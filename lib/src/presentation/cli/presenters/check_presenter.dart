import 'package:cura/src/domain/entities/package_audit_result.dart';
import 'package:cura/src/domain/value_objects/errors.dart';
import 'package:cura/src/presentation/cli/formatters/score_formatter.dart';
import 'package:cura/src/presentation/cli/loggers/console_logger.dart';

/// Presenter : Formatage de l'output du scan
class CheckPresenter {
  final ConsoleLogger _logger;
  final bool _showSuggestions;

  CheckPresenter({
    required ConsoleLogger logger,
    bool showSuggestions = true,
  })  : _logger = logger,
        _showSuggestions = showSuggestions;

  void showHeader({required int total}) {
    _logger.info('');
    _logger.info('🔍 Scanning $total packages...');
    _logger.info('');
  }

  void updateProgress({required int current, required int total}) {
    final percentage = (current / total * 100).round();
    final bar = _buildProgressBar(percentage);

    // Clear line and print progress
    _logger.clearLine();
    _logger.write('$bar $percentage% ($current/$total)');
  }

  void showPackageResult(PackageAuditResult audit) {
    final icon = _getStatusIcon(audit.status);
    final scoreStr = ScoreFormatter.format(audit.score);

    _logger.info('$icon ${audit.name} ${audit.version.padRight(12)} $scoreStr');

    // Show issues if any
    if (audit.issues.isNotEmpty) {
      for (final issue in audit.issues) {
        _logger.warn('  └─ ${issue.message}');
      }
    }
  }

  void showPackageError(PackageProviderError error) {
    // final message = error.when(
    //   notFound: (name) => '✗ $name - Package not found',
    //   network: (msg) => '✗ Network error: $msg',
    //   rateLimit: (retryAfter) => '⚠ Rate limited (retry in ${retryAfter.inSeconds}s)',
    //   timeout: (name) => '✗ $name - Timeout',
    // );

    // _logger.error(message);
  }

  void showSummary({
    required int total,
    required int failures,
  }) {
    _logger.info('');
    _logger.info('─' * 50);
    _logger.info('');
    _logger.info('Summary:');
    _logger.info('  Total packages: $total');
    _logger.info('  Successful: ${total - failures}');
    if (failures > 0) {
      _logger.error('  Failed: $failures');
    }
    _logger.info('');
  }

  void showJsonOutput(List<dynamic> results) {
    // todo: Implement JSON serialization
    _logger.info('[JSON OUTPUT NOT YET IMPLEMENTED]');
  }

  void showError(String message) {
    _logger.error('Error: $message');
  }

  String _buildProgressBar(int percentage) {
    const barLength = 20;
    final filled = (barLength * percentage / 100).round();
    final empty = barLength - filled;

    return '[' + ('█' * filled) + ('░' * empty) + ']';
  }

  String _getStatusIcon(AuditStatus status) {
    return switch (status) {
      AuditStatus.excellent => '✓',
      AuditStatus.good => '✓',
      AuditStatus.warning => '⚠',
      AuditStatus.critical => '✗',
      AuditStatus.discontinued => '⛔',
    };
  }
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