# Configuration Reference

Cura uses a **hierarchical configuration** system. Settings are resolved in
priority order — higher sources override lower ones:

```
CLI flags                        (highest priority)
  ↓
./.cura/config.yaml              (project config)
  ↓
~/.cura/config.yaml              (global config)
  ↓
Built-in defaults                (lowest priority)
```

---

## Config Files

### Global config — `~/.cura/config.yaml`

Created automatically on first run with built-in defaults. Use this for
personal preferences (theme, GitHub token) that apply to every project.

### Project config — `./.cura/config.yaml`

Created manually via `cura config init`. Commit this file to share quality
standards with your team (minimum score, ignored packages).

---

## Complete Key Reference

### Appearance

| Key          | Type   | Default | Description                                   |
|--------------|--------|---------|-----------------------------------------------|
| `theme`      | string | `dark`  | Terminal theme: `dark`, `light`, or `minimal` |
| `use_colors` | bool   | `true`  | Enable ANSI color output                      |
| `use_emojis` | bool   | `true`  | Show emoji symbols in output                  |

```yaml
theme: minimal
use_colors: false   # recommended for CI logs
use_emojis: false
```

---

### API

| Key               | Type   | Default | Description                            |
|-------------------|--------|---------|----------------------------------------|
| `github_token`    | string | —       | GitHub PAT for higher rate limits      |
| `timeout_seconds` | int    | `10`    | HTTP request timeout in seconds        |
| `max_retries`     | int    | `3`     | Retry attempts before giving up        |
| `max_concurrency` | int    | `5`     | Maximum simultaneous outbound requests |

```yaml
github_token: ghp_xxxxxxxxxxxxx
timeout_seconds: 15
max_concurrency: 3
```

Generate a GitHub token at <https://github.com/settings/tokens>. No scopes
are required for public repositories. With a token the rate limit rises from
60 to 5 000 requests per hour.

---

### Scoring

| Key         | Type | Default | Description              |
|-------------|------|---------|--------------------------|
| `min_score` | int  | `70`    | Minimum acceptable score |

```yaml
min_score: 85
```

---

### Behaviour

| Key                           | Type | Default | Description                                   |
|-------------------------------|------|---------|-----------------------------------------------|
| `fail_on_vulnerable`          | bool | `false` | Exit 1 if any CVEs are detected               |
| `fail_on_discontinued`        | bool | `false` | Exit 1 if any discontinued packages are found |
| `show_suggestions`            | bool | `true`  | Show alternative package suggestions          |
| `max_suggestions_per_package` | int  | `3`     | Maximum alternatives shown per package        |
| `ignore_packages`             | list | `[]`    | Package names to skip during analysis         |

```yaml
fail_on_vulnerable: true
fail_on_discontinued: true
show_suggestions: true
ignore_packages:
  - internal_test_helper
  - mock_server
```

---

### Cache

| Key                   | Type | Default | Description                               |
|-----------------------|------|---------|-------------------------------------------|
| `enable_cache`        | bool | `true`  | Enable the local SQLite cache             |
| `cache_max_age_hours` | int  | —       | Override the TTL (hours) for all packages |
| `auto_update`         | bool | `true`  | Sweep expired entries at startup          |

```yaml
enable_cache: true
cache_max_age_hours: 2   # flat TTL override
```

---

### Logging

| Key               | Type | Default | Description                               |
|-------------------|------|---------|-------------------------------------------|
| `verbose_logging` | bool | `false` | Log every API call, cache hit, and timing |
| `quiet`           | bool | `false` | Suppress all output except errors         |

---

## Commands

### `cura config show`

Print the merged effective configuration.

```bash
cura config show
```

---

### `cura config init`

Create `./.cura/config.yaml` with commented-out defaults as a starting point.

```bash
cura config init
```

Existing files are never overwritten.

---

### `cura config set <key> <value>`

Write a single value to the project config.

```bash
cura config set min_score 85
cura config set theme minimal
cura config set github_token ghp_xxxxx
cura config set fail_on_vulnerable true
```

Both `snake_case` and `camelCase` key variants are accepted:

```bash
cura config set minScore 85   # same as min_score
```

---

### `cura config get <key>`

Read a single value from the merged config.

```bash
cura config get theme
# dark

cura config get min_score
# 85
```

---

## Practical Examples

### Personal global setup

```yaml
# ~/.cura/config.yaml
theme: dark
github_token: ghp_xxxxxxxxxxxxx
show_suggestions: true
timeout_seconds: 15
```

---

### Team project standards

```yaml
# ./.cura/config.yaml  — commit this file
min_score: 80
fail_on_vulnerable: true
fail_on_discontinued: true
ignore_packages:
  - internal_analytics
  - mock_data_server
```

---

### CI/CD environment

```yaml
# ./.cura/config.yaml
theme: minimal
use_colors: false
use_emojis: false
min_score: 85
```

---

## Best Practices

- Commit `.cura/config.yaml` to enforce shared standards across the team.
- Store your GitHub token only in `~/.cura/config.yaml` — never commit tokens.
- Use `minimal` theme and `use_colors: false` for cleaner CI logs.
- Start with `min_score: 70` and raise it gradually as the team improves
  package hygiene.

---

## Related

- [CI/CD integration](ci-cd.md) — pipeline configuration examples
- [Caching](caching.md) — cache-specific keys explained
- [Themes](themes.md) — theme details
