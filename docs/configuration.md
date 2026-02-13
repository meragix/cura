# Configuration System

## Overview

Cura supports **hierarchical configuration** with three levels:

```
CLI Flags (highest priority)
    ↓
Project Config (./.cura/config.yaml)
    ↓
Global Config (~/.cura/config.yaml)
    ↓
Defaults (lowest priority)
```

## Configuration Levels

### 1. Global Config

**Location:** `~/.cura/config.yaml`

**Purpose:** Personal preferences that apply to all projects

**Created:** Automatically on first run

**Example:**

```yaml
# My personal preferences
theme: dracula
use_emojis: true
github_token: ghp_xxxxx

# Default strictness
min_score: 70
```

**Edit:**

```bash
cura config edit --global
```

---

### 2. Project Config

**Location:** `./.cura/config.yaml` (in project root)

**Purpose:** Team standards that override global settings

**Created:** Manually via `cura config init`

**Example:**

```yaml
# Team standards for this project
min_score: 85

# Ignore internal packages
ignore_packages:
  - internal_test_package

# Trust company publisher
trusted_publishers:
  - my-company.dev
```

**Edit:**

```bash
cura config edit --project
```

**Version Control:**

```bash
# Commit project config to share with team
git add .cura/config.yaml
git commit -m "Add Cura project standards"
```

---

### 3. CLI Flags

**Purpose:** One-time overrides for specific commands

**Example:**

```bash
# Override theme for this run only
cura scan --theme=light

# Override min score for CI/CD
cura check --min-score 90
```

---

## Complete Reference

### Appearance

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `theme` | string | `dark` | UI theme (dark, light, minimal, dracula) |
| `use_emojis` | bool | `true` | Show emojis in output |
| `use_colors` | bool | `true` | Enable colored output |

**Example:**

```yaml
theme: dracula
use_emojis: false  # ASCII symbols only
use_colors: true
```

---

### Cache

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `cache_max_age` | int | `24` | Cache TTL in hours |
| `auto_update` | bool | `true` | Auto-refresh cache in background |

**Example:**

```yaml
cache_max_age: 12   # More aggressive caching
auto_update: false  # Manual refresh only
```

---

### Scoring

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `min_score` | int | `70` | Minimum acceptable score |
| `score_weights` | object | See below | Custom scoring weights |

**Default Weights:**

```yaml
score_weights:
  vitality: 40
  technical_health: 30
  trust: 20
  maintenance: 10
```

**Custom Weights Example:**

```yaml
# Prioritize maintenance over vitality
score_weights:
  vitality: 30           # -10
  technical_health: 30
  trust: 20
  maintenance: 20        # +10
```

**Rules:**

- Total must equal 100
- Validation error if sum ≠ 100

---

### API Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `timeout_seconds` | int | `10` | HTTP request timeout |
| `max_retries` | int | `3` | Max retry attempts |
| `github_token` | string | `null` | GitHub Personal Access Token |

**GitHub Token:**

```yaml
github_token: ghp_xxxxxxxxxxxxx
```

**Get a token:**

1. Go to <https://github.com/settings/tokens>
2. Generate new token (classic)
3. Select scopes: `public_repo` (read-only)
4. Copy token to config

**Benefits:**

- Rate limit: 60 req/h → 5000 req/h
- Access to detailed commit data

---

### Suggestions

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `show_suggestions` | bool | `true` | Show package alternatives |
| `max_suggestions_per_package` | int | `3` | Max alternatives to show |

**Example:**

```yaml
show_suggestions: true
max_suggestions_per_package: 2  # Show top 2 only
```

---

### Exclusions

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `ignore_packages` | list | `[]` | Packages to skip |
| `trusted_publishers` | list | `[]` | Auto-approve publishers |

**Example:**

```yaml
ignore_packages:
  - internal_test_package
  - mock_data_generator
  - example_flutter_app

trusted_publishers:
  - dart.dev
  - flutter.dev
  - my-company.dev
```

