import 'package:cura/src/domain/entities/github_metrics.dart';
import 'package:cura/src/domain/entities/package_audit_result.dart';
import 'package:cura/src/domain/entities/score.dart';
import 'package:cura/src/presentation/cli/formatters/date_formatter.dart';
import 'package:cura/src/presentation/cli/formatters/number_formatter.dart';
import 'package:cura/src/presentation/cli/loggers/console_logger.dart';
import 'package:cura/src/presentation/cli/renderers/bar_renderer.dart';
import 'package:mason_logger/mason_logger.dart';

/// Presenter : View command output
class ViewPresenter {
  final ConsoleLogger _logger;
  final BarRenderer _barRenderer;

  ViewPresenter({required ConsoleLogger logger})
      : _logger = logger,
        _barRenderer = BarRenderer();

  Progress showProgressHeader(String packageName) {
    final progress = _logger.progress('Analyzing: $packageName');
    return progress;
  }

  void showPackageDetails(PackageAuditResult audit, {bool verbose = false}) {
   // _logger.spacer();

    // ========================================================================
    // HEADER (with visual separator)
    // ========================================================================

  //  _logger.info('═' * 65);
    _logger.spacer();

    _showHeader(audit);

    _logger.spacer();

    // ========================================================================
    // SCORE BREAKDOWN (Visual bars)
    // ========================================================================

    _showScoreBreakdown(audit.score);

    _logger.spacer();

    // ========================================================================
    // ISSUES (if any)
    // ========================================================================

    if (audit.issues.isNotEmpty) {
      _showIssues(audit.issues);
      _logger.spacer();
    }

    // ========================================================================
    // KEY METRICS
    // ========================================================================

    _showKeyMetrics(audit);

    _logger.spacer();

    // ========================================================================
    // GITHUB METRICS (if available)
    // ========================================================================

    if (audit.githubMetrics != null) {
      _showGitHubMetrics(audit.githubMetrics!);
      _logger.spacer();
    }

    // ========================================================================
    // VULNERABILITIES (if any)
    // ========================================================================

    if (audit.vulnerabilities.isNotEmpty) {
      _showVulnerabilities(audit.vulnerabilities);
      _logger.spacer();
    }

    // ========================================================================
    // SUGGESTIONS (if available)
    // ========================================================================

    // if (suggestions != null && suggestions.isNotEmpty) {
    //   _showSuggestions(suggestions);
    //   _logger.spacer();
    // }

    // ========================================================================
    // RECOMMENDATION
    // ========================================================================

    _showRecommendation(audit);

    _logger.spacer();
    // _logger.info('═' * 65);
    // _logger.spacer();
  }

  /// Show error
  void showError(String message) {
    _logger.spacer();
    _logger.error(message);
    _logger.spacer();
  }

  /// Show usage
  void showUsage(String invocation) {
    _logger.info('');
    _logger.info('Usage: $invocation');
  }

  // ==========================================================================
  // PRIVATE RENDERERS
  // ==========================================================================

  /// Render header
  void _showHeader(PackageAuditResult audit) {
    final statusIcon = _getStatusIcon(audit.score.total);
    final packageName = cyan.wrap(audit.name)!;
    final version = lightGray.wrap('v${audit.version}')!;

    _logger.info(' $statusIcon $packageName $version');
    _logger.spacer();

    // Score with grade
    final scoreStr = _formatScore(audit.score.total);
    final grade = _formatGrade(audit.score.grade);

    _logger.info(' ● Score: $scoreStr $grade');
  }

  /// Render score breakdown (visual bars)
  void _showScoreBreakdown(Score score) {
    final breakdown = _barRenderer.renderScoreBreakdown(score);
    _logger.info(' $breakdown');
  }

  /// Render issues
  void _showIssues(List<dynamic> issues) {
    _logger.warn('Issues Detected');

    for (final issue in issues) {
      _logger.warn('  ● ${issue.message}');
    }
  }

  /// Render key metrics
  void _showKeyMetrics(PackageAuditResult audit) {
    final info = audit.packageInfo;

    _logger.info('Key Metrics');

    // Publisher
    final publisherIcon = info.isTrustedPublisher ? '✓' : '';
    final publisherText = info.publisherId ?? 'None (unverified)';
    final publisherColored = info.isTrustedPublisher ? green.wrap(publisherText) : lightGray.wrap(publisherText);

    _logger.info('  Publisher:   $publisherColored $publisherIcon');

    // Pub Score
    final pubScoreIndicator = _barRenderer.renderPubScoreIndicator(
      info.panaScore,
    );
    _logger.info('  Pub Score:   ${info.panaScore}/${info.maxPoints} $pubScoreIndicator');

    // Popularity
    final popularityDots = _barRenderer.renderPopularityDots(
      info.popularity,
    );
    _logger.info('  Popularity:  ${info.popularity}% $popularityDots');

    // Likes
    _logger.info('  Likes:       ${info.likes}');

    // Last Update
    final updateStatus = _barRenderer.renderUpdateStatus(
      info.daysSinceLastUpdate,
    );
    final updateText = DateFormatter.format(info.lastPublished);
    _logger.info('  Last Update: $updateText $updateStatus');

    // Repository
    if (info.repositoryUrl != null) {
      final repoUrl = info.repositoryUrl!.replaceFirst('https://', '');
      _logger.info('  Repository:  ${cyan.wrap(repoUrl)}');
    } else {
      _logger.warn('  Repository:  None');
    }

    // Platforms
    if (info.supportedPlatforms.isNotEmpty) {
      final platforms = info.supportedPlatforms.join(', ');
      _logger.info('  Platforms:   $platforms');
    }

    // Flutter Favorite
    if (info.isFlutterFavorite) {
      _logger.success('  Flutter Favorite ✨', showSymbol: false);
    }
  }

