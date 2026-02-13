# Development Guide

Complete guide for setting up and developing Cura locally.

---

## Prerequisites

### Required

- **Dart SDK** ≥ 3.0.0

  ```bash
  # Install via Homebrew (macOS)
  brew tap dart-lang/dart
  brew install dart
  
  # Or download from https://dart.dev/get-dart
  ```

- **Git** ≥ 2.0

  ```bash
  git --version
  ```

### Recommended

- **VS Code** with Dart extension
- **GitHub CLI** (for PR workflow)

  ```bash
  brew install gh
  gh auth login
  ```

---

## Initial Setup

### 1. Fork and Clone

```bash
# Fork on GitHub (click Fork button)

# Clone your fork
git clone https://github.com/YOUR_USERNAME/cura.git
cd cura

# Add upstream remote
git remote add upstream https://github.com/your-org/cura.git
```

### 2. Install Dependencies

```bash
# Install Dart dependencies
dart pub get

# Verify installation
dart pub deps
```

### 3. Generate Code (Freezed, JSON Serializable)

```bash
# Generate model code
cd packages/cura
dart run build_runner build --delete-conflicting-outputs

# Watch for changes during development
dart run build_runner watch
```

### 4. Verify Setup

```bash
# Run CLI locally
dart run bin/cura.dart --help

# Should output:
# Usage: cura <command> [arguments]
# ...
```

---

## Project Structure Deep Dive

```shell
cura/
├── bin/
│   └── cura.dart                       # CLI entry point
│
├── lib/
│   ├── cura_cli.dart                   # Public exports
│   │
│   └── src/
│       ├── commands/                   # Command implementations
│       │   ├── base/
│       │   │   ├── base_command.dart   # Base class for all commands
│       │   │   └── command_context.dart # DI container
│       │   │
│       │   ├── scan_command.dart       # cura scan
│       │   ├── view_command.dart       # cura view
│       │   ├── check_command.dart      # cura check
│       │   └── config_command.dart     # cura config
│       │
│       ├── presentation/               # UI/Formatting layer
│       │   ├── loggers/
│       │   │   ├── cura_logger.dart    # Base logger interface
│       │   │   ├── output/
│       │   │   │   ├── normal_logger.dart
│       │   │   │   ├── verbose_logger.dart
│       │   │   │   ├── quiet_logger.dart
│       │   │   │   └── json_logger.dart
│       │   │   └── specialized/
│       │   │       ├── scan_logger.dart
│       │   │       ├── view_logger.dart
│       │   │       └── check_logger.dart
│       │   │
│       │   ├── renderers/
│       │   │   ├── table_renderer.dart
│       │   │   ├── progress_renderer.dart
│       │   │   └── summary_renderer.dart
│       │   │
│       │   ├── formatters/
│       │   │   ├── score_formatter.dart
│       │   │   ├── date_formatter.dart
│       │   │   └── number_formatter.dart
│       │   │
│       │   ├── themes/
│       │   │   ├── theme.dart          # Theme interface
│       │   │   ├── dark_theme.dart
│       │   │   ├── light_theme.dart
│       │   │   ├── minimal_theme.dart
│       │   │   └── dracula_theme.dart
│       │   │
│       │   └── widgets/                # Reusable UI components
│       │       ├── header.dart
│       │       ├── table.dart
│       │       └── progress_bar.dart
│       │
│       ├── core/                       # Business logic
│       │   ├── models/
│       │   │   ├── cura_package.dart   # Package model (Freezed)
│       │   │   ├── cura_score.dart     # Score model
│       │   │   └── health_metrics.dart
│       │   │
│       │   ├── calculators/
│       │   │   └── score_calculator.dart # Scoring algorithm
│       │   │
│       │   └── services/
│       │       ├── suggestion_service.dart
│       │       └── multi_api_service.dart
│       │
│       ├── infrastructure/            # External services
│       │   ├── api/
│       │   │   ├── pub_dev_client.dart # pub.dev API
│       │   │   ├── github_client.dart  # GitHub API
│       │   │   └── osv_client.dart     # OSV.dev API
│       │   │
│       │   └── cache/
│       │       └── local_cache.dart    # SQLite cache
│       │
│       ├── config/
│       │   ├── config_manager.dart     # Config loading
│       │   └── constants.dart
│       │
│       └── utils/
│           ├── extensions/
│           └── helpers/
│
├── test/                               # Tests mirror lib/ structure
│   ├── unit/
│   ├── integration/
│   └── e2e/
│
├── docs/                               # Documentation
├── examples/                           # Usage examples
└── scripts/                            # Build/deployment scripts
```

---

## Development Workflow

### Running Locally

```bash
# Run CLI with arguments
dart run bin/cura.dart scan

# Run specific command
dart run bin/cura.dart view riverpod --verbose

# Test config
dart run bin/cura.dart config show
```

### Hot Reload (Development)

```bash
# Use a file watcher to rebuild on changes
dart run build_runner watch &
dart run bin/cura.dart scan
```

---

## Testing

### Unit Tests

```bash
# Run all tests
dart test

# Run specific test file
dart test test/core/calculators/score_calculator_test.dart

# Run with filter
dart test --name "calculates vitality"

# Verbose output
dart test --reporter=expanded
```

### Integration Tests

```bash
# Run integration tests (hit real APIs)
dart test test/integration/

# With retry on failure (flaky API tests)
dart test --test-randomize-ordering-seed=random test/integration/
```

### End-to-End Tests

```bash
# Run CLI tests
dart test test/e2e/cli_test.dart
```

### Coverage

```bash
# Generate coverage
dart test --coverage=coverage

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html
```

### Writing Tests

**Example unit test:**

```dart
import 'package:test/test.dart';
import 'package:cura_cli/src/core/calculators/score_calculator.dart';

void main() {
  group('ScoreCalculator', () {
    test('returns 0 for discontinued packages', () {
      // Given
      final package = CuraPackage(
        isDiscontinued: true,
        lastPublished: DateTime.now(),
        metrics: HealthMetrics(panaScore: 130, likes: 1000, popularity: 90),
      );

      // When
      final score = ScoreCalculator.calculate(package);

      // Then
      expect(score.total, equals(0));
      expect(score.grade, equals('F'));
    });
  });
}
```

---

## Code Quality

### Formatting

```bash
# Format all files
dart format .

# Check formatting (CI)
dart format --set-exit-if-changed .

# Format specific files
dart format lib/src/commands/
```

### Analysis

```bash
# Analyze all code
dart analyze

# Analyze with fatal warnings
dart analyze --fatal-infos

# Fix auto-fixable issues
