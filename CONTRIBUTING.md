# Contributing to Cura

First off, thank you for considering contributing to Cura! 🎉

This document provides guidelines and instructions for contributing. Whether you're fixing a bug, adding a feature, or improving documentation, your contributions are welcome.

---

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Release Process](#release-process)

---

## 📜 Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).

**In short:**

- ✅ Be respectful and inclusive
- ✅ Focus on constructive feedback
- ✅ Accept criticism gracefully
- ✅ Adherence to this code is mandatory for all contributors and maintainers.
- ❌ No harassment, trolling, or personal attacks

---

## 🤝 How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the [issue tracker](https://github.com/meragix/cura/issues) to avoid duplicates.

**How to submit a bug report:**

1. **Use a clear and descriptive title**
2. **Describe the exact steps to reproduce the problem**
3. **Provide specific examples** (commands, inputs, outputs)
4. **Describe the behavior you observed** and what you expected
5. **Include screenshots** if applicable
6. **Specify your environment:**
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

We love feature suggestions! Before submitting:

1. **Check if it's already suggested** in [discussions](https://github.com/meragix/cura/discussions)
2. **Consider if it fits Cura's scope** (package health analysis)
3. **Think about the use case** (who benefits and why)

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

We welcome code contributions! Here's how to get started:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feat/amazing-feature`)
3. **Make your changes**
4. **Write or update tests**
5. **Update documentation**
6. **Commit with conventional commits**
7. **Push and create a Pull Request**

See [Development Workflow](#development-workflow) for detailed steps.

---

### Improving Documentation

Documentation is crucial! You can contribute by:

- Fixing typos or unclear explanations
- Adding examples
- Writing tutorials
- Translating documentation
- Creating video guides

**Documentation locations:**

- `README.md` — Main project readme
- `doc/` — Detailed documentation (scoring, architecture, caching, CI/CD, etc.)
- Inline code comments and doc comments (`///`)
- `CONTRIBUTING.md` — This guide

---

### Contributing to Suggestions Database

Help build the alternatives database:

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

## 🛠️ Development Setup

### Project Structure

````bash
lib/
├── src/
│   ├── domain/                    # Pure Dart — zero external dependencies
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
````

### Prerequisites

- **Dart SDK** ≥ 3.0.0
- **Git**
- **Code editor** (VS Code recommended)
- Basic understanding of Clean Architecture principles

### Quick Start

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

## 🔄 Development Workflow

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

Follow these principles:

**✅ Do:**

- Write self-documenting code
- Add tests for new functionality
- Update relevant documentation
- Keep commits atomic and focused
- Follow the style guide

**❌ Don't:**

- Mix multiple concerns in one commit
- Leave commented-out code
- Add dependencies without justification
- Skip tests

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

## 📏 Coding Standards

### Dart Style Guide

Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines.

**Key points:**

```dart
// ✅ Good
class ScoreCalculator {
  /// Calculates the health score for a package.
  /// 
  /// Returns a score from 0-100.
  static int calculate(CuraPackage package) {
    // Implementation
  }
}

// ❌ Bad
class score_calculator {
  // No documentation
  static int calc(pkg) { }
}
```

### Code Organization

**Separation of Concerns:**

```dart
// ✅ Good - Single Responsibility
class PubDevClient {
  Future<PackageInfo> getPackageInfo(String name) { }
}

class ScoreCalculator {
  static int calculate(PackageInfo info) { }
}

// ❌ Bad - Mixed responsibilities
class PackageService {
  Future<int> getScoreFromPubDev(String name) {
    // Fetching AND calculating mixed
  }
}
```

### Error Handling

```dart
// ✅ Good - Specific exceptions
if (response.statusCode == 404) {
  throw PackageNotFoundException(packageName);
}

// ✅ Good - Graceful degradation
try {
  final score = await calculateScore(pkg);
} catch (e) {
  logger.warn('Score calculation failed: $e');
  return defaultScore;
}

// ❌ Bad - Silent failures
try {
  await dangerousOperation();
} catch (e) {
  // Swallowed
}
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `ScoreCalculator` |
| Functions | camelCase | `calculateScore()` |
| Variables | camelCase | `packageName` |
| Constants | lowerCamelCase | `defaultTimeout` |
| Private | prefix `_` | `_privateMethod()` |

---

## 🧪 Testing

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

**Target:** ≥ 80% coverage

**Priority:**

1. Business logic (calculators, services)
2. API clients
3. Error handling
4. UI formatters

**Check coverage:**

```bash
dart test --coverage=coverage
genhtml coverage/lcov.info -o coverage/html

# View in browser
open coverage/html/index.html
```

### Mocking

Use [mocktail](https://pub.dev/packages/mocktail) for ports and aggregators.
Scoring dimensions can be tested without mocking — pass a `ScoringInput` record directly:

```dart
import 'package:mocktail/mocktail.dart';

// Mock a port (abstract interface)
class MockScoreCalculator extends Mock implements ScoreCalculator {}

// Test a dimension without any mock — ScoringInput is just a record
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

## 📝 Commit Guidelines

### Conventional Commits

Format: `<type>(<scope>): <subject>`

**Types:**

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting (no code change)
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance

**Examples:**

```bash
# Feature
feat(scoring): add GitHub stars to trust calculation

# Bug fix
fix(cache): handle concurrent JSON file writes safely

# Documentation
docs(api): update configuration examples

# Refactor
refactor(ui): extract table rendering to separate class

# Test
test(calculator): add edge cases for vitality score

# Breaking change
feat(config)!: rename min_score to minimum_score

BREAKING CHANGE: Configuration key changed from min_score to minimum_score
```

### Commit Best Practices

✅ **Do:**

- Write in imperative mood ("add feature" not "added feature")
- Keep subject under 72 characters
- Reference issue numbers (`fixes #123`)
- Explain **why**, not just **what**

❌ **Don't:**

- Commit unrelated changes together
- Use vague messages ("fix stuff", "WIP")
- Commit commented-out code

---

## 🔀 Pull Request Process

### Before Submitting

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

1. **Automated checks** run (CI/CD)
2. **Maintainer review** (usually within 48h)
3. **Discussion and iteration**
4. **Approval and merge**

**What reviewers look for:**

- Code quality and style
- Test coverage
- Documentation
- Performance implications
- Breaking changes

---

## 🚀 Release Process

### Versioning

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (1.0.0): Breaking changes
- **MINOR** (0.1.0): New features (backward compatible)
- **PATCH** (0.0.1): Bug fixes

### Release Checklist

1. **Update version** in `pubspec.yaml`
2. **Update CHANGELOG.md**
3. **Create release branch**

   ```bash
   git checkout -b release/v1.2.0
   ```

4. **Run full test suite**
5. **Build and test locally**
6. **Create PR to main**
7. **After merge, tag release**

   ```bash
   git tag v1.2.0
   git push origin v1.2.0
   ```

8. **Publish to pub.dev**

   ```bash
   dart pub publish
   ```

9. **Create GitHub release** with notes

---

## 🎓 Learning Resources

### New to Dart?

- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)

### Testing in Dart

- [Testing Guide](https://dart.dev/guides/testing)
- [Mocktail Package](https://pub.dev/packages/mocktail)

### CLI Development

- [args package](https://pub.dev/packages/args)
- [mason_logger](https://pub.dev/packages/mason_logger)

---

## 💬 Getting Help

- **Questions:** [GitHub Discussions](https://github.com/meragix/cura/discussions)
- **Chat:** [Discord Server](https://discord.gg/cura)
- **Issues:** [Issue Tracker](https://github.com/meragix/cura/issues)

---

## 🙏 Recognition

Contributors are recognized in:

- `CONTRIBUTORS.md`
- Release notes
- Project README

Thank you for contributing to Cura! 🎉
