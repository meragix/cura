# Contributing to Cura

This document specifies the guidelines and procedures for contributing to the
project. It covers bug reporting, feature proposals, code contributions, coding
standards, testing requirements, and the release process.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Release Process](#release-process)

---

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).

Required conduct for all contributors and maintainers:

- Respectful and inclusive communication
- Constructive feedback
- Acceptance of criticism
- No harassment, trolling, or personal attacks

---

## How to Contribute

### Reporting Bugs

Before creating a bug report, check the [issue tracker](https://github.com/meragix/cura/issues) to avoid duplicates.

**Bug report requirements:**

1. A clear and descriptive title
2. Exact steps to reproduce the problem
3. Specific examples (commands, inputs, outputs)
4. Description of observed behaviour and expected behaviour
5. Screenshots if applicable
6. Environment details:
   - OS (macOS, Linux, Windows)
   - Dart SDK version
   - Cura version

**Bug Report Template:**

```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Run `cura scan`
2. See error

**Expected behavior**
What you expected to happen.

**Actual behavior**
What actually happened.

**Environment**
- OS: macOS 13.0
- Dart SDK: 3.2.0
- Cura version: 1.0.0

**Additional context**
Any other relevant information.
```

---

### Suggesting Features

Before submitting a feature request:

1. Check if it is already proposed in [discussions](https://github.com/meragix/cura/discussions)
2. Verify that it fits Cura's scope (package health analysis)
3. Define the use case clearly (who benefits and how)

**Feature Request Template:**

```markdown
**Is your feature request related to a problem?**
A clear description of the problem.

**Describe the solution you'd like**
A clear description of what you want to happen.

**Describe alternatives you've considered**
Alternative solutions or features you've considered.

**Additional context**
Any other context, mockups, or examples.
```

---

### Contributing Code

Procedure for code contributions:

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/description`)
3. Make your changes
4. Write or update tests
5. Update documentation
6. Commit using Conventional Commits
7. Push and open a pull request

See [Development Workflow](#development-workflow) for detailed steps.

---

### Improving Documentation

Documentation contributions include:

- Correcting typos or imprecise explanations
- Adding usage examples
- Expanding technical reference material

**Documentation locations:**

- `README.md` — project overview and command reference
- `doc/` — detailed documentation (scoring, architecture, caching, CI/CD)
- Inline doc comments (`///`)
- `CONTRIBUTING.md` — this guide

---

### Contributing to the Suggestions Database

To add or update package alternatives:

1. Fork [cura-data](https://github.com/meragix/cura-data)
2. Edit `alternatives.yaml`
3. Follow the format:

   ```yaml
   deprecated_package:
     - package: better_alternative
       reason: "Why it's better"
       migration_guide: "https://..."
       tags: ["category"]
   ```

4. Submit a PR (auto-validated by CI)

---

## Development Setup

### Project Structure

```text
lib/
├── src/
│   ├── domain/                    # Pure Dart, zero external dependencies
│   │   ├── entities/              # PackageInfo, Score, GitHubMetrics, Vulnerability
│   │   ├── value_objects/         # Grade, RedFlag, Recommendation, ScoreWeights
│   │   ├── ports/                 # Abstract interfaces (ScoreCalculator, etc.)
│   │   ├── usecases/              # CalculateScore, CheckPackages, ViewPackageDetails
│   │   └── services/scoring/      # Strategy dimensions (Vitality, Trust, etc.)
│   ├── infrastructure/            # External adapters (pub.dev, GitHub, OSV.dev, cache)
│   ├── application/               # Commands (orchestration layer)
│   ├── presentation/              # CLI UI (formatters, renderers, presenters)
│   └── shared/                    # Utilities, constants
test/
├── unit/               # Unit tests (fast, isolated)
├── integration/        # Integration tests (with real APIs)
└── e2e/                # End-to-end CLI tests
```

### Prerequisites

- **Dart SDK** >= 3.0.0
- **Git**
- **Code editor** (VS Code recommended)
- Familiarity with Clean Architecture / Hexagonal Architecture principles

### Setup

```bash
# 1. Fork and clone
git clone https://github.com/meragix/cura.git
cd cura

# 2. Install dependencies
dart pub get

# 3. Run locally
dart run bin/cura.dart --help

# 4. Run tests
dart test

# 5. Format code
dart format .

# 6. Analyze
dart analyze
```

### Recommended VS Code Extensions

```json
{
  "recommendations": [
    "dart-code.dart-code",
    "dart-code.flutter",
    "usernamehw.errorlens",
    "streetsidesoftware.code-spell-checker"
  ]
}
```

### Environment Setup

```bash
# Optional: Set up Git hooks
cp scripts/pre-commit .git/hooks/
chmod +x .git/hooks/pre-commit

# Optional: Configure GitHub CLI
gh auth login
```

---

## Development Workflow

### 1. Create a Feature Branch

```bash
# Update main
git checkout main
git pull origin main

# Create feature branch
git checkout -b feat/my-feature

# Or for a bugfix
git checkout -b fix/my-bugfix
```

### 2. Make Changes

Required:

- Write self-documenting code
- Add tests for new functionality
- Update relevant documentation
- Keep commits atomic and focused
- Follow the style guide

Prohibited:

- Mixing multiple concerns in one commit
- Leaving commented-out code
- Adding dependencies without justification
- Skipping tests

### 3. Test Your Changes

```bash
# Run all tests
dart test

# Run specific test file
dart test test/unit/domain/usecases/calculate_score_test.dart

# Run with coverage
dart test --coverage=coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### 4. Format and Analyze

```bash
# Format code
dart format .

# Analyze
dart analyze

# Fix auto-fixable issues
dart fix --apply
```

### 5. Commit Changes

Use [Conventional Commits](https://www.conventionalcommits.org/):

```bash
git add .
git commit -m "feat: add GitHub stars to score calculation"

# Types: feat, fix, docs, style, refactor, test, chore
```

### 6. Push and Create PR

```bash
git push origin feat/my-feature

# Create PR on GitHub
gh pr create --title "feat: add GitHub stars to score" --body "Description..."
```

---

## Coding Standards

### Dart Style Guide

Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines.

```dart
// Correct
class ScoreCalculator {
  /// Calculates the health score for a package.
  ///
  /// Returns a score from 0-100.
  static int calculate(CuraPackage package) {
    // Implementation
  }
}

// Incorrect
class score_calculator {
  // No documentation
  static int calc(pkg) { }
}
```

### Code Organization

Single Responsibility Principle:

```dart
// Correct: single responsibility per class
class PubDevClient {
  Future<PackageInfo> getPackageInfo(String name) { }
}

class ScoreCalculator {
  static int calculate(PackageInfo info) { }
}

// Incorrect: mixed responsibilities
class PackageService {
  Future<int> getScoreFromPubDev(String name) {
    // Fetching and calculating in the same method
  }
}
```

### Error Handling

```dart
// Correct: typed exceptions
if (response.statusCode == 404) {
  throw PackageNotFoundException(packageName);
}

// Correct: graceful degradation
try {
  final score = await calculateScore(pkg);
} catch (e) {
  logger.warn('Score calculation failed: $e');
  return defaultScore;
}

// Incorrect: silent failures
try {
  await dangerousOperation();
} catch (e) {
  // swallowed
}
```

### Naming Conventions

| Type      | Convention     | Example            |
|-----------|----------------|--------------------|
| Classes   | PascalCase     | `ScoreCalculator`  |
| Functions | camelCase      | `calculateScore()` |
| Variables | camelCase      | `packageName`      |
| Constants | lowerCamelCase | `defaultTimeout`   |
| Private   | prefix `_`     | `_privateMethod()` |

---

## Testing

### Test Structure

```dart
void main() {
  group('CalculateScore', () {
    test('returns 0 for discontinued packages', () {
      final score = Score.discontinued('my_package');

      expect(score.total, equals(0));
      expect(score.grade, equals(Grade.f));
    });
  });

  group('VitalityDimension', () {
    test('scores 35 pts for a package updated 45 days ago', () {
      final dimension = VitalityDimension(weight: 40);
      final input = (
        package: mockPackageUpdatedDaysAgo(45),
        github: null,
        vulnerabilities: const <Vulnerability>[],
      );

      expect(dimension.calculate(input), equals(35));
    });
  });
}
```

### Test Coverage

Target: >= 80% line coverage.

Priority order:

1. Business logic (calculators, services)
2. API clients
3. Error handling
4. UI formatters

Generate a coverage report:

```bash
dart test --coverage=coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Mocking

Use [mocktail](https://pub.dev/packages/mocktail) for ports and aggregators.
Scoring dimensions can be tested without mocking — pass a `ScoringInput` record
directly:

```dart
import 'package:mocktail/mocktail.dart';

// Mock a port (abstract interface)
class MockScoreCalculator extends Mock implements ScoreCalculator {}

// Test a dimension without any mock — ScoringInput is a plain record
void main() {
  test('TrustDimension awards stars bonus', () {
    final dimension = TrustDimension(weight: 20);
    final input = (
      package: mockPackageWithLikes(1200),
      github: GitHubMetrics(stars: 1500, ...),
      vulnerabilities: const [],
    );

    expect(dimension.calculate(input), greaterThan(20));
  });
}
```

---

## Commit Guidelines

### Conventional Commits

Format: `<type>(<scope>): <subject>`

**Types:**

- `feat`: new feature
- `fix`: bug fix
- `docs`: documentation only
- `style`: formatting (no code change)
- `refactor`: code restructuring
- `test`: adding tests
- `chore`: maintenance

**Examples:**

```bash
feat(scoring): add GitHub stars to trust calculation
fix(cache): handle concurrent JSON file writes safely
docs(api): update configuration examples
refactor(ui): extract table rendering to separate class
test(calculator): add edge cases for vitality score

# Breaking change
feat(config)!: rename min_score to minimum_score

BREAKING CHANGE: Configuration key changed from min_score to minimum_score
```

### Commit Requirements

- Imperative mood ("add feature", not "added feature")
- Subject line under 72 characters
- Reference issue numbers where applicable (`fixes #123`)
- Explain why, not just what

Do not:

- Commit unrelated changes together
- Use vague messages ("fix stuff", "WIP")
- Commit commented-out code

---

## Pull Request Process

### Pre-submission Checklist

- [ ] Tests pass (`dart test`)
- [ ] Code is formatted (`dart format .`)
- [ ] No analyzer warnings (`dart analyze`)
- [ ] Documentation updated
- [ ] CHANGELOG.md updated (if user-facing)

### PR Template

```markdown
## Description
Brief description of changes.

## Type of Change
- [ ] Bug fix (non-breaking)
- [ ] New feature (non-breaking)
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Added unit tests
- [ ] Added integration tests
- [ ] Manual testing performed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-reviewed code
- [ ] Commented complex logic
- [ ] Updated documentation
- [ ] No new warnings

## Related Issues
Fixes #123
```

### Review Process

1. Automated checks run (CI/CD)
2. Maintainer review (typically within 48 hours)
3. Discussion and iteration
4. Approval and merge

Reviewers evaluate:

- Code quality and style
- Test coverage
- Documentation accuracy
- Performance implications
- Breaking changes

---

## Release Process

### Versioning

The project follows [Semantic Versioning](https://semver.org/):

- **MAJOR** (1.0.0): breaking changes
- **MINOR** (0.1.0): new features, backward compatible
- **PATCH** (0.0.1): bug fixes

### Release Checklist

1. Update version in `pubspec.yaml`
2. Update `CHANGELOG.md`
3. Create release branch

   ```bash
   git checkout -b release/v1.2.0
   ```

4. Run full test suite
5. Build and test locally
6. Create PR to main
7. After merge, tag the release

   ```bash
   git tag v1.2.0
   git push origin v1.2.0
   ```

8. Publish to pub.dev

   ```bash
   dart pub publish
   ```

9. Create a GitHub release with notes

---

## Reference

### Dart Resources

- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Testing Guide](https://dart.dev/guides/testing)

### Dependencies

- [args package](https://pub.dev/packages/args)
- [mason_logger](https://pub.dev/packages/mason_logger)
- [mocktail](https://pub.dev/packages/mocktail)

---

## Getting Help

- **Questions:** [GitHub Discussions](https://github.com/meragix/cura/discussions)
- **Issues:** [Issue Tracker](https://github.com/meragix/cura/issues)

---

## Recognition

Contributors are credited in `CONTRIBUTORS.md`, release notes, and the project README.
