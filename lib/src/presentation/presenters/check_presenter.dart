import 'dart:convert';

import 'package:cura/src/domain/entities/package_audit_result.dart';
import 'package:cura/src/presentation/formatters/error_formatter.dart';
import 'package:cura/src/presentation/loggers/console_logger.dart';
import 'package:cura/src/presentation/renderers/table_renderer.dart';

import 'package:mason_logger/mason_logger.dart';

/// Presentation layer orchestrator for the `cura check` command.
///
/// [CheckPresenter] is responsible for translating domain objects produced by
/// [CheckPackagesUsecase] into formatted CLI output. It is intentionally free
/// of business logic — all scoring and issue detection happens in the domain
/// layer before results reach this class.
///
/// The rendering lifecycle mirrors the five stages of [CheckCommand.run]:
///
/// 1. [showHeader] — prints the package count banner.
/// 2. [showProgress] / [updateProgress] / [stopProgress] — manages the
///    animated progress bar while packages are being fetched concurrently.
/// 3. [collectPackageResult] — accumulates successful audit results and tracks
///    cache-vs-API statistics.
/// 4. [showPackageError] — surfaces fetch errors immediately, inline.
/// 5. [showSummary] / [showJsonOutput] — renders the final report.
class CheckPresenter {
  final ConsoleLogger _logger;
  final ErrorFormatter _errorFormatter;
  final TableRenderer _tableRenderer;

  /// Accumulated audit results; populated during the streaming phase and
  /// consumed when [showSummary] is called.
  final List<PackageAuditResult> _results = [];

  /// Number of packages whose data was served from the local JSON file cache.
  int _cacheHits = 0;

  /// Total number of HTTP requests issued to external APIs across all
  /// non-cached packages. Accumulated from [PackageAuditResult.requestCount].
  int _apiCalls = 0;

  /// Creates a [CheckPresenter].
  ///
  /// - [logger] is the active output logger (normal, verbose, quiet, or JSON).
  ///   included in the critical-issues section of the summary.
  CheckPresenter({
    required ConsoleLogger logger,
    bool showSuggestions = true,
  })  : _logger = logger,
        _errorFormatter = ErrorFormatter(logger),
        _tableRenderer = TableRenderer();

  // --------------------------------------------------------------------------
  // Stage 1: Header
  // --------------------------------------------------------------------------

  /// Renders the audit header with the total number of packages to audit.
  void showHeader({required int total}) {
    _logger.info('📦 Scanning pubspec.yaml...');
    _logger.info('Found $total auditable dependencies');
    _logger.spacer();
  }

  // --------------------------------------------------------------------------
  // Stage 2: Progress bar
  // --------------------------------------------------------------------------

  /// Starts and returns an animated [Progress] indicator.
  ///
  /// The caller is responsible for passing this handle to [updateProgress] and
  /// [stopProgress] throughout the streaming phase.
  Progress showProgress() {
    return _logger.progress('Starting');
  }

  /// Updates the animated progress bar with the current position.
  ///
  /// [current] is the number of packages processed so far; [total] is the
  /// total number of packages scheduled for auditing.
  void updateProgress({
    required int current,
    required int total,
    required Progress progress,
  }) {
    final filled = (current / total * 20).round();
    final bar = '█' * filled + '░' * (20 - filled);
    progress.update('Analyzing... [$bar] $current/$total');
  }

  /// Completes the progress bar at 100 % and stops the animation.
  void stopProgress({
    required int current,
    required int total,
    required Progress progress,
  }) {
    progress.complete('Analyzing... [${'█' * 20}] $total/$total');
  }

  // --------------------------------------------------------------------------
  // Stage 3 & 4: Result collection and inline errors
  // --------------------------------------------------------------------------

