import 'package:cura/src/domain/entities/package_audit_result.dart';
import 'package:cura/src/presentation/cli/loggers/console_logger.dart';
import 'package:cura/src/presentation/cli/renderers/table_renderer.dart';
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
  final TableRenderer _tableRenderer;
  final bool _showSuggestions;

  /// Accumulated audit results; populated during the streaming phase and
  /// consumed when [showSummary] is called.
  final List<PackageAuditResult> _results = [];

  /// Number of packages whose data was served from the local SQLite cache.
  int _cacheHits = 0;

  /// Number of packages whose data required a live API round-trip.
  int _apiCalls = 0;

  /// Creates a [CheckPresenter].
  ///
  /// - [logger] is the active output logger (normal, verbose, quiet, or JSON).
  /// - [showSuggestions] controls whether alternative package suggestions are
  ///   included in the critical-issues section of the summary.
  CheckPresenter({
    required ConsoleLogger logger,
    bool showSuggestions = true,
  })  : _logger = logger,
        _tableRenderer = TableRenderer(),
        _showSuggestions = showSuggestions;

  // --------------------------------------------------------------------------
  // Stage 1: Header
  // --------------------------------------------------------------------------

  /// Renders the audit header with the total number of packages to audit.
  void showHeader({required int total}) {
    _logger.spacer();
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
      _apiCalls++;
    }
  }

  /// Surfaces a fetch or processing [error] immediately, cancelling the
  /// progress animation so the error message is readable.
  void showPackageError(dynamic error, Progress progress) {
    progress.cancel();
    _logger.error(error.toString());
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
  }) {
    _logger.spacer();

    // ------------------------------------------------------------------
    // Results table
    // ------------------------------------------------------------------

    final tableStr = _tableRenderer.renderAuditTable(_results);
    _logger.info(tableStr);

    final legend =
        '${styleItalic.wrap('Legend')}: ${yellow.wrap('⭐ Stable package')}  '
        '${yellow.wrap('! Needs review')}  '
        '${red.wrap('✗ Critical')}';
    _logger.info(legend);
    _logger.muted('Legend: ⭐ Stable package  ⚠️  Needs review  ❌ Critical');

    // ------------------------------------------------------------------
    // Separator
    // ------------------------------------------------------------------

    _logger.info('━' * 60);

    // ------------------------------------------------------------------
    // Summary stats
    // ------------------------------------------------------------------

    final healthy = _results.where((r) => r.score.total >= 70).length;
    final warning = _results
        .where((r) => r.score.total >= 50 && r.score.total < 70)
        .length;
    final critical = _results.where((r) => r.score.total < 50).length;

    final avgScore = _results.isEmpty
        ? 0
        : _results.map((r) => r.score.total).reduce((a, b) => a + b) ~/
            _results.length;

    _logger.info('');
    _logger.info(styleBold.wrap('SUMMARY')!);

    if (healthy > 0) {
      _logger.info(
          '  ${green.wrap("✓ Healthy:")}   $healthy packages (${(healthy / total * 100).round()}%)');
    }
    if (warning > 0) {
      _logger.info(
          '  ${yellow.wrap("! Warning:")}  $warning packages (${(warning / total * 100).round()}%)');
    }
    if (critical > 0) {
      _logger.info(
          '  ${red.wrap("✗ Critical:")}  $critical packages (${(critical / total * 100).round()}%)');
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
            '   ${red.wrap('✗')} ${styleBold.wrap(result.name)} (score: ${result.score.total})');

        for (final issue in result.issues) {
          _logger.warn('     └─ ${issue.message}');
        }

        if (result.suggestions.isNotEmpty && _showSuggestions) {
          _logger.info('     └─ Suggestion: ${result.suggestions.first}');
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
          '($_cacheHits cached, $_apiCalls API calls)')!,
    );

    // ------------------------------------------------------------------
    // Usage tip
    // ------------------------------------------------------------------

    _logger.spacer();
    _logger.info("💡 Run 'cura view <package>' for detailed analysis");
    _logger.spacer();
  }

  /// Emits a machine-readable JSON representation of [results].
  ///
  /// TODO(#43): implement full JSON serialization using `package:json_serializable`.
  void showJsonOutput(List<dynamic> results) {
    _logger.info('[JSON OUTPUT]');
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
