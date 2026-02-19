# Cura Examples

This directory contains examples demonstrating various use cases of Cura.

## 📁 Directory Structure

- **basic_usage/** - Simple CLI usage examples
- **ci_cd/** - CI/CD integration examples
- **programmatic/** - Using Cura as a library
- **advanced/** - Advanced features and customization
- **test_projects/** - Sample projects for testing

## 🚀 Quick Start

### 1. Basic Scan

```bash
cd test_projects/flutter_app
cura check
```

### 2. CI/CD Integration

```bash
# Copy workflow to your project
cp ci_cd/github_actions.yaml .github/workflows/cura.yml
```

### 3. Programmatic Usage

```bash
# Run the example
cd programmatic
dart run use_as_library.dart
```

## 📚 Examples Index

### Basic Usage

- [simple_check.dart](basic_usage/simple_check.dart) - Check a project
- [view_package.dart](basic_usage/view_package.dart) - View package details
- [custom_config.dart](basic_usage/custom_config.dart) - Custom configuration

### CI/CD

- [github_actions.yaml](ci_cd/github_actions.yaml) - GitHub Actions workflow
- [gitlab_ci.yaml](ci_cd/gitlab_ci.yaml) - GitLab CI pipeline
- [check_health.dart](ci_cd/check_health.dart) - Health check script

### Programmatic

- [use_as_library.dart](programmatic/use_as_library.dart) - Library usage
- [custom_scorer.dart](programmatic/custom_scorer.dart) - Custom scoring
- [batch_analysis.dart](programmatic/batch_analysis.dart) - Batch processing

### Advanced

- [filter_by_score.dart](advanced/filter_by_score.dart) - Filter packages
- [generate_report.dart](advanced/generate_report.dart) - HTML reports
- [migrate_suggestions.dart](advanced/migrate_suggestions.dart) - Auto-migrate

## 🧪 Running Examples

All examples are self-contained and can be run directly:

```bash
# Install Cura globally
dart pub global activate cura

# Run any example
dart run examples/basic_usage/simple_scan.dart
```

## 💡 Need Help?

- [Documentation](../docs/)
- [GitHub Issues](https://github.com/meragix/cura/issues)
- [Discussions](https://github.com/orgs/meragix/discussions)