  /// Collects a successful [PackageAuditResult] for inclusion in the final
  /// summary table.
  ///
  /// Also increments the cache-hit or API-call counter depending on whether
  /// [audit] was served from the local cache.
  void collectPackageResult(PackageAuditResult audit) {
    _results.add(audit);

    if (audit.fromCache) {
      _cacheHits++;
    } else {
      _apiCalls += audit.requestCount;
    }
  }

  /// Surfaces a fetch or processing [error] immediately, cancelling the
  /// progress animation so the error message is readable.
  void showPackageError(dynamic error, Progress progress) {
    progress.cancel();
    _errorFormatter.format(error);
  }

  // --------------------------------------------------------------------------
  // Stage 5: Summary
  // --------------------------------------------------------------------------

  /// Renders the complete audit report: results table, legend, summary stats,
  /// critical-issues list, performance metrics, and a usage tip.
  ///
  /// [total] is the number of packages scheduled; [failures] is the count of
  /// packages that could not be fetched or processed. [stopwatch] provides the
  /// total elapsed time.
  void showSummary({
    required int total,
    required int failures,
    required Stopwatch stopwatch,
    required bool passed,
  }) {
    // Quiet mode: minimal PASS/FAIL output only.
    if (_logger.isQuiet) {
      _logger.write(passed ? 'PASS\n' : 'FAIL\n');
      if (!passed) {
        final criticalResults =
            _results.where((r) => r.score.total < 50).toList();
        if (criticalResults.isNotEmpty) {
          _logger.write('\nCRITICAL ISSUES (require action):\n');
          for (final r in criticalResults) {
            _logger.write('  ✗ ${r.name} (score: ${r.score.total})\n');
          }
        }
      }
      return;
    }

    _logger.spacer();

    // ------------------------------------------------------------------
    // Results table
    // ------------------------------------------------------------------

    final tableStr = _tableRenderer.renderAuditTable(_results);
    _logger.info(tableStr);

    final legend = '${styleItalic.wrap('Legend')}: '
        '${yellow.wrap('! Needs review')}  '
        '${red.wrap('✗ Critical')}';
    _logger.info(legend);

    // ------------------------------------------------------------------
    // Separator
    // ------------------------------------------------------------------

    _logger.info('━' * 60);

    // ------------------------------------------------------------------
    // Summary stats
    // ------------------------------------------------------------------

    final healthy = _results.where((r) => r.score.total >= 70).length;
    final warning =
        _results.where((r) => r.score.total >= 50 && r.score.total < 70).length;
    final critical = _results.where((r) => r.score.total < 50).length;

    final avgScore = _results.isEmpty
        ? 0
        : _results.map((r) => r.score.total).reduce((a, b) => a + b) ~/
            _results.length;

    _logger.info('');
    _logger.info(styleBold.wrap('SUMMARY')!);

    if (healthy > 0) {
      _logger.info(
          '  ${green.wrap("Healthy:")}  $healthy/$total (${(healthy / total * 100).round()}%)');
    }
    if (warning > 0) {
      _logger.info('  ${yellow.wrap("Warning:")}  $warning');
    }
    if (critical > 0) {
      _logger.info('  ${red.wrap("Critical:")} $critical');
    }

    _logger.info('');

    final healthEmoji = avgScore >= 70
        ? '✅'
        : avgScore >= 50
            ? '⚠️'
            : '❌';
    _logger.info('  Overall health: $avgScore/100 $healthEmoji');

    // ------------------------------------------------------------------
    // Critical issues
    // ------------------------------------------------------------------

    final criticalResults = _results.where((r) => r.score.total < 50).toList();

    if (criticalResults.isNotEmpty) {
      _logger.spacer();
      _logger.error('CRITICAL ISSUES (require action):');

      for (final result in criticalResults) {
        _logger.error(
            '  ${red.wrap('✗')} ${red.wrap(styleBold.wrap(result.name))} (score: ${result.score.total})');

        for (final issue in result.issues) {
          _logger.info('    └─ ${issue.message}');
        }

        if (result.recommendations.isNotEmpty) {
          _logger.info(
              '    └─ Recommendation: ${result.recommendations.first.message}');
        }
      }
    }

    // ------------------------------------------------------------------
    // Performance stats
    // ------------------------------------------------------------------

    _logger.spacer();
    _logger.spacer();
    final elapsed = _getElapsedSeconds(stopwatch);
    _logger.info(
      darkGray.wrap('⏱️  Total time: ${elapsed}s '
          '($_cacheHits from cache, $_apiCalls HTTP requests)')!,
    );

    // ------------------------------------------------------------------
    // Usage tip
    // ------------------------------------------------------------------

    _logger.spacer();
    _logger.info("💡 Run 'cura view <package>' for detailed analysis");
    _logger.spacer();
  }