**Behavior:**

- **ignore_packages:** Skipped during `scan`, not analyzed
- **trusted_publishers:** Auto-assigned high maintenance score

---

## Command Reference

### Show Configuration

```bash
# Show merged config (effective settings)
cura config show

# Show with detailed breakdown
cura config show --verbose

# Show only global
cura config show --global

# Show only project
cura config show --project
```

**Output:**

```
Configuration Hierarchy

Global Config:
  Location: ~/.cura/config.yaml
  Status: ✓ Found
  Theme: dracula
  Min Score: 70

Project Config:
  Location: ./.cura/config.yaml
  Status: ✓ Found
  Min Score: 85  (overrides global)

Effective Config:
  Theme: dracula        (from global)
  Min Score: 85         (from project)
  GitHub Token: ✓ Set   (from global)
```

---

### Initialize Project Config

```bash
# Create ./.cura/config.yaml
cura config init
```

**Creates:**

```yaml
# Cura Project Configuration
# Overrides global settings for this project

# Override minimum score
min_score: 75

# Project-specific exclusions
ignore_packages:
  # - example_package

trusted_publishers:
  # - my-company.dev
```

---

### Set Values

```bash
# Set global value
cura config set theme dracula --global

# Set project value
cura config set min_score 85 --project

# Auto-detect (global if no project exists)
cura config set use_emojis false
```

---

### Get Values

```bash
# Get specific value
cura config get theme
# Output: dracula

# Get from specific scope
cura config get min_score --project
# Output: 85
```

---

### Edit in Editor

```bash
# Edit global config
cura config edit --global

# Edit project config
cura config edit --project
```

**Opens in:**

1. `$EDITOR` environment variable
2. VS Code (`code`)
3. Nano
4. Vim

---

### Validate Configuration

```bash
cura config validate
```

**Checks:**

- ✓ YAML syntax is valid
- ✓ Score weights sum to 100
- ✓ Min score is 0-100
- ✓ Theme is valid
- ✓ Required fields present

**Output (valid):**

```
✓ Configuration is valid
```

**Output (invalid):**

```
✗ Invalid configuration:
  - Score weights must sum to 100 (got 95)
  - Invalid theme: "neon" (valid: dark, light, minimal, dracula)
```

---

### Reset to Defaults

```bash
# Reset global config
cura config reset --global

# Remove project config
cura config remove --project
```

---

## Examples

### Personal Setup

```yaml
# ~/.cura/config.yaml
theme: dracula
use_emojis: true
github_token: ghp_xxxxx
cache_max_age: 48  # I prefer longer cache
```

---

### Team Project

```yaml
# ./.cura/config.yaml
min_score: 80  # Stricter than default

ignore_packages:
  - internal_analytics
  - mock_server

trusted_publishers:
  - my-company.dev
  - partner-company.dev

# Everyone uses the same standards
```

---

### CI/CD Environment

```yaml
# ./.cura/config.yaml
theme: minimal      # No colors in CI logs
use_emojis: false
use_colors: false
min_score: 85       # Strict for production
```

---

## Best Practices

### ✅ Do

- Commit project config to version control
- Use global config for personal preferences
- Document project config choices in comments
- Validate config before committing

### ❌ Don't

- Don't commit global config (`~/.cura/config.yaml`)
- Don't hardcode GitHub tokens in project config
- Don't override every setting in project config

---

## Troubleshooting

### Config not loading

```bash
# Check if file exists
ls -la ~/.cura/config.yaml
ls -la ./.cura/config.yaml

# Validate syntax
cura config validate

# View effective config
cura config show --verbose
```

### Values not applying

**Priority reminder:**

```
CLI > Project > Global > Defaults
```

Check if a higher-priority source is overriding your setting.

---

## Related

- [CLI Reference](cli-reference.md) - All command options
- [Themes](themes.md) - Theme customization
- [CI/CD](ci-cd.md) - CI/CD configuration
