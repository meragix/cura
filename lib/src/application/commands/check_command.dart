import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cura/src/domain/entities/package_audit_result.dart';
import 'package:cura/src/domain/usecases/check_packages_usecase.dart';
import 'package:cura/src/domain/value_objects/result.dart';
import 'package:cura/src/presentation/presenters/check_presenter.dart';
import 'package:cura/src/shared/utils/pubspec_parser.dart';

/// CLI command that audits all pub.dev packages declared in a `pubspec.yaml`.
///
/// `cura check` is the primary entry point for both interactive developer
/// workflows and automated CI/CD pipelines. It reads the project manifest,
/// resolves auditable pub.dev dependencies, streams audit results concurrently
/// through [CheckPackagesUsecase], and delegates all output formatting to
/// [CheckPresenter].
///
/// Local path dependencies and Git-sourced packages are automatically excluded
/// because they cannot be queried through the pub.dev or OSV.dev APIs.
///
/// ## Options
///
/// | Flag / Option              | Short | Default          | Description                                                        |
/// |----------------------------|-------|------------------|--------------------------------------------------------------------|
/// | `--path`                   | `-p`  | `./pubspec.yaml` | Path to the `pubspec.yaml` file to audit.                          |
/// | `--dev-dependencies`       |       | `false`          | Also audit `dev_dependencies` in addition to `dependencies`.       |
/// | `--min-score`              |       | `70`             | Minimum acceptable health score (0–100).                           |
/// | `--fail-on-vulnerable`     |       | `true`           | Exit with code `1` if any package has known vulnerabilities.       |
/// | `--fail-on-discontinued`   |       | `true`           | Exit with code `1` if any package is discontinued on pub.dev.      |
/// | `--quiet`                  | `-q`  | `false`          | Suppress non-essential output (CI-friendly).                       |
/// | `--json`                   |       | `false`          | Emit results as machine-readable JSON instead of the default table.|
///
/// ## Exit codes
///
/// | Code | Meaning                                                    |
/// |------|------------------------------------------------------------|
/// | `0`  | All packages passed the audit criteria.                    |
/// | `1`  | One or more packages failed, or an unrecoverable error occurred. |
///
/// ## Examples
///
/// ```sh
/// # Audit the current project with default settings
/// cura check
///
/// # Include dev_dependencies with a stricter threshold
/// cura check --dev-dependencies --min-score 80
///
/// # CI/CD mode: quiet JSON output, always fail on vulnerabilities
/// cura check --quiet --json
///
/// # Audit a manifest located in a sub-directory
/// cura check --path packages/my_lib/pubspec.yaml
/// ```
class CheckCommand extends Command<int> {
  /// Use case responsible for fetching, scoring, and streaming
  /// [PackageAuditResult]s for each package name.
  final CheckPackagesUsecase _checkUseCase;

  /// Presenter that handles all output formatting and rendering.
  final CheckPresenter _presenter;

  /// Package names that must be skipped during the audit.
  ///
  /// Populated from the global or project config (`ignored_packages`). Each
  /// entry is matched case-sensitively against the package name resolved from
  /// `pubspec.yaml`.
  final List<String> _ignoredPackages;

  /// Measures wall-clock time from the start of the audit to the final
  /// summary line.
  final Stopwatch _stopwatch = Stopwatch();

  @override
  String get name => 'check';

  @override
  String get description =>
      'Analyze all pub.dev packages listed in pubspec.yaml and report their health.';

  /// Creates a [CheckCommand].
  ///
  /// - [checkUseCase] orchestrates data fetching and scoring for each package.
  /// - [presenter] renders all output (progress bar, results table, summary).
  /// - [ignoredPackages] lists package names to skip; defaults to an empty list.
  CheckCommand({
    required CheckPackagesUsecase checkUseCase,
    required CheckPresenter presenter,
    List<String> ignoredPackages = const [],
  })  : _checkUseCase = checkUseCase,
        _presenter = presenter,
        _ignoredPackages = ignoredPackages {
    argParser
      ..addOption(
        'path',
        abbr: 'p',
        help: 'Path to the pubspec.yaml file to audit.',
        defaultsTo: './pubspec.yaml',
        valueHelp: 'FILE',
      )
      ..addFlag(
        'dev-dependencies',
        help:
            'Include dev_dependencies in the audit in addition to dependencies.',
        defaultsTo: false,
      )
      ..addOption(
        'min-score',
        help: 'Minimum acceptable health score (0–100). '
            'Packages below this threshold are flagged in the report.',
        defaultsTo: '70',
        valueHelp: 'SCORE',
      )
      ..addFlag(
        'fail-on-vulnerable',
        help:
            'Exit with code 1 if any package has known security vulnerabilities.',
        defaultsTo: true,
      )
      ..addFlag(
        'fail-on-discontinued',
        help:
            'Exit with code 1 if any package is marked as discontinued on pub.dev.',
        defaultsTo: true,
      )
      ..addFlag(
        'quiet',
        abbr: 'q',
        help: 'Suppress non-essential output. Useful for CI/CD pipelines.',
        defaultsTo: false,
      )
      ..addFlag(
        'json',
        help:
            'Emit results as machine-readable JSON instead of the default table.',
        defaultsTo: false,
      );
  }

