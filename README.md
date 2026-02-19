# 🩺 Cura

<!-- <p align="center">
  <img src="assets/logo.png" alt="Cura Logo" width="200"/>
</p> -->

<p align="center">
  <strong>Replace "Vibe Code" with data-driven decisions</strong>
</p>

<p align="center">
  <a href="https://pub.dev/packages/cura"><img src="https://img.shields.io/pub/v/cura.svg" alt="Pub Version"></a>
  <a href="https://github.com/meragix/cura/actions"><img src="https://github.com/meragix/cura/workflows/CI/badge.svg" alt="CI Status"></a>
  <a href="https://github.com/meragix/cura/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License"></a>
  <a href="https://github.com/meragix/cura"><img src="https://img.shields.io/github/stars/meragix/cura?style=social" alt="GitHub Stars"></a>
</p>

---

## 📖 Table of Contents

- [What is Cura?](#-what-is-cura)
- [Features](#-features)
- [Quick Start](#-quick-start)
- [Installation](#-installation)
- [Usage](#-usage)
  - [Check Command](#check-command)
  - [View Command](#view-command)
  - [Config Command](#config-command)
- [Scoring Algorithm](#-scoring-algorithm)
- [Configuration](#️-configuration)
- [CI/CD Integration](#-cicd-integration)
- [Advanced Features](#-advanced-features)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 What is Cura?

**Cura** is a CLI tool that provides **objective health scores** (0-100) for Flutter and Dart packages, helping you make informed decisions about your dependencies instead of relying on intuition ("Vibe Code").

### The Problem

When choosing packages, developers often rely on:

- ❌ **Gut feeling** - "This looks good"
- ❌ **Popularity alone** - High downloads ≠ quality
- ❌ **Outdated information** - Last checked 6 months ago

### The Solution

Cura analyzes packages across **4 key dimensions**:

| Dimension | Weight | What it measures |
|-----------|--------|------------------|
| **Vitality** | 40pts |Release frequency, commit recency, active maintenance. |
| **Technical Health** | 30pts | Pana score, null safety, platform support |
| **Trust** | 20pts | Popularity, community engagement |
| **Maintenance** | 10pts | Verified publisher, Flutter Favorite |

**Score: 0-100** → **Grade: F to A+**

---

## ✨ Features

### Core Features

- 🔍 **Package Analysis** - Deep health check for any pub.dev package
- 📊 **Project Scanning** - Analyze all dependencies in your `pubspec.yaml`
- 💯 **Objective Scoring** - Data-driven scores (0-100) with detailed breakdown
- 💡 **Smart Suggestions** - Recommendations for better alternatives
- ⚡ **Fast & Cached** - Local SQLite cache for instant results

### Developer Experience

- 🎨 **Beautiful CLI** - Color-coded output with progress bars
- 🌗 **Theme Support** - Dark, Light, Minimal, Dracula themes
- 🔧 **Highly Configurable** - Global + project-level configs
- 🚀 **CI/CD Ready** - Exit codes, JSON output, quiet mode

### Advanced

- 🌐 **Multi-API** - Aggregates data from pub.dev, GitHub, OSV.dev
- 🔄 **Auto-update** - Background cache refresh every 24h
- 📈 **GitHub Metrics** - Stars, issues, commit activity (optional)
- 🔐 **Security Checks** - CVE detection via OSV.dev

---

## ⚡ Quick Start

```bash
# Install globally
dart pub global activate cura

# Analyze your Flutter project
cd my_flutter_app
cura check

# View detailed score for a specific package
cura view riverpod

# CI/CD health check
cura check --min-score 70
```

**Output:**

```
📦 Scanning pubspec.yaml...
Found 15 dependencies

✓ Analyzing packages... [████████████████████] 15/15 (3.2s)

┌────────────────────────┬───────┬────────┬──────────────┐
│ Package                │ Score │ Status │ Last Update  │
├────────────────────────┼───────┼────────┼──────────────┤
│ riverpod               │  92   │   ✅   │ 1 month      │
│ dio                    │  88   │   ✅   │ 15 days      │
│ provider               │  68   │   ⚠️   │ 8 months     │
│ old_package            │  25   │   ❌   │ 32 months    │
└────────────────────────┴───────┴────────┴──────────────┘

📊 Summary
   Average Score: 75.3/100
   ✅ Healthy: 12/15 (80%)
   💡 Alternatives Available: 2
```

---

## 📥 Installation

### Method 1: Global Installation (Recommended)

```bash
dart pub global activate cura
```

**Verify installation:**

```bash
cura --version
```

### Method 2: Local Installation

```bash
# Clone the repository
git clone https://github.com/meragix/cura.git
cd cura

# Install dependencies
dart pub get

# Activate locally
dart pub global activate --source path .
```

### Requirements

- Dart SDK ≥ 3.0.0
- Internet connection (for initial package analysis)

---

## 🚀 Usage

### Check Command

Analyze all dependencies in your project.

```bash
cura check [options]
```

**Options:**

- `-p, --path <path>` - Project directory (default: current directory)
- `--min-score <score>` - Fail if average score below threshold
- `--fail-on-vulnerable` - Exit 1 if vulnerabilities found
- `--fail-on-discontinued` - Exit 1 if discontinued packages found
- `--no-github` - Skip GitHub metrics (faster, offline mode)
- `--json` - Output results as JSON
- `-q, --quiet` - Minimal output

**Examples:**

```bash
# Basic check
cura check

# Scan specific directory
cura check --path /path/to/project

# Strict check for CI/CD
cura check --min-score 80 --fail-on-vulnerable

# CI/CD mode with threshold
cura check --min-score 80 --json > report.json

# Offline mode (cached data only)
cura check --no-github

# Quiet mode (only errors)
cura check --quiet
echo $?  # 0 = pass, 1 = fail
```

---

**See also:** [docs/scan.md](docs/check.md) for advanced usage

**GitHub Actions Integration:**

```yaml
- name: Cura Health Check
  run: cura check --min-score 75
```

**See also:** [docs/ci-cd.md](docs/ci-cd.md) for CI/CD best practices

---

### View Command

Get detailed analysis for a specific package.

```bash
cura view <package> [options]
```

**Options:**

- `-v, --verbose` - Show detailed debug information
- `--json` - Output as JSON

**Examples:**

```bash
# View package score
cura view dio

# Verbose mode (cache status, API calls, timing)
cura view dio --verbose

# JSON output for scripts
cura view dio --json | jq '.score.total'
```

**Output (Normal):**

```
✨ dio v5.4.0

● Score: 92/100 (A+)
  █ Vitality  ▓ Tech  █ Trust  ▒ Maint

Key Metrics
  Publisher:   dart.dev ✓
  Pub Score:   135/140 ●
  Popularity:  98% ●●●
  GitHub:      ⭐ 12.0K
  Last Update: 1 month ago 🟢

✓ Recommended - High-quality, actively maintained package
```

**Output (Verbose):**

```
🔍 dio v5.4.0

[CACHE] ✅ Hit (2h old, valid)
[DATA]
  Last update:   45 days ago
  Publisher:     dart.dev (trusted ✅)
  Pub points:    135/140 (96%)
  Popularity:    0.98
  Repository:    ✅ github.com/cfug/dio

[SCORE: 92/100 ✅]
  Vitality      38/40  ✅ (Updated recently)
  Tech Health   28/30  ✅ (Excellent Pana score)
  Trust         19/20  ✅ (High popularity)
  Maintenance    7/10  ✅ (Verified publisher)

💡 Recommended for production
⏱️  315ms (1 API call, now cached)
```

**See also:** [docs/view.md](docs/view.md) for output customization

---

### Config Command

Manage global and project-level configuration.

```bash
cura config <subcommand> [options]
```

**Subcommands:**

- `show` - Display current configuration
- `init` - Create project config (`./.cura/config.yaml`)
- `edit` - Open config in editor
- `set <key> <value>` - Set a configuration value
- `get <key>` - Get a configuration value
- `reset` - Reset to defaults
- `validate` - Validate config file

**Examples:**

```bash
# Show config hierarchy
cura config show

# Initialize project config
cura config init

# Set global preference
cura config set theme dracula --global

# Set project-specific min score
cura config set min_score 85 --project

# Edit config
cura config edit --global
```

**See also:** [docs/configuration.md](docs/configuration.md) for all options

---

## 📊 Scoring Algorithm

Cura calculates a score from **0 to 100** based on weighted criteria:

### Score Breakdown

```
Total Score = Vitality (40) + Technical Health (30) + Trust (20) + Maintenance (10)
```

#### 1. Vitality (40 points)

Measures how actively maintained the package is.

| Last Update | Score |
|-------------|-------|
| < 1 month   | 40    |
| 1-3 months  | 35    |
| 3-6 months  | 28    |
| 6-12 months | 20    |
| 1-2 years   | 10    |
| > 2 years   | 0     |

**Exceptions:** Packages with high Pana scores (>130) and proven stability receive bonus points even if older.

#### 2. Technical Health (30 points)

Evaluates code quality and platform support.

- **Pana Score** (15pts): Normalized from pub.dev's 0-140 scale
- **Null Safety** (10pts): Supports null safety
- **Platform Support** (5pts): Number of supported platforms (iOS, Android, Web, etc.)

#### 3. Trust (20 points)

Measures community confidence.

- **Likes** (10pts): Normalized from pub.dev likes
- **Popularity** (10pts): Based on download metrics

#### 4. Maintenance (10 points)

Indicates official support and reliability.

- **Verified Publisher** (5pts): Has verified publisher
- **Flutter Favorite** (5pts): Official Flutter Favorite badge

### Grade Mapping

| Score | Grade | Meaning |
|-------|-------|---------|
| 90-100 | A+ | Excellent - Production ready |
| 80-89 | A | Very good - Highly recommended |
| 70-79 | B | Good - Safe to use |
| 60-69 | C | Fair - Use with caution |
| 50-59 | D | Poor - Consider alternatives |
| 0-49 | F | Critical - Avoid |

### Penalties

Automatic score of **0** if:

- Package is marked as discontinued
- Critical security vulnerabilities detected (via OSV.dev)

**See also:** [docs/scoring.md](docs/scoring.md) for detailed algorithm explanation

---

## ⚙️ Configuration

Cura supports hierarchical configuration: **Project > Global > Defaults**

### Config Locations

```
~/.cura/config.yaml          # Global config (user preferences)
./.cura/config.yaml          # Project config (team standards)
```

### Config Hierarchy

```
CLI Flags (highest priority)
    ↓
Project Config (./.cura/config.yaml)
    ↓
Global Config (~/.cura/config.yaml)
    ↓
Defaults (lowest priority)
```

### Example Configuration

**Global Config** (`~/.cura/config.yaml`):

```yaml
# Appearance
theme: dracula
use_emojis: true
use_colors: true

# Cache
cache_max_age: 24  # hours
auto_update: true

# Scoring
min_score: 70

# API
timeout_seconds: 10
github_token: ghp_your_token_here

# Suggestions
show_suggestions: true
max_suggestions_per_package: 3
```

**Project Config** (`./.cura/config.yaml`):

```yaml
# Override for this project
min_score: 85

# Ignore internal packages
ignore_packages:
  - internal_test_package

# Trust company packages
trusted_publishers:
  - my-company.dev
```

### Common Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `theme` | string | `dark` | UI theme (dark, light, minimal, dracula) |
| `min_score` | int | `70` | Minimum acceptable score |
| `cache_max_age` | int | `24` | Cache TTL in hours |
| `github_token` | string | `null` | GitHub PAT for higher rate limits |
| `ignore_packages` | list | `[]` | Packages to skip during analysis |
| `trusted_publishers` | list | `[]` | Auto-approve publishers |

**See also:** [docs/configuration.md](docs/configuration.md) for full reference

---

## 🔄 CI/CD Integration

### GitHub Actions

```yaml
name: Cura Health Check

on: [push, pull_request]

jobs:
  health:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: dart-lang/setup-dart@v1
      
      - name: Install Cura
        run: dart pub global activate cura
      
      - name: Health Check
        run: cura check --min-score 75 --fail-on-vulnerable
```

### GitLab CI

```yaml
cura_check:
  image: dart:stable
  script:
    - dart pub global activate cura
    - cura check --min-score 80 --quiet
  allow_failure: false
```

### Exit Codes

- `0` - All checks passed
- `1` - Failed (score below threshold, vulnerabilities, etc.)

**See also:** [docs/ci-cd.md](docs/ci-cd.md) for advanced workflows

---

## 🎨 Advanced Features

### Themes

Switch between 4 built-in themes:

```bash
# Via CLI flag
cura check --theme=dracula

# Via config
cura config set theme light

# Via environment variable
export CURA_THEME=minimal
cura check
```

**Available Themes:**

- `dark` - Default, vibrant colors
- `light` - For light terminals
- `minimal` - Monochrome, CI/CD friendly
<!-- - `dracula` - Popular Dracula color scheme -->

**See also:** [docs/themes.md](docs/themes.md) for theme customization

---

### Caching

Cura uses local SQLite cache to minimize API calls.

**Cache locations:**

```
~/.cura/cache/cura_cache.db           # Package scores
~/.cura/suggestions_cache.yaml        # Alternative suggestions
```

**Cache management:**

```bash
# Clear cache
cura clean

# View cache stats
cura config show

# Disable cache
cura check --no-cache
```

**Cache TTL:**

- Popular packages (>1000 likes): 1 hour
- Normal packages: 24 hours
- Failed requests: Not cached

**See also:** [docs/caching.md](docs/caching.md) for cache strategies

---
<!-- 
### Suggestions Engine

Cura suggests better alternatives for low-scoring packages.

**How it works:**

1. Maintains a community-driven database of alternatives
2. Validates each suggestion's health score (must be >70)
3. Auto-updates from GitHub every 24h

**Example:**

```
⚠️  provider (68/100)
   💡 Better Alternatives:
      → riverpod (92/100) - Modern, compile-safe state management
        Migration: https://riverpod.dev/docs/from_provider
```

**Contributing suggestions:**

1. Fork [cura-data](https://github.com/meragix/cura-data)
2. Edit `alternatives.yaml`
3. Submit PR (auto-validated)

**See also:** [docs/suggestions.md](docs/suggestions.md) for details

--- -->

### Multi-API Aggregation

Cura aggregates data from multiple sources:

| Source | Data Retrieved |
|--------|----------------|
| **pub.dev** | Pana score, likes, popularity, publisher |
| **GitHub** | Stars, issues, commits, contributors |
| **OSV.dev** | Security vulnerabilities (CVEs) |

**GitHub integration:**

```bash
# Set GitHub token for higher rate limits
cura config set github_token ghp_xxxxx

# Disable GitHub (faster, offline)
cura scan --no-github
```

**Rate limits:**

- pub.dev: ~10 req/s (built-in retry)
- GitHub: 60 req/h (5000/h with token)
- OSV.dev: No limit

**See also:** [docs/api-integration.md](docs/api-integration.md)

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### Bug Reports & Feature Requests

[Open an issue](https://github.com/meragix/cura/issues/new) with:

- Clear description
- Steps to reproduce (for bugs)
- Expected vs actual behavior

### Code Contributions

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feat/amazing-feature`)
5. Open a Pull Request

**Development setup:**

```bash
git clone https://github.com/meragix/cura.git
cd cura
dart pub get
dart run bin/cura.dart --help
```

**Run tests:**

```bash
dart test
```

<!-- ### Suggesting Package Alternatives

Contribute to [cura-data](https://github.com/meragix/cura-data):

1. Fork the repo
2. Edit `alternatives.yaml` -->
1. Submit PR (auto-validated by CI)

**See also:** [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines

---

## 📚 Documentation

- [Scoring Algorithm](docs/scoring.md) - Detailed score calculation
- [Configuration](docs/configuration.md) - All config options
- [CI/CD Integration](docs/ci-cd.md) - GitHub Actions, GitLab CI examples
- [Themes](docs/themes.md) - Theme customization
- [API Integration](docs/api-integration.md) - Multi-API architecture
- [Caching](docs/caching.md) - Cache strategies
- [Suggestions](docs/suggestions.md) - Alternatives engine

---

## 🗺️ Roadmap

### v1.x (Current)

- ✅ Core scoring algorithm
- ✅ CLI with scan/view/check commands
- ✅ Multi-API aggregation
- ✅ Config system (global + project)
- ✅ Themes

### v2.0 (Planned)

- 🔄 Backend service (optional)
- 🔄 Web dashboard
- 🔄 Badge service (shields.io style)
- 🔄 VS Code extension
- 🔄 GitHub Action (pre-built)

### Future

- 📅 Trend analysis (score over time)
- 📅 Dependency tree visualization
- 📅 Package comparison tool
- 📅 Custom scoring weights

**Vote on features:** [GitHub Discussions](https://github.com/orgs/meragix/discussions)

---

## 💬 Community

- **Discord:** [Join our server](https://discord.gg/meragix)
- **Twitter:** [@Meragix](https://twitter.com/meragix)
- **Discussions:** [GitHub Discussions](https://github.com/orgs/meragix/discussions)

---

## 📄 License

Cura is MIT licensed. See [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

- Inspired by [Pana](https://pub.dev/packages/pana) and npm's [Snyk](https://snyk.io/)
- Built with [mason_logger](https://pub.dev/packages/mason_logger) for beautiful CLI output
- Data provided by [pub.dev](https://pub.dev), [GitHub](https://github.com), and [OSV.dev](https://osv.dev)

---

<p align="center">
  Made with ❤️ for the Flutter/Dart community
</p>

<p align="center">
  <a href="https://github.com/meragix/cura">⭐ Star us on GitHub</a> •
  <a href="https://github.com/meragix/cura/issues">🐛 Report Bug</a> •
  <a href="https://github.com/orgs/meragix/discussions">💬 Discussions</a>
</p>
