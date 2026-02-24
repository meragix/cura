# CI/CD Integration

Cura is designed for seamless pipeline integration:

- Structured exit codes (`0` = pass, `1` = fail)
- `--quiet` mode for clean logs
- `--json` output for downstream tooling
- Configurable thresholds via project config or CLI flags
- Local SQLite cache that can be persisted between runs

---

## Quick Setup

Add a project config so every developer and pipeline uses the same standards:

```yaml
# ./.cura/config.yaml — commit this file
theme: minimal
use_colors: false
min_score: 80
fail_on_vulnerable: true
```

Then install and run in one step:

```bash
dart pub global activate cura
cura check
```

---

## GitHub Actions

### Minimal workflow

```yaml
name: Dependency Health

on: [push, pull_request]

jobs:
  cura:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: dart-lang/setup-dart@v1
        with:
          sdk: stable

      - name: Install Cura
        run: dart pub global activate cura

      - name: Audit dependencies
        run: cura check --min-score 75 --fail-on-vulnerable
```

### With cache and GitHub token

```yaml
name: Dependency Health

on: [push, pull_request]

jobs:
  cura:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: dart-lang/setup-dart@v1
        with:
          sdk: stable

      - name: Restore Cura cache
        uses: actions/cache@v4
        with:
          path: ~/.cura/cache
          key: cura-${{ hashFiles('pubspec.lock') }}
          restore-keys: cura-

      - name: Install Cura
        run: dart pub global activate cura

      - name: Audit dependencies
        run: cura check --min-score 80 --fail-on-vulnerable
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Export JSON report
        if: always()
        run: cura check --json > cura-report.json

      - name: Upload report artifact
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: cura-report
          path: cura-report.json
```

The cache key is tied to `pubspec.lock` so it is invalidated whenever
dependencies change.

---

## GitLab CI

### Basic pipeline

```yaml
dependency-health:
  image: dart:stable
  stage: test
  script:
    - dart pub global activate cura
    - cura check --min-score 75
  allow_failure: false
```

### With cache

```yaml
dependency-health:
  image: dart:stable
  stage: test
  cache:
    key: cura-$CI_COMMIT_REF_SLUG
    paths:
      - ~/.cura/cache/
  script:
    - dart pub global activate cura
    - cura check --min-score 80 --fail-on-vulnerable
  allow_failure: false
```

---

## CircleCI

```yaml
version: 2.1

jobs:
  dependency-health:
    docker:
      - image: google/dart:latest
    steps:
      - checkout

      - restore_cache:
          keys:
            - cura-{{ checksum "pubspec.lock" }}
            - cura-

      - run:
          name: Install Cura
          command: dart pub global activate cura

      - run:
          name: Audit dependencies
          command: cura check --min-score 75

      - save_cache:
          key: cura-{{ checksum "pubspec.lock" }}
          paths:
            - ~/.cura/cache

workflows:
  main:
    jobs:
      - dependency-health
```

---

## Exit Codes

| Code | Meaning                                                |
|------|--------------------------------------------------------|
| `0`  | All packages passed all configured checks              |
| `1`  | One or more packages failed the threshold or have CVEs |

Use in shell scripts:

```bash
cura check --min-score 80 --quiet
if [ $? -eq 0 ]; then
  echo "Health check passed"
else
  echo "Health check failed"
  exit 1
fi
```

---

## Options Reference

| Flag                      | Description                                   |
|---------------------------|-----------------------------------------------|
| `--min-score <n>`         | Exit 1 when average score falls below `n`     |
| `--fail-on-vulnerable`    | Exit 1 if any CVEs are detected               |
| `--fail-on-discontinued`  | Exit 1 if any discontinued packages are found |
| `--no-github`             | Skip GitHub metrics (faster, fewer API calls) |
| `--json`                  | Emit results as JSON to stdout                |
| `-q, --quiet`             | Suppress all output except errors             |

---

## JSON Output

Generate a machine-readable report:

```bash
cura check --json > cura-report.json
```

Process with `jq`:

```bash
# Average score
cura check --json | jq '.summary.average_score'

# Packages below 70
cura check --json | jq '.packages[] | select(.score.total < 70) | .name'
```

---

## Troubleshooting

### GitHub rate-limited

**Symptom:** `Rate limit exceeded` error from the GitHub API.

**Fix:** Persist the `~/.cura/cache/` directory between runs (see examples
above), or inject a GitHub token:

```bash
cura config set github_token "$GITHUB_TOKEN"
```

### Job times out

**Fix:** Skip GitHub metrics or ensure caching is enabled:

```bash
cura check --no-github
```

### Internal packages fail the check

**Fix:** Add them to `ignore_packages` in the project config:

```yaml
# ./.cura/config.yaml
ignore_packages:
  - internal_test_helper
  - mock_data_server
```

---

## Related

- [Configuration reference](configuration.md) — all config keys
- [Caching](caching.md) — cache strategy and CI cache setup
- [API integration](api-integration.md) — rate limits and authentication
