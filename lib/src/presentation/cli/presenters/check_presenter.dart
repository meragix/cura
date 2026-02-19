import 'package:cura/src/domain/entities/package_audit_result.dart';
import 'package:cura/src/presentation/cli/loggers/console_logger.dart';
import 'package:cura/src/presentation/cli/renderers/table_renderer.dart';
import 'package:mason_logger/mason_logger.dart';

class CheckPresenter {
  final ConsoleLogger _logger;
  final TableRenderer _tableRenderer;
  final bool _showSuggestions;

  // Track for summary
  final List<PackageAuditResult> _results = [];
  int _apiCalls = 0;
  int _cacheHits = 0;

  CheckPresenter({
    required ConsoleLogger logger,
    bool showSuggestions = true,
  })  : _logger = logger,
        _tableRenderer = TableRenderer(),
        _showSuggestions = showSuggestions;

  /// Show header
  void showHeader({required int total}) {
    _logger.spacer();
    _logger.info('📦 Scanning pubspec.yaml...');
    _logger.info('Found $total auditable dependencies');
    _logger.spacer();
  }

  // Show progress
  Progress showProgess() {
    final progress = _logger.progress('Stating');
    return progress;
  }

  /// Update progress (with animated bar)
  void updateProgress({
    required int current,
    required int total,
    required Progress progress,
  }) {
    // Update the progress bar
    final filled = (current / total * 20).round();
    final bar = '█' * filled + '░' * (20 - filled);

    progress.update('Analyzing... [$bar] $current/$total');
  }

  // Stop progress
  void stopProgess({
    required int current,
    required int total,
    required Progress progress,
  }) {
    progress.complete('Analyzing... [${'█' * 20}] $total/$total');
  }

  /// Collect result (don't print yet, wait for table)
  void collectPackageResult(PackageAuditResult audit) {
    _results.add(audit);

    // Track cache vs API
    if (audit.fromCache) {
      _cacheHits++;
    } else {
      _apiCalls++;
    }
  }

  /// Show error (immediately)
  void showPackageError(dynamic error, Progress progress) {
    progress.cancel();
    _logger.error(error.toString());
  }

  /// Show complete summary with table
  void showSummary({
    required int total,
    required int failures,
    required Stopwatch stopwatch,
  }) {
    _logger.spacer();

    // ========================================================================
    // MAIN TABLE
    // ========================================================================

    final tableStr = _tableRenderer.renderAuditTable(_results);
    _logger.info(tableStr);

    // Legend
    final legend =
        '${styleItalic.wrap('Legend')}: ${yellow.wrap('⭐ Stable package')}  '
        '${yellow.wrap('! Needs review')}  '
        '${red.wrap('✗ Critical')}';
    _logger.info(legend);
    _logger.muted('Legend: ⭐ Stable package  ⚠️  Needs review  ❌ Critical');

    // ========================================================================
    // SEPARATOR
    // ========================================================================

    _logger.info('━' * 60);

    // ========================================================================
    // SUMMARY STATS
    // ========================================================================

    final healthy = _results.where((r) => r.score.total >= 70).length;
    final warning = _results
        .where(
          (r) => r.score.total >= 50 && r.score.total < 70,
        )
        .length;
    final critical = _results.where((r) => r.score.total < 50).length;

    final avgScore = _results.isEmpty
        ? 0
        : _results.map((r) => r.score.total).reduce((a, b) => a + b) ~/
            _results.length;

    _logger.info('');
    _logger.info(styleBold.wrap('SUMMARY')!);

    // Colored stats
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

    // Overall health
    final healthEmoji = avgScore >= 70
        ? '✅'
        : avgScore >= 50
            ? '⚠️'
            : '❌';
    _logger.info('  Overall health: $avgScore/100 $healthEmoji');

    // ========================================================================
    // CRITICAL ISSUES
    // ========================================================================

    final criticalResults = _results.where((r) => r.score.total < 50).toList();

    if (criticalResults.isNotEmpty) {
      _logger.spacer();
      _logger.error('CRITICAL ISSUES (require action):');

      for (final result in criticalResults) {
        _logger.error(
            '   ${red.wrap('✗')} ${styleBold.wrap(result.name)} (score: ${result.score.total})');
        // _logger.error('  ❌ ${result.name} (score: ${result.score.total})');

        // Show issues
        for (final issue in result.issues) {
          _logger.warn('     └─ ${issue.message}');
        }

        // Show suggestion
        if (result.suggestions.isNotEmpty && _showSuggestions) {
          _logger.info('     └─ Suggestion: ${result.suggestions.first}');
        }
      }
    }

    // ========================================================================
    // PERFORMANCE STATS
    // ========================================================================

    _logger.spacer();
    _logger.spacer();
    final elapsed = _getElapsedSeconds(stopwatch);
    _logger.info(
      darkGray.wrap('⏱️  Total time: ${elapsed}s '
          '(${_cacheHits} cached, ${_apiCalls} API calls)')!,
    );

    // ========================================================================
    // TIPS
    // ========================================================================

    _logger.spacer();
    _logger.info("💡 Run 'cura view <package>' for detailed analysis");
    _logger.spacer();
  }

  /// Show JSON output
  void showJsonOutput(List<dynamic> results) {
    // todo: Implement JSON serialization
    _logger.info('[JSON OUTPUT]');
  }

  /// Show error
  void showError(String message) {
    _logger.error(message);
  }

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  /// Get elapsed time in seconds
  String _getElapsedSeconds(Stopwatch stopwatch) {
    return (stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1);
  }

  // String _getStatusIcon(AuditStatus status) {
  //   return switch (status) {
  //     AuditStatus.excellent => '✓',
  //     AuditStatus.good => '✓',
  //     AuditStatus.warning => '⚠',
  //     AuditStatus.critical => '✗',
  //     AuditStatus.discontinued => '⛔',
  //   };
  // }
}

/// Presenter : Check command output (CI/CD friendly)
// class CheckPresenter {
//   final ConsoleLogger _logger;
//   final bool _quiet;

//   CheckPresenter({
//     required ConsoleLogger logger,
//     bool quiet = false,
//   })  : _logger = logger,
//         _quiet = quiet;

//   void showHeader() {
//     if (_quiet) return;
//     _logger.info('');
//     _logger.info('🔍 Health Check');
//     _logger.info('');
//   }

//   void showReport(dynamic report) {
//     if (_quiet) {
//       // Minimal output pour CI
//       if (report.hasFailed) {
//         _logger.error('✗ Health check failed');
//       } else {
//         _logger.success('✓ Health check passed');
//       }
//       return;
//     }

//     // Full report
//     _logger.info('Results:');
//     _logger.info('  Total packages: ${report.totalPackages}');
//     _logger.info('  Average score: ${report.averageScore}/100');
//     _logger.info('  Below threshold: ${report.belowThreshold}');

//     if (report.vulnerablePackages > 0) {
//       _logger.warn('  Vulnerable: ${report.vulnerablePackages}');
//     }

//     if (report.discontinuedPackages > 0) {
//       _logger.warn('  Discontinued: ${report.discontinuedPackages}');
//     }

//     _logger.info('');

//     if (report.hasFailed) {
//       _logger.error('✗ Health check failed');
//     } else {
//       _logger.success('✓ Health check passed');
//     }
//   }

//   void showJsonOutput(dynamic report) {
//     // TODO: Implement JSON serialization
//     _logger.info('[JSON OUTPUT]');
//   }

//   void showError(String message) {
//     _logger.error(message);
//   }
// }
