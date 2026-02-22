import 'package:cura/src/domain/entities/github_metrics.dart';
import 'package:cura/src/domain/entities/package_audit_result.dart';
import 'package:cura/src/domain/entities/score.dart';
import 'package:cura/src/presentation/formatters/date_formatter.dart';
import 'package:cura/src/presentation/formatters/number_formatter.dart';
import 'package:cura/src/presentation/loggers/console_logger.dart';
import 'package:cura/src/presentation/renderers/bar_renderer.dart';
import 'package:mason_logger/mason_logger.dart';

/// Presentation layer orchestrator for the `cura view` command.
///
/// [ViewPresenter] translates a [PackageAuditResult] into a structured,
/// colour-coded terminal report. It is intentionally free of business logic —
/// all scoring and issue detection happens in the domain layer before results
/// reach this class.
///
/// The report is divided into the following sections, rendered in order:
///
/// 1. **Header** — package name, version, overall score, and letter grade.
/// 2. **Score breakdown** — visual bar chart for each scoring dimension.
/// 3. **Issues** — warnings and critical findings (rendered only when present).
/// 4. **Key metrics** — publisher, pub score, popularity, likes, last update,
///    repository, and supported platforms.
/// 5. **GitHub metrics** — stars, forks, open issues, commit activity, and
///    last commit date (rendered only when GitHub data is available).
/// 6. **Vulnerabilities** — CVE list with severity badges and fix versions
///    (rendered only when vulnerabilities are present).
/// 7. **Recommendation** — a single-line verdict based on the overall score.
class ViewPresenter {
  final ConsoleLogger _logger;
  final BarRenderer _barRenderer;

  /// Creates a [ViewPresenter].
  ///
  /// [logger] is the active output logger (normal, verbose, quiet, or JSON).
  ViewPresenter({required ConsoleLogger logger})
      : _logger = logger,
        _barRenderer = BarRenderer();

  // --------------------------------------------------------------------------
  // Public API
  // --------------------------------------------------------------------------

  /// Starts and returns an animated [Progress] indicator while the package
  /// data is being fetched.
  ///
  /// The caller is responsible for calling [Progress.complete] or
  /// [Progress.cancel] once the fetch completes or fails.
  Progress showProgressHeader(String packageName) {
    return _logger.progress('Analyzing: $packageName');
  }

  /// Renders the full health report for [audit].
  ///
  /// When [verbose] is `true`, the score breakdown section includes extended
  /// detail for each scoring dimension.
  ///
  /// Sections are rendered conditionally: issues, GitHub metrics, and
  /// vulnerabilities are only shown when the corresponding data is present.
  void showPackageDetails(PackageAuditResult audit, {bool verbose = false}) {
    _logger.spacer();

    // Section 1: Header
    _showHeader(audit);
    _logger.spacer();

    // Section 2: Score breakdown
    _showScoreBreakdown(audit.score);
    _logger.spacer();

    // Section 3: Issues (conditional)
    if (audit.issues.isNotEmpty) {
      _showIssues(audit.issues);
      _logger.spacer();
    }

    // Section 4: Key metrics
    _showKeyMetrics(audit);
    _logger.spacer();

    // Section 5: GitHub metrics (conditional)
    if (audit.githubMetrics != null) {
      _showGitHubMetrics(audit.githubMetrics!);
      _logger.spacer();
    }

    // Section 6: Vulnerabilities (conditional)
    if (audit.vulnerabilities.isNotEmpty) {
      _showVulnerabilities(audit.vulnerabilities);
      _logger.spacer();
    }

    // Section 7: Recommendation
    _showRecommendation(audit);
    _logger.spacer();
  }

  /// Displays a top-level error message (e.g. package not found).
  void showError(String message) {
    _logger.spacer();
    _logger.error(message);
    _logger.spacer();
  }

  /// Displays the correct command invocation when a required argument is
  /// missing.
  void showUsage(String invocation) {
    _logger.info('');
    _logger.info('Usage: $invocation');
  }

  // --------------------------------------------------------------------------
  // Private section renderers
  // --------------------------------------------------------------------------

  /// Renders the package name, version, overall score, and letter grade.
  void _showHeader(PackageAuditResult audit) {
    final statusIcon = _getStatusIcon(audit.score.total);
    final packageName = cyan.wrap(audit.name)!;
    final version = lightGray.wrap('v${audit.version}')!;

    _logger.info(' $statusIcon $packageName $version');
    _logger.spacer();

    final scoreStr = _formatScore(audit.score.total);
    final grade = _formatGrade(audit.score.grade);

    _logger.info(' ● Score: $scoreStr $grade');
  }

  /// Renders a visual bar chart for each dimension of [score].
  void _showScoreBreakdown(Score score) {
    final breakdown = _barRenderer.renderScoreBreakdown(score);
    _logger.info(' $breakdown');
  }

  /// Renders the list of audit [issues] with their messages.
  void _showIssues(List<dynamic> issues) {
    _logger.warn('Issues Detected');

    for (final issue in issues) {
      _logger.warn('  ● ${issue.message}');
    }
  }