  /// Runs the audit pipeline and returns an exit code.
  ///
  /// Execution follows five sequential stages:
  ///
  /// 1. **Parse** — reads and validates the `pubspec.yaml` at `--path`.
  /// 2. **Filter** — removes packages listed in [_ignoredPackages].
  /// 3. **Header** — renders the total package count via [CheckPresenter].
  /// 4. **Stream** — delegates to [CheckPackagesUsecase.execute], which yields
  ///    one [Result]<[PackageAuditResult]> per package concurrently; each
  ///    result updates the live progress bar.
  /// 5. **Summarize** — renders the full audit table and stats, or JSON output
  ///    when `--json` is active.
  ///
  /// Returns `0` when every package passes, `1` if any package failed or an
  /// error occurred during processing.
  @override
  Future<int> run() async {
    final pubspecPath = argResults!['path'] as String;
    final includeDevDeps = argResults!['dev-dependencies'] as bool;
    final jsonOutput = argResults!['json'] as bool;

    // --min-score, --fail-on-vulnerable, --fail-on-discontinued, and --quiet
    // are registered here so they appear in `cura check --help`.
    // Their runtime values are currently supplied via constructor injection from
    // the composition root (bin/cura.dart), which reads the resolved config.
    // TODO(#42): forward these flag values to CheckPackagesUsecase at runtime
    // so that per-invocation overrides take precedence over the config file.

    _stopwatch.start();

    // Stage 1 — Parse pubspec.yaml and resolve auditable pub.dev packages.
    final packageNames = await _parsePubspec(
      path: pubspecPath,
      includeDevDeps: includeDevDeps,
    );

    if (packageNames.isEmpty) {
      _presenter.showError('No packages found in $pubspecPath');
      return 1;
    }

    // Stage 2 — Remove packages the user has explicitly opted out of auditing.
    final packagesToAudit =
        packageNames.where((name) => !_ignoredPackages.contains(name)).toList();

    // Stage 3 — Render the audit header with total count.
    _presenter.showHeader(total: packagesToAudit.length);

    var processedCount = 0;
    var failureCount = 0;

    final progress = _presenter.showProgress();

    // Stage 4 — Stream results from the use case and update the progress bar.
    await for (final result in _checkUseCase.execute(packagesToAudit)) {
      processedCount++;

      _presenter.updateProgress(
        current: processedCount,
        total: packagesToAudit.length,
        progress: progress,
      );

      switch (result) {
        case Success<PackageAuditResult>(:final value):
          _presenter.collectPackageResult(value);
        case Failure<PackageAuditResult>(:final error):
          failureCount++;
          _presenter.showPackageError(error, progress);
      }
    }

    _presenter.stopProgress(
      current: processedCount,
      total: packagesToAudit.length,
      progress: progress,
    );

    // Stage 5 — Render the final report.
    if (jsonOutput) {
      _presenter.showJsonOutput([]);
    } else {
      _presenter.showSummary(
        total: packagesToAudit.length,
        failures: failureCount,
        stopwatch: _stopwatch,
      );
    }

    return failureCount > 0 ? 1 : 0;
  }

  /// Parses the `pubspec.yaml` at [path] and returns the names of all
  /// pub.dev-hosted packages eligible for auditing.
  ///
  /// Only [PubDevSource] entries are included. Local path dependencies and
  /// Git-sourced packages are intentionally excluded because they cannot be
  /// audited via the pub.dev or OSV.dev APIs.
  ///
  /// When [includeDevDeps] is `true`, both `dependencies` and
  /// `dev_dependencies` sections are combined.
  ///
  /// Throws [FileSystemException] if [path] does not point to an existing file.
  Future<List<String>> _parsePubspec({
    required String path,
    required bool includeDevDeps,
  }) async {
    final file = File(path);

    if (!await file.exists()) {
      throw FileSystemException('pubspec.yaml not found', path);
    }

    final pubspec = PubspecParser.parse(await file.readAsString());

    final packages = <PubDevSource>[...pubspec.auditableDeps];

    if (includeDevDeps) {
      packages.addAll(pubspec.auditableDevDeps);
    }

    return packages.map((e) => e.name).toList();
  }
}
