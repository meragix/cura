# Caching

Cura stores API responses as JSON files on disk so that repeated runs over the
same dependencies avoid redundant network calls and respect external rate limits.
The cache requires no native dependencies and works out-of-the-box on macOS,
Linux, and Windows.

---

## Cache Location

```text
~/.cura/cache/
  aggregated/          ← AggregatedPackageData per package
    dio.json
    provider.json
    ...
```

The directory hierarchy is created automatically on first run.

---

## How It Works

### Write path

When a package is fetched for the first time (or its cache entry has expired),
Cura:

1. Calls the relevant APIs (pub.dev, GitHub, OSV.dev)
2. Aggregates the raw data into an `AggregatedPackageData` payload
3. Writes the payload as `~/.cura/cache/aggregated/<packageName>.json` with an
   `expiresAt` timestamp
4. Returns the fresh data to the scorer

Writes use the **write-then-rename** pattern (`<key>.json.tmp` → `<key>.json`)
so a crash mid-write never leaves a corrupted file.

### Read path

On subsequent runs, before touching any API:

1. Cura opens `~/.cura/cache/aggregated/<packageName>.json`
2. If the file exists and `expiresAt` is in the future, the payload is returned
3. The result is tagged `fromCache: true` so presenters can show a cache-hit
   indicator
4. If the file is absent, expired, or unparseable it is treated as a cache miss

### Startup sweep

When Cura starts, `cleanupExpired()` runs automatically and:

- Deletes `.json` files whose `expiresAt` has passed
- Removes orphaned `.json.tmp` files older than 1 hour

---

## JSON File Schema

Each cache file follows this envelope (schemaVersion 1):

```json
{
  "schemaVersion": 1,
  "key": "dio",
  "cachedAt": "2026-02-24T10:00:00.000Z",
  "expiresAt": "2026-02-25T10:00:00.000Z",
  "data": {
    "package_info": { ... },
    "github_metrics": { ... },
    "vulnerabilities": []
  }
}
```

| Field           | Description                                          |
|-----------------|------------------------------------------------------|
| `schemaVersion` | Format version; bumped on breaking schema changes    |
| `key`           | Package name (matches the file name without `.json`) |
| `cachedAt`      | UTC ISO-8601 timestamp when the entry was written    |
| `expiresAt`     | UTC ISO-8601 timestamp after which the entry is stale|
| `data`          | The `AggregatedPackageData` payload                  |

---

## TTL Strategy

Cache lifetime scales with package popularity, measured by the
`popularityScore` returned by pub.dev (0–100):

| Popularity tier | Condition     | TTL  |
|-----------------|---------------|------|
| Very high       | `score >= 90` | 24 h |
| High            | `score >= 70` | 12 h |
| Normal          | `score >= 40` | 6 h  |
| Low             | `score < 40`  | 3 h  |

Rationale: popular packages publish updates frequently and may have new CVEs
reported at any time, so their cache is intentionally short. Obscure packages
change rarely; a longer TTL avoids hitting OSV.dev unnecessarily.

---

## Cache Management Commands

### Inspect

```bash
cura cache stats
```

Prints valid (non-expired) entry counts per namespace:

```text
Cache Statistics:

  Aggregated cache : 43 entries
  ──────────────────────────────
  Total            : 43 entries
```

### Sweep expired entries

```bash
cura cache cleanup
```

Removes expired entries and orphaned `.tmp` files. Valid entries are untouched.
Safe to run at any time.

### Wipe everything

```bash
cura cache clear
```

Prompts for confirmation, then deletes all `.json` files across all cache
namespaces. Use this when you want to force a fully fresh analysis (e.g. after
a security incident or to verify a fix).

---

## Configuration Keys

| Key                  | Default | Description                               |
|----------------------|---------|-------------------------------------------|
| `enable_cache`       | `true`  | Enable or disable the file cache entirely |
| `cache_max_age_hours`| —       | Override TTL (hours) for all packages     |
| `auto_update`        | `true`  | Sweep expired entries on startup          |

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
strategy.

---

## CI/CD Considerations

Cache the `~/.cura/cache/` directory between pipeline runs to dramatically
reduce API calls and execution time.

### GitHub Actions

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.cura/cache
    key: cura-${{ hashFiles('pubspec.lock') }}
    restore-keys: cura-
```

The cache key is tied to `pubspec.lock` so it is invalidated whenever
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
