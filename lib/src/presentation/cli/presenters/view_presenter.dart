import 'package:cura/src/domain/entities/package_audit_result.dart';
import 'package:cura/src/presentation/cli/formatters/date_formatter.dart';
import 'package:cura/src/presentation/cli/formatters/score_formatter.dart';
import 'package:cura/src/presentation/cli/loggers/console_logger.dart';

/// Presenter : View command output
class ViewPresenter {
  final ConsoleLogger _logger;

  ViewPresenter({required ConsoleLogger logger}) : _logger = logger;

  void showHeader(String packageName) {
    _logger.info('');
    _logger.info('📦 Package: $packageName');
    _logger.info('─' * 50);
  }

  void showPackageDetails(PackageAuditResult audit, {bool verbose = false}) {
    final info = audit.packageInfo;

    // Basic info
    _logger.info('Version: ${info.version}');
    _logger.info('Description: ${info.description}');
    _logger.info('');

    // Score
    _logger.info('Score: ${ScoreFormatter.format(audit.score)}');
    if (verbose) {
      _showScoreBreakdown(audit.score);
    }
    _logger.info('');

    // Metrics
    _logger.info('Metrics:');
    _logger.info('  Pana Score: ${info.panaScore}/130');
    _logger.info('  Likes: ${info.likes}');
    _logger.info('  Popularity: ${info.popularity}%');
    _logger.info('  Platforms: ${info.supportedPlatforms.join(", ")}');
    _logger.info('');

    // Dates
    _logger.info('Published: ${DateFormatter.format(info.lastPublished)}');
    _logger.info('');

    // Publisher
    if (info.publisherId != null) {
      _logger.info('Publisher: ${info.publisherId}');
    }
    if (info.isFlutterFavorite) {
      _logger.success('✓ Flutter Favorite');
    }
    _logger.info('');

    // GitHub (si disponible)
    // if (audit.githubMetrics != null) {
    //   _showGitHubMetrics(audit.githubMetrics!);
    // }

    // Vulnerabilities
    if (audit.vulnerabilities.isNotEmpty) {
      _showVulnerabilities(audit.vulnerabilities);
    }

    // Issues
    if (audit.issues.isNotEmpty) {
      _showIssues(audit.issues);
    }
  }

  void _showScoreBreakdown(dynamic score) {
    _logger.info('  Vitality: ${score.vitality}/40');
    _logger.info('  Technical Health: ${score.technicalHealth}/30');
    _logger.info('  Trust: ${score.trust}/20');
    _logger.info('  Maintenance: ${score.maintenance}/10');
  }

  void _showGitHubMetrics(dynamic metrics) {
    _logger.info('GitHub:');
    _logger.info('  Stars: ${metrics.stars}');
    _logger.info('  Forks: ${metrics.forks}');
    _logger.info('  Open Issues: ${metrics.openIssues}');
    _logger.info('  Commits (90d): ${metrics.commitCountLast90Days}');
    if (metrics.lastCommitDate != null) {
      _logger.info(
          '  Last Commit: ${DateFormatter.format(metrics.lastCommitDate)}');
    }
    _logger.info('');
  }

  void _showVulnerabilities(List<dynamic> vulnerabilities) {
    _logger.warn('⚠ Vulnerabilities:');
    for (final vuln in vulnerabilities) {
      _logger.warn('  ${vuln.id}: ${vuln.summary}');
    }
    _logger.info('');
  }

  void _showIssues(List<dynamic> issues) {
    _logger.warn('Issues:');
    for (final issue in issues) {
      _logger.warn('  • ${issue.message}');
    }
    _logger.info('');
  }

  void showError(String message) {
    _logger.error('Error: $message');
  }

  void showUsage(String invocation) {
    _logger.info('');
    _logger.info('Usage: $invocation');
  }
}