  /// Emits a machine-readable JSON audit report.
  ///
  /// Schema:
  /// ```json
  /// {
  ///   "timestamp":       "<ISO-8601 UTC>",
  ///   "total_packages":  N,
  ///   "overall_health":  0-100,
  ///   "status":          "PASSED" | "WARNING" | "FAILED",
  ///   "summary":         { "healthy": X, "warning": Y, "critical": Z },
  ///   "packages":        [ { name, version, score, grade, last_update_days,
  ///                          "red_flags": [...] } ],
  ///   "critical_packages": [ { name, score } ],
  ///   "performance":     { "time_ms": N, "api_calls": N, "cache_hits": N }
  /// }
  /// ```
  ///
  /// `red_flags` is omitted from a package entry when there are none.
  /// `status` is:
  /// - `"PASSED"` — no warning or critical packages
  /// - `"WARNING"` — some warning/critical packages but overall_health ≥ 50
  /// - `"FAILED"` — overall_health < 50
  void showJsonOutput(Stopwatch stopwatch) {
    final healthy = _results.where((r) => r.score.total >= 70).length;
    final warning =
        _results.where((r) => r.score.total >= 50 && r.score.total < 70).length;
    final critical = _results.where((r) => r.score.total < 50).length;

    final overallHealth = _results.isEmpty
        ? 0
        : _results.map((r) => r.score.total).reduce((a, b) => a + b) ~/
            _results.length;

    final status = overallHealth < 50
        ? 'FAILED'
        : (critical > 0 || warning > 0)
            ? 'WARNING'
            : 'PASSED';

    final packages = _results.map((r) {
      final entry = <String, dynamic>{
        'name': r.name,
        'version': r.version,
        'score': r.score.total,
        'grade': r.score.grade.label,
        'last_update_days': r.packageInfo.daysSinceLastUpdate,
      };
      if (r.score.redFlags.isNotEmpty) {
        entry['red_flags'] = r.score.redFlags.map((f) => f.message).toList();
      }
      return entry;
    }).toList();

    final criticalPackages = _results
        .where((r) => r.score.total < 50)
        .map((r) => {'name': r.name, 'score': r.score.total})
        .toList();

    final output = {
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'total_packages': _results.length,
      'overall_health': overallHealth,
      'status': status,
      'summary': {
        'healthy': healthy,
        'warning': warning,
        'critical': critical,
      },
      'packages': packages,
      if (criticalPackages.isNotEmpty) 'critical_packages': criticalPackages,
      'performance': {
        'time_ms': stopwatch.elapsedMilliseconds,
        'api_calls': _apiCalls,
        'cache_hits': _cacheHits,
      },
    };

    // Use write() so JSON output is never suppressed by quiet mode.
    _logger.write('${const JsonEncoder.withIndent('  ').convert(output)}\n');
  }

  /// Displays a top-level error message (e.g. "no packages found").
  void showError(String message) {
    _logger.error(message);
  }

  // --------------------------------------------------------------------------
  // Private helpers
  // --------------------------------------------------------------------------

  /// Returns [stopwatch]'s elapsed time formatted as seconds with one decimal
  /// place (e.g. `"3.4"`).
  String _getElapsedSeconds(Stopwatch stopwatch) {
    return (stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1);
  }
}
