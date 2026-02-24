# Caching

Cura stores API responses in a local SQLite database so that repeated runs
over the same dependencies avoid redundant network calls and respect external
rate limits.

---

## Cache Location

```
~/.cura/cache/cura_cache.db
```

The directory is created automatically on first run.

---

## How It Works

### Write path

When a package is fetched for the first time (or its cache entry has expired),
Cura:

1. Calls the relevant APIs (pub.dev, GitHub, OSV.dev)
2. Aggregates the raw data into a single JSON payload
3. Stores the payload in the `aggregated_cache` table with an expiry timestamp
4. Returns the fresh data to the scorer

### Read path

On subsequent runs, before touching any API:

1. Cura queries `aggregated_cache` for the package name
2. If a non-expired row exists, the cached payload is deserialized and returned
3. The result is tagged `fromCache: true` so presenters can show a cache-hit
   indicator

### Startup sweep

When Cura starts, it calls `cleanupExpired()` to delete all rows whose expiry
timestamp is in the past, keeping the database file small.

---

## TTL Strategy

Cache lifetime scales with package popularity, measured by the `popularityScore`
field returned by pub.dev (0–100):

| Popularity tier    | Condition              | TTL      |
|--------------------|------------------------|----------|
| High               | `popularityScore >= 70`| 1 hour   |
| Normal             | `popularityScore >= 20`| 6 hours  |
| Low                | `popularityScore < 20` | 24 hours |

Rationale: popular packages publish updates frequently and may have new CVEs
reported at any time, so their cache is intentionally short. Obscure packages
change rarely; a 24-hour TTL avoids hitting OSV.dev unnecessarily.

---

## Database Schema

Two tables are maintained:

### `package_cache`

Stores raw per-source responses (pub.dev, GitHub, OSV.dev) keyed by package
name and source type.

| Column       | Type    | Description                        |
|--------------|---------|------------------------------------|
| `key`        | TEXT PK | `{packageName}:{source}`           |
| `data`       | TEXT    | JSON payload                       |
| `expires_at` | INTEGER | Unix timestamp (seconds since epoch) |

### `aggregated_cache`

Stores the fully merged `AggregatedPackageData` payload keyed by package name.

| Column       | Type    | Description                          |
|--------------|---------|--------------------------------------|
| `key`        | TEXT PK | Package name                         |
| `data`       | TEXT    | JSON-encoded `AggregatedPackageData` |
| `expires_at` | INTEGER | Unix timestamp (seconds since epoch) |

---

## Cache Management Commands

### Inspect

```bash
cura cache stats
```

Prints entry counts per table:

```
Cache Statistics:

  Package cache    : 47 entries
  Aggregated cache : 43 entries
  ──────────────────────────────
  Total            : 90 entries
```

### Sweep expired entries

```bash
cura cache cleanup
```

Removes only rows whose TTL has elapsed. Valid entries are untouched.
Safe to run at any time.

### Wipe everything

```bash
cura cache clear
```

Prompts for confirmation, then deletes all rows from all tables. Use this
when you want to force a fully fresh analysis (e.g. after a security incident
or to verify a fix).

---

## Configuration Keys

| Key                  | Default | Description                                 |
|----------------------|---------|---------------------------------------------|
| `enable_cache`       | `true`  | Enable or disable the SQLite cache entirely |
| `cache_max_age_hours`| —       | Override TTL (hours) for all packages       |
| `auto_update`        | `true`  | Sweep expired entries on startup            |

### Disable the cache

```bash
cura config set enable_cache false
```

When the cache is disabled every run fetches live data from all three APIs.
Useful for debugging but increases latency and API consumption.

### Pin a custom TTL

```bash
cura config set cache_max_age_hours 2
```

Sets a flat 2-hour TTL for all packages, ignoring the popularity-based
strategy. Useful when you want consistent refresh intervals.

---

## CI/CD Considerations

Caching the `~/.cura/cache/` directory between pipeline runs dramatically
reduces API calls and execution time.

### GitHub Actions

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.cura/cache
    key: cura-${{ hashFiles('pubspec.lock') }}
    restore-keys: cura-
```

The cache key is tied to `pubspec.lock` so the cache is invalidated whenever
dependencies change.

### GitLab CI

```yaml
cache:
  key: cura-cache
  paths:
    - ~/.cura/cache/
```

---

## Related

- [API integration](api-integration.md) — what data is fetched and cached
- [Configuration reference](configuration.md) — full config key list
- [CI/CD integration](ci-cd.md) — pipeline cache examples
