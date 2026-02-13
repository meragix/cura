# CI/CD Integration

## Overview

Cura is designed for seamless CI/CD integration with:

- ✅ Exit codes (0 = pass, 1 = fail)
- ✅ Minimal/JSON output modes
- ✅ Configurable thresholds
- ✅ Fast execution (with caching)

---

## GitHub Actions

### Basic Health Check

```yaml
name: Cura Health Check

on:
  push:
    branches: [main]
  pull_request:

jobs:
  health:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: dart-lang/setup-dart@v1
        with:
          sdk: stable
      
      - name: Install Cura
        run: dart pub global activate cura
      
      - name: Health Check
        run: cura check --min-score 70
```

---

### Advanced with Caching

```yaml
name: Cura Advanced

on: [push, pull_request]

jobs:
  health:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: dart-lang/setup-dart@v1
      
      - name: Cache Cura
        uses: actions/cache@v3
        with:
          path: ~/.cura/cache
          key: cura-${{ hashFiles('pubspec.lock') }}
          restore-keys: cura-
      
      - name: Install Cura
        run: dart pub global activate cura
      
      - name: Configure Cura
        run: |
          cura config set theme minimal --global
          cura config set use_colors false --global
      
      - name: Health Check
        run: |
          cura check --min-score 75 --fail-on-vulnerable
      
      - name: Upload Report
        if: always()
        run: |
          cura scan --json > cura-report.json
      
      - uses: actions/upload-artifact@v3
        if: always()
        with:
          name: cura-report
          path: cura-report.json
```

---

### With GitHub Token (Higher Rate Limits)

```yaml
- name: Health Check with GitHub Metrics
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: |
    cura config set github_token $GITHUB_TOKEN --global
    cura check --min-score 80
```

---

## GitLab CI

### Basic Pipeline

```yaml
cura_check:
  image: dart:stable
  stage: test
  script:
    - dart pub global activate cura
    - cura check --min-score 75
  allow_failure: false
```

---

### Advanced with Caching

```yaml
cura_check:
  image: dart:stable
  stage: test
  cache:
    key: cura-cache
    paths:
      - .cura/cache/
  before_script:
    - dart pub global activate cura
    - cura config set theme minimal --global
  script:
    - cura check --min-score 80 --fail-on-vulnerable
  artifacts:
    when: always
    reports:
      junit: cura-report.xml
    paths:
      - cura-report.json
  allow_failure: false
```

---

## CircleCI

```yaml
version: 2.1

jobs:
  cura_check:
    docker:
      - image: google/dart:latest
    steps:
      - checkout
      
      - restore_cache:
          keys:
            - cura-cache-{{ checksum "pubspec.lock" }}
            - cura-cache-
      
      - run:
          name: Install Cura
          command: dart pub global activate cura
      
      - run:
          name: Health Check
          command: cura check --min-score 75
      
      - save_cache:
          key: cura-cache-{{ checksum "pubspec.lock" }}
          paths:
            - ~/.cura/cache
      
      - store_artifacts:
          path: cura-report.json

workflows:
  main:
    jobs:
      - cura_check
```

---

## Travis CI

```yaml
language: dart
dart:
  - stable

cache:
  directories:
    - $HOME/.cura/cache

before_script:
  - dart pub global activate cura

script:
  - cura check --min-score 70 --fail-on-vulnerable
```

---

## Command Options for CI/CD

### Check Command

```bash
cura check [options]
```

**Critical Options:**

| Flag | Description | Default |
|------|-------------|---------|
| `--min-score <n>` | Fail if avg score < n | `70` |
| `--fail-on-vulnerable` | Fail if CVEs found | `true` |
| `--fail-on-discontinued` | Fail if discontinued packages | `true` |
| `-q, --quiet` | Minimal output | `false` |
| `--json` | JSON output | `false` |

---

### Exit Codes

| Code | Meaning |
|------|---------|
| `0` | All checks passed |
| `1` | Failed (score/vulnerability/discontinued) |

**Example:**

```bash
cura check --min-score 80
if [ $? -eq 0 ]; then
  echo "✓ Health check passed"
else
  echo "✗ Health check failed"
  exit 1
fi
```

---

## Configuration for CI/CD

### Option 1: Project Config (Recommended)

```yaml
# ./.cura/config.yaml (committed to repo)
theme: minimal
use_colors: false
min_score: 80

ignore_packages:
  - test_package
```

**Advantage:** Same config for all developers + CI

---

### Option 2: Environment-Specific

```bash
# In CI script
if [ "$CI" = "true" ]; then
  cura config set theme minimal --global
  cura config set use_colors false --global
fi

cura check --min-score 85
```

---

## Caching Strategies

### Cura Cache Location

```bash
~/.cura/cache/cura_cache.db
```

### GitHub Actions

```yaml
- uses: actions/cache@v3
  with:
    path: ~/.cura/cache
    key: cura-${{ hashFiles('pubspec.lock') }}
    restore-keys: cura-
```

**Benefits:**

- Faster runs (skip API calls)
- Avoid rate limits
- Consistent scores

---

## JSON Output

### Generate Report

```bash
cura scan --json > report.json
```

### Example Output

```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "summary": {
    "total_packages": 15,
    "average_score": 78.5,
    "healthy": 12,
    "warnings": 2,
    "critical": 1
  },
  "packages": [
    {
      "name": "dio",
      "version": "5.4.0",
      "score": {
        "total": 92,
        "grade": "A+",
        "vitality": 38,
        "technical_health": 28,
        "trust": 19,
        "maintenance": 7
      },
      "issues": [],
      "suggestions": []
    }
  ]
}
```

### Process with jq

```bash
# Get average score
cura scan --json | jq '.summary.average_score'

# List packages below 70
cura scan --json | jq '.packages[] | select(.score.total < 70) | .name'

# Count critical packages
cura scan --json | jq '.summary.critical'
```

---

## Notifications

### Slack Notification (GitHub Actions)

```yaml
- name: Notify Slack
  if: failure()
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {
        "text": "❌ Cura health check failed",
        "blocks": [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "*Cura Health Check Failed*\nAverage score below threshold"
            }
          }
        ]
      }
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

---

## Best Practices

### ✅ Do

- Commit `.cura/config.yaml` to repo
- Use caching to speed up builds
- Set appropriate `min_score` for your project
- Use `--quiet` in CI for cleaner logs
- Store reports as artifacts

### ❌ Don't

- Don't commit GitHub tokens to config
- Don't set `min_score` too high initially (start at 70)
- Don't skip caching (wastes time and API quota)

---

## Troubleshooting

### Rate Limiting

**Problem:** `Rate limit exceeded for pub.dev API`

**Solution:**

```yaml
# Add caching
- uses: actions/cache@v3
  with:
    path: ~/.cura/cache
    key: cura-${{ hashFiles('pubspec.lock') }}
```

---

### Timeout

**Problem:** CI job times out

**Solution:**

```bash
# Increase timeout
cura config set timeout_seconds 30 --global

# Or disable GitHub metrics (faster)
cura check --no-github
```

---

### False Positives

**Problem:** Internal packages fail check

**Solution:**

```yaml
# ./.cura/config.yaml
ignore_packages:
  - internal_test_package
  - mock_data
```

---

## Examples Repository

See [cura-examples](https://github.com/your-org/cura-examples) for:

- ✅ Complete workflow files
- ✅ Multi-platform setups
- ✅ Advanced configurations

---

## Related

- [Check Command](check.md) - Command details
- [Configuration](configuration.md) - Config options
- [CLI Reference](cli-reference.md) - All flags
