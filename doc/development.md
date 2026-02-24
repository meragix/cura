# Development Guide

Complete guide for setting up Cura locally and contributing code.

---

## Prerequisites

### Required

- **Dart SDK** >= 3.0.0

  ```bash
  # macOS via Homebrew
  brew tap dart-lang/dart
  brew install dart

  # or download from https://dart.dev/get-dart
  dart --version
  ```

- **Git** >= 2.0

### Recommended

- **VS Code** with the [Dart extension](https://marketplace.visualstudio.com/items?itemName=Dart-Code.dart-code)
- **GitHub CLI** for the PR workflow

  ```bash
  brew install gh
  gh auth login
  ```

---

## Initial Setup

```bash
# 1. Fork on GitHub, then clone your fork
git clone https://github.com/YOUR_USERNAME/cura.git
cd cura

# 2. Add the upstream remote
git remote add upstream https://github.com/meragix/cura.git

# 3. Install dependencies
dart pub get

# 4. Verify the setup
dart run bin/cura.dart --help
```

---

## Project Structure

```text
bin/
  cura.dart                    # Entry point -- composition root

lib/src/
  domain/                      # Pure Dart, no external deps
    entities/
    value_objects/
    ports/                     # Abstract interfaces
    usecases/
    exceptions/

  application/
    commands/                  # CLI command implementations
    dto/

  infrastructure/              # External adapters
    api/clients/               # pub.dev, GitHub, OSV.dev HTTP clients
    aggregators/               # MultiApiAggregator, CachedAggregator
    cache/                     # SQLite database + TTL strategy
    repositories/              # YAML config repository

  presentation/
    loggers/                   # ConsoleLogger
    presenters/                # CheckPresenter, ViewPresenter
    renderers/                 # Table, bar, summary rendering
    themes/                    # dark, light, minimal
    formatters/

  shared/
    constants/
    utils/                     # HttpHelper, PoolManager
    app_info.dart

test/
  unit/                        # Business logic tests
  integration/                 # API client tests
  e2e/                         # CLI end-to-end tests
```

---

## Running Locally

```bash
# Audit the current project
dart run bin/cura.dart check

# Inspect a package
dart run bin/cura.dart view dio --verbose

# Show the active config
dart run bin/cura.dart config show

# Cache stats
dart run bin/cura.dart cache stats
```

---

## Testing

```bash
# Run all tests
dart test

# Run a single file
dart test test/unit/domain/usecases/calculate_score_test.dart

# Run tests matching a name pattern
dart test --name "calculates vitality"

# Verbose output
dart test --reporter=expanded

# Generate coverage data
dart test --coverage=coverage
```

**Target:** >= 80 % line coverage across unit and integration tests.

### Writing a unit test

```dart
import 'package:test/test.dart';
import 'package:cura/src/domain/usecases/calculate_score.dart';

void main() {
  group('CalculateScore', () {
    test('returns 0 for discontinued packages', () {
      // arrange
      final useCase = CalculateScore();
      // act + assert ...
    });
  });
}
```

---

## Code Quality

```bash
# Format all files
dart format .

# Format check (CI mode -- exits non-zero if changes needed)
dart format --set-exit-if-changed .

# Static analysis
dart analyze

# Apply automatic fixes
dart fix --apply
```

All three must pass before opening a pull request.

---

## Contribution Workflow

1. Create a feature branch from `main`:

   ```bash
   git checkout -b feat/my-feature
   ```

2. Make changes, run tests and analysis:

   ```bash
   dart test
   dart format --set-exit-if-changed .
   dart analyze
   ```

3. Commit using [Conventional Commits](https://www.conventionalcommits.org/):

   ```text
   feat: add --no-osv flag to skip vulnerability checks
   fix: prevent double-init race in CacheDatabase
   chore: update sqflite_common_ffi to 2.3.0
   ```

4. Push and open a pull request against `main`.

Branch naming convention: `feat/description`, `fix/description`,
`chore/description`.

---

## Architecture Principles

- **No service locator** -- all dependencies are injected via constructors.
- **Domain isolation** -- `lib/src/domain/` must not import anything from
  `infrastructure/` or `presentation/`.
- **Ports & Adapters** -- domain interfaces (`ports/`) define contracts;
  infrastructure provides concrete implementations.
- **Sealed result types** -- use `Result<T>` and `PackageResult` instead of
  throwing exceptions across layer boundaries.
- **Minimum viable complexity** -- do not add abstractions, helpers, or
  configuration options that do not have an immediate use case.

---

## Related

- [Architecture overview](architecture.md) -- layer diagram and key patterns
- [Configuration reference](configuration.md) -- all config keys
- [Scoring algorithm](scoring.md) -- how scores are calculated