  /// Render GitHub metrics
  void _showGitHubMetrics(GitHubMetrics githubMetrics) {
    _logger.info('GitHub');

    // Stars
    final starsFormatted = NumberFormatter.formatCompact(githubMetrics.stars);
    _logger.info('  Stars:       ⭐ $starsFormatted');

    // Forks
    _logger.info('  Forks:       ${NumberFormatter.formatGrouped(githubMetrics.forks)}');

    // Open Issues
    final issuesColor = githubMetrics.openIssues > 100 ? yellow : green;
    final issuesFormatted = NumberFormatter.formatGrouped(githubMetrics.openIssues);
    final issuesColored = issuesColor.wrap(issuesFormatted.toString())!;
    _logger.info('  Open Issues: $issuesColored');

    // Recent Activity
    if (githubMetrics.commitCountLast90Days > 0) {
      final commits = githubMetrics.commitCountLast90Days;
      _logger.info('  Activity:    $commits commits (90d)');
    }

    // Last Commit
    if (githubMetrics.lastCommitDate != null) {
      final lastCommit = DateFormatter.format(githubMetrics.lastCommitDate!);
      _logger.info('  Last Commit: $lastCommit');
    }
  }

  /// Render vulnerabilities
  void _showVulnerabilities(List<dynamic> vulnerabilities) {
    _logger.alert('Vulnerabilities', level: AlertLevel.error);

    for (final vuln in vulnerabilities) {
      final severity = _formatSeverity(vuln.severity);
      _logger.error('  $severity ${vuln.id}: ${vuln.summary}');

      if (vuln.fixedVersion != null) {
        _logger.info('    └─ Fixed in: ${vuln.fixedVersion}');
      }
    }
  }

  /// Render suggestions
  // void _showSuggestions(List<DynamicSuggestion> suggestions) {
  //   _logger.info('Better Alternatives');

  //   for (final suggestion in suggestions.take(3)) {
  //     final arrow = cyan.wrap('→')!;
  //     final packageName = suggestion.suggestedPackage;
  //     final score = '(${suggestion.suggestedScore}/100)';

  //     _logger.info('  $arrow $packageName $score');

  //     // Show reason (first line only)
  //     final reasonLines = suggestion.reason.split('\n');
  //     if (reasonLines.isNotEmpty) {
  //       _logger.muted('    ${reasonLines.first}');
  //     }
  //   }
  // }

  /// Render recommendation
  void _showRecommendation(PackageAuditResult audit) {
    final score = audit.score.total;

    if (score >= 80) {
      // final checkmark = green.wrap('✓')!;
      _logger.success('Recommended - High-quality, actively maintained package');
    } else if (score >= 60) {
      final warning = yellow.wrap('!')!;
      _logger.warn('$warning Use with caution - Some concerns, review before using');
    } else {
      final cross = red.wrap('✗')!;
      _logger.error('$cross Not Recommended - Appears abandoned, high risk for production use');
    }
  }

  // ==========================================================================
  // FORMATTERS
  // ==========================================================================

  String _getStatusIcon(int score) {
    if (score >= 90) return '✨';
    if (score >= 70) return '✓';
    if (score >= 50) return '⚠';
    return '✗';
  }

  String _formatScore(int score) {
    final scoreStr = '$score/100';

    if (score >= 90) return green.wrap(scoreStr)!;
    if (score >= 70) return lightGreen.wrap(scoreStr)!;
    if (score >= 50) return yellow.wrap(scoreStr)!;
    return red.wrap(scoreStr)!;
  }

  String _formatGrade(String grade) {
    final gradeText = '($grade)';

    if (grade.startsWith('A')) return green.wrap(gradeText)!;
    if (grade.startsWith('B')) return lightGreen.wrap(gradeText)!;
    if (grade.startsWith('C')) return yellow.wrap(gradeText)!;
    return red.wrap(gradeText)!;
  }

  String _formatSeverity(dynamic severity) {
    // Assuming VulnerabilitySeverity enum
    final severityStr = severity.toString().split('.').last.toUpperCase();

    return switch (severityStr) {
      'CRITICAL' => red.wrap('🔴 CRITICAL')!,
      'HIGH' => red.wrap('🟠 HIGH')!,
      'MEDIUM' => yellow.wrap('🟡 MEDIUM')!,
      'LOW' => green.wrap('🟢 LOW')!,
      _ => lightGray.wrap('⚪ UNKNOWN')!,
    };
  }
}