  /// Renders publisher info, pub score, popularity, likes, last update,
  /// repository URL, supported platforms, and Flutter Favorite status.
  void _showKeyMetrics(PackageAuditResult audit) {
    final info = audit.packageInfo;

    _logger.info('Key Metrics');

    final publisherIcon = info.isTrustedPublisher ? '✓' : '';
    final publisherText = info.publisherId ?? 'None (unverified)';
    final publisherColored = info.isTrustedPublisher ? green.wrap(publisherText) : lightGray.wrap(publisherText);

    _logger.info('  Publisher:   $publisherColored $publisherIcon');

    final pubScoreIndicator = _barRenderer.renderPubScoreIndicator(info.panaScore);
    _logger.info('  Pub Score:   ${info.panaScore}/${info.maxPoints} $pubScoreIndicator');

    final popularityDots = _barRenderer.renderPopularityDots(info.popularity);
    _logger.info('  Popularity:  ${info.popularity}% $popularityDots');

    _logger.info('  Likes:       ${NumberFormatter.formatGrouped(info.likes)}');

    final updateStatus = _barRenderer.renderUpdateStatus(info.daysSinceLastUpdate);
    final updateText = DateFormatter.formatWithRelative(info.lastPublished);
    _logger.info('  Last Update: $updateText $updateStatus');

    if (info.repositoryUrl != null) {
      final repoUrl = info.repositoryUrl!.replaceFirst('https://', '');
      _logger.info('  Repository:  ${cyan.wrap(repoUrl)}');
    } else {
      _logger.warn('  Repository:  None', showSymbol: false);
    }

    if (info.supportedPlatforms.isNotEmpty) {
      final platforms = info.supportedPlatforms.join(', ');
      _logger.info('  Platforms:   $platforms');
    }

    if (info.isFlutterFavorite) {
      _logger.success('  Flutter Favorite ✨', showSymbol: false);
    }
  }

  /// Renders stars, forks, open issue count, recent commit activity, and
  /// last commit date from [githubMetrics].
  void _showGitHubMetrics(GitHubMetrics githubMetrics) {
    _logger.info('GitHub');

    final starsFormatted = NumberFormatter.formatCompact(githubMetrics.stars);
    _logger.info('  Stars:       ⭐ $starsFormatted');

    _logger.info('  Forks:       ${NumberFormatter.formatGrouped(githubMetrics.forks)}');

    final issuesColor = githubMetrics.openIssues > 100 ? yellow : green;
    final issuesFormatted = NumberFormatter.formatGrouped(githubMetrics.openIssues);
    _logger.info('  Open Issues: ${issuesColor.wrap(issuesFormatted.toString())!}');

    if (githubMetrics.commitCountLast90Days > 0) {
      final commitsFormatted = NumberFormatter.formatGrouped(githubMetrics.commitCountLast90Days);
      _logger.info('  Activity:    $commitsFormatted commits (90d)');
    }

    if (githubMetrics.lastCommitDate != null) {
      final lastCommit = DateFormatter.formatWithRelative(githubMetrics.lastCommitDate!);
      _logger.info('  Last Commit: $lastCommit');
    }
  }

  /// Renders each CVE in [vulnerabilities] with a coloured severity badge and
  /// a fix-version hint when available.
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

  /// Renders a single-line verdict: Recommended, Use with caution, or
  /// Not Recommended — determined by the overall score.
  ///
  /// | Score range | Verdict                 |
  /// |-------------|-------------------------|
  /// | ≥ 80        | Recommended             |
  /// | 60 – 79     | Use with caution        |
  /// | < 60        | Not Recommended         |
  void _showRecommendation(PackageAuditResult audit) {
    final score = audit.score.total;

    if (score >= 80) {
      _logger.success('Recommended - High-quality, actively maintained package');
    } else if (score >= 60) {
      final warning = yellow.wrap('!')!;
      _logger.warn('$warning Use with caution - Some concerns, review before using', showSymbol: false);
    } else {
      final cross = red.wrap('✗')!;
      _logger.error('$cross Not Recommended - Appears abandoned, high risk for production use');
    }
  }

  // --------------------------------------------------------------------------
  // Private formatters
  // --------------------------------------------------------------------------

  /// Returns a status icon character based on [score].
  ///
  /// | Range  | Icon |
  /// |--------|------|
  /// | ≥ 90   | ✨   |
  /// | 70–89  | ✓    |
  /// | 50–69  | ⚠    |
  /// | < 50   | ✗    |
  String _getStatusIcon(int score) {
    if (score >= 90) return '✨';
    if (score >= 70) return '✓';
    if (score >= 50) return '⚠';
    return '✗';
  }

  /// Returns [score] formatted as `"n/100"` with ANSI colour applied.
  String _formatScore(int score) {
    final scoreStr = '$score/100';

    if (score >= 90) return green.wrap(scoreStr)!;
    if (score >= 70) return lightGreen.wrap(scoreStr)!;
    if (score >= 50) return yellow.wrap(scoreStr)!;
    return red.wrap(scoreStr)!;
  }

  /// Returns [grade] wrapped in parentheses with ANSI colour applied.
  String _formatGrade(String grade) {
    final gradeText = '($grade)';

    if (grade.startsWith('A')) return green.wrap(gradeText)!;
    if (grade.startsWith('B')) return lightGreen.wrap(gradeText)!;
    if (grade.startsWith('C')) return yellow.wrap(gradeText)!;
    return red.wrap(gradeText)!;
  }

  /// Returns a colour-coded severity badge for the given [severity] enum value.
  ///
  /// Accepts any type whose `toString()` ends with the severity name (e.g.
  /// `VulnerabilitySeverity.critical`).
  String _formatSeverity(dynamic severity) {
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
