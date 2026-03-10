import 'dart:convert';

import 'package:cura/src/domain/value_objects/errors.dart';
import 'package:cura/src/domain/value_objects/recommendation.dart';
import 'package:cura/src/domain/value_objects/red_flag.dart';
import 'package:cura/src/domain/entities/github_metrics.dart';
import 'package:cura/src/domain/entities/package_audit_result.dart';
import 'package:cura/src/domain/entities/score.dart';
import 'package:cura/src/presentation/formatters/date_formatter.dart';
import 'package:cura/src/presentation/formatters/error_formatter.dart';
import 'package:cura/src/presentation/formatters/number_formatter.dart';
import 'package:cura/src/presentation/loggers/console_logger.dart';
import 'package:cura/src/presentation/renderers/bar_renderer.dart';
import 'package:cura/src/presentation/themes/theme.dart';
import 'package:cura/src/presentation/themes/theme_manager.dart';
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
  final ErrorFormatter _errorFormatter;
  final BarRenderer _barRenderer;

  /// Creates a [ViewPresenter].
  ///
  /// [logger] is the active output logger (normal, verbose, quiet, or JSON).
  ViewPresenter({required ConsoleLogger logger})
      : _logger = logger,
        _errorFormatter = ErrorFormatter(logger),
        _barRenderer = BarRenderer(useColors: logger.useColors);

  CuraTheme get _theme => ThemeManager.current;
  bool get _useColors => _logger.useColors;

  /// Wraps [text] with [color] only when colours are enabled.
  String _c(String text, AnsiCode color) =>
      _useColors ? color.wrap(text) ?? text : text;

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
  void showPackageDetails(
    PackageAuditResult audit, {
    bool verbose = false,
    Duration elapsed = Duration.zero,
  }) {
    _logger.spacer();

    // Section 0: Cache status — verbose only
    if (verbose) {
      _showCacheStatus(audit);
      _logger.spacer();
    }

    // Section 1: Header
    _showHeader(audit);
    _logger.spacer();

    // Section 2: Score breakdown
    if (verbose) {
      _showVerboseScoreBreakdown(audit.score);
    } else {
      _showScoreBreakdown(audit.score);
    }
    _logger.spacer();

    // Section 3: Key metrics
    _showKeyMetrics(audit);
    _logger.spacer();

    // Section 4: GitHub metrics (conditional)
    if (audit.githubMetrics != null) {
      _showGitHubMetrics(audit.githubMetrics!);
      _logger.spacer();
    }

    // Section 5: Vulnerabilities (conditional)
    if (audit.vulnerabilities.isNotEmpty) {
      _showVulnerabilities(audit.vulnerabilities);
      _logger.spacer();
    }

    // Section 6: Issues (conditional)
    if (audit.issues.isNotEmpty) {
      _showIssues(audit.issues);
      _logger.spacer();
    }

    // Section 7: Risk signals — verbose only (conditional)
    if (verbose && audit.score.redFlags.isNotEmpty) {
      _showRedFlags(audit.score.redFlags);
      _logger.spacer();
    }

    // Section 8: Verdict & actionable recommendations from RecommendationEngine
    _showRecommendations(audit.recommendations);
    _logger.spacer();

    // Section 9: Timing — verbose only
    if (verbose) {
      _showTiming(elapsed, audit.requestCount);
      _logger.spacer();
    }
  }

  /// Displays a top-level error message (e.g. package not found).
  void showError(String message) {
    _logger.spacer();
    _logger.error(message);
    _logger.spacer();
  }

  /// Formats and displays a [PackageProviderError] using [ErrorFormatter].
  void showProviderError(PackageProviderError error) {
    _errorFormatter.format(error);
  }

  /// Displays the correct command invocation when a required argument is
  /// missing.
  void showUsage(String invocation) {
    _logger.info('');
    _logger.info('Usage: $invocation');
  }

  /// Emits a machine-readable JSON audit report for the package.
  ///
  /// Schema:
  /// ```json
  /// {
  ///   "timestamp":   "<ISO-8601 UTC>",
  ///   "package":     { ...audit fields, score breakdown, GitHub, vulns },
  ///   "performance": { "time_ms": N, "api_calls": N, "from_cache": bool }
  /// }
  /// ```
  void showJsonOutput(PackageAuditResult audit,
      {Duration elapsed = Duration.zero}) {
    final score = audit.score;
    final info = audit.packageInfo;

    final output = <String, dynamic>{
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'package': {
        'name': audit.name,
        'version': audit.version,
        'status': audit.status.name,
        'score': {
          'total': score.total,
          'grade': score.grade.label,
          'vitality': score.vitality,
          'technical_health': score.technicalHealth,
          'trust': score.trust,
          'maintenance': score.maintenance,
          if (score.penalty != 0) 'penalty': score.penalty,
          if (score.penaltyItems.isNotEmpty)
            'penalty_items': score.penaltyItems
                .map((p) => {'label': p.label, 'points': p.points})
                .toList(),
        },
        'publisher': info.publisherId,
        'pub_score': info.panaScore,
        'max_points': info.maxPoints,
        'popularity': info.popularity,
        'likes': info.likes,
        'last_published': info.lastPublished.toUtc().toIso8601String(),
        'repository': info.repositoryUrl,
        'platforms': info.supportedPlatforms,
        'is_flutter_favorite': info.isFlutterFavorite,
        'is_null_safe': info.isNullSafe,
        'is_dart3_compatible': info.isDart3Compatible,
        if (audit.githubMetrics != null)
          'github': {
            'stars': audit.githubMetrics!.stars,
            'forks': audit.githubMetrics!.forks,
            'open_issues': audit.githubMetrics!.openIssues,
            'commits_90d': audit.githubMetrics!.commitCountLast90Days,
            if (audit.githubMetrics!.lastCommitDate != null)
              'last_commit': audit.githubMetrics!.lastCommitDate!
                  .toUtc()
                  .toIso8601String(),
          },
        if (score.redFlags.isNotEmpty)
          'red_flags': score.redFlags
              .map((f) => {
                    'severity': f.severity.name,
                    'message': f.message,
                  })
              .toList(),
        if (audit.vulnerabilities.isNotEmpty)
          'vulnerabilities':
              audit.vulnerabilities.map((v) => v.toJson()).toList(),
        if (audit.issues.isNotEmpty)
          'issues': audit.issues.map((i) => i.toJson()).toList(),
        if (audit.recommendations.isNotEmpty)
          'recommendations': audit.recommendations
              .map((r) => {'level': r.level.name, 'message': r.message})
              .toList(),
      },
      'performance': {
        'time_ms': elapsed.inMilliseconds,
        'api_calls': audit.requestCount,
        'from_cache': audit.fromCache,
      },
    };

    // write() bypasses quiet mode so JSON is always emitted.
    _logger.write('${const JsonEncoder.withIndent('  ').convert(output)}\n');
  }

  // --------------------------------------------------------------------------
  // Private section renderers
  // --------------------------------------------------------------------------

  /// Renders the package name, version, overall score, and letter grade.
  void _showHeader(PackageAuditResult audit) {
    final statusIcon = _getStatusIcon(audit.score.total);
    final packageName = _c(audit.name, _theme.primary);
    final version = _c('v${audit.version}', _theme.textSecondary);

    _logger.info(' $statusIcon $packageName $version');
    _logger.spacer();

    final scoreStr = _formatScore(audit.score.total);
    final grade = _formatGrade(audit.score.grade.label);

    _logger.info(' ● Score: $scoreStr $grade');
  }

  /// Renders a visual bar chart for each dimension of [score].
  void _showScoreBreakdown(Score score) {
    final breakdown = _barRenderer.renderScoreBreakdown(score);
    _logger.info(' $breakdown');
  }

  /// Renders a detailed score table for each dimension — verbose mode only.
  void _showVerboseScoreBreakdown(Score score) {
    _logger.info('Score Breakdown');

    _printDimensionRow(
        'Vitality', score.vitality, 40, score.breakdown.vitalityDetails);
    _printDimensionRow('Tech Health', score.technicalHealth, 30,
        score.breakdown.technicalHealthDetails);
    _printDimensionRow('Trust', score.trust, 20, score.breakdown.trustDetails);
    _printDimensionRow('Maintenance', score.maintenance, 10,
        score.breakdown.maintenanceDetails);

    if (score.penaltyItems.isNotEmpty) {
      _showPenalties(score.penalty, score.penaltyItems);
    }

    _logger.info('  ${'─' * 42}');
    _logger.info(
        '  ${'Total'.padRight(13)} ${''.padRight(7)} ${_formatScore(score.total)}');
  }

  void _printDimensionRow(String label, int value, int max, String detail) {
    final pct = value / max;
    final icon = pct >= 0.75
        ? _c('✓', _theme.success)
        : pct >= 0.50
            ? _c('!', _theme.warning)
            : _c('✗', _theme.error);
    final ratio = '${value.toString().padLeft(2)}/$max'.padRight(6);
    final detailStr = detail.isNotEmpty ? _c('  $detail', _theme.muted) : '';
    _logger.info('  ${label.padRight(13)} $ratio  $icon$detailStr');
  }

  /// Renders the penalty block with tree connectors and a clamp note if needed.
  void _showPenalties(int appliedPenalty, List<PenaltyItem> items) {
    final itemsSum = items.fold(0, (sum, item) => sum + item.points);
    final isClamped = itemsSum < appliedPenalty; // items sum to more negative

    final ratio = '$appliedPenalty/0'.padRight(6);
    _logger
        .info('  ${'Penalties'.padRight(13)} $ratio  ${_c('✗', _theme.error)}');

    for (var i = 0; i < items.length; i++) {
      final isLast = i == items.length - 1 && !isClamped;
      final connector = isLast ? '└─' : '├─';
      final label = '${items[i].label}:'.padRight(22);
      _logger.info(
          '    $connector $label${_c('${items[i].points}', _theme.error)}');
    }

    if (isClamped) {
      _logger
          .info('    └─ ${_c('(clamped to $appliedPenalty)', _theme.muted)}');
    }
  }

  /// Renders publisher info, pub score, popularity, likes, last update,
  /// repository URL, supported platforms, and Flutter Favorite status.
  void _showKeyMetrics(PackageAuditResult audit) {
    final info = audit.packageInfo;

    _logger.info('Key Metrics');

    final publisherIcon =
        info.isTrustedPublisher ? _c('✓', _theme.success) : '';
    final publisherText = info.publisherId ?? 'None (unverified)';
    final publisherColored = info.isTrustedPublisher
        ? _c(publisherText, _theme.success)
        : _c(publisherText, _theme.muted);

    _logger.info('  Publisher:   $publisherColored $publisherIcon');

    final pubScoreIndicator =
        _barRenderer.renderPubScoreIndicator(info.panaScore);
    _logger.info(
        '  Pub Score:   ${info.panaScore}/${info.maxPoints} $pubScoreIndicator');

    final popularityDots = _barRenderer.renderPopularityDots(info.popularity);
    _logger.info('  Popularity:  ${info.popularity}% $popularityDots');

    _logger.info('  Likes:       ${NumberFormatter.formatGrouped(info.likes)}');

    final updateStatus =
        _barRenderer.renderUpdateStatus(info.daysSinceLastUpdate);
    final updateText = DateFormatter.formatWithRelative(info.lastPublished);
    _logger.info('  Last Update: $updateText $updateStatus');

    if (info.repositoryUrl != null) {
      final repoUrl = info.repositoryUrl!.replaceFirst('https://', '');
      _logger.info('  Repository:  ${_c(repoUrl, _theme.primary)}');
    } else {
      _logger.warn('  Repository:  None');
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

    _logger.info(
        '  Forks:       ${NumberFormatter.formatGrouped(githubMetrics.forks)}');

    final issuesColor =
        githubMetrics.openIssues > 100 ? _theme.warning : _theme.success;
    final issuesFormatted =
        NumberFormatter.formatGrouped(githubMetrics.openIssues);
    _logger
        .info('  Open Issues: ${_c(issuesFormatted.toString(), issuesColor)}');

    if (githubMetrics.commitCountLast90Days > 0) {
      final commitsFormatted =
          NumberFormatter.formatGrouped(githubMetrics.commitCountLast90Days);
      _logger.info('  Activity:    $commitsFormatted commits (90d)');
    }

    if (githubMetrics.lastCommitDate != null) {
      final lastCommit =
          DateFormatter.formatWithRelative(githubMetrics.lastCommitDate!);
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

  /// Renders the list of audit [issues] with their messages.
  void _showIssues(List<dynamic> issues) {
    _logger.alert('Issues Detected', level: AlertLevel.warning);

    for (final issue in issues) {
      _logger.info('  ● ${issue.message}');
    }
  }

  /// Renders raw risk signals from the scoring engine — verbose mode only.
  ///
  /// Each flag is colour-coded by [RedFlagSeverity]:
  /// critical → red, warning → yellow, info → gray.
  void _showRedFlags(List<RedFlag> flags) {
    _logger.alert('Risk Signals', level: AlertLevel.error);
    for (final flag in flags) {
      final icon = switch (flag.severity) {
        RedFlagSeverity.critical => _c('●', _theme.error),
        RedFlagSeverity.warning => _c('●', _theme.warning),
        RedFlagSeverity.info => _c('●', _theme.muted),
      };
      _logger.info('  $icon ${flag.message}');
    }
  }

  /// Renders actionable improvement recommendations from [RecommendationEngine].
  ///
  /// Icon and colour are driven by [RecommendationLevel]:
  /// - critical → red ✗
  /// - warning  → yellow !
  /// - action   → cyan →
  /// - advisory → gray →
  void _showRecommendations(List<Recommendation> recs) {
    _logger.info(_c('Recommendations', _theme.success));
    for (final rec in recs) {
      final icon = switch (rec.level) {
        RecommendationLevel.critical => _c('✗', _theme.error),
        RecommendationLevel.warning => _c('!', _theme.warning),
        RecommendationLevel.action => _c('→', _theme.primary),
        RecommendationLevel.advisory => _c('→', _theme.muted),
      };
      _logger.info('  $icon ${rec.message}');
    }
  }

  /// Renders cache provenance — verbose mode only.
  ///
  /// Hit:  `Cache: ✓ Hit (2h 15m old, valid)`
  /// Miss: `Cache: ✗ Miss, fetching...`
  void _showCacheStatus(PackageAuditResult audit) {
    if (audit.fromCache && audit.cachedAt != null) {
      final age = DateTime.now().toUtc().difference(audit.cachedAt!.toUtc());
      final ageStr = _formatAge(age);
      final label = _c('Cache:', _theme.muted);
      _logger
          .info('$label ${_c('✓ Hit', _theme.success)} ($ageStr old, valid)');
    } else {
      final label = _c('Cache:', _theme.muted);
      _logger.info('$label ${_c('✗ Miss', _theme.error)}, fetching...');
    }
  }

  /// Renders elapsed time and API call count — verbose mode only.
  ///
  /// Example: `⏱️  342ms (5 API calls)`
  void _showTiming(Duration elapsed, int requestCount) {
    final ms = elapsed.inMilliseconds;
    final timeStr = _c('⏱️  ${ms}ms', _theme.muted);
    final callsStr = requestCount > 0
        ? _c('($requestCount API call${requestCount == 1 ? '' : 's'})',
            _theme.muted)
        : _c('(cached — 0 API calls)', _theme.muted);
    _logger.info('$timeStr $callsStr');
  }

  /// Formats a [Duration] as a human-readable age string (e.g. `2h 15m`).
  String _formatAge(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours.remainder(24)}h';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return '${d.inSeconds}s';
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

    if (score >= 90) return _c(scoreStr, _theme.scoreExcellent);
    if (score >= 70) return _c(scoreStr, _theme.scoreGood);
    if (score >= 50) return _c(scoreStr, _theme.scoreFair);
    return _c(scoreStr, _theme.scorePoor);
  }

  /// Returns [grade] wrapped in parentheses with ANSI colour applied.
  String _formatGrade(String grade) {
    final gradeText = '($grade)';

    if (grade.startsWith('A')) return _c(gradeText, _theme.scoreExcellent);
    if (grade.startsWith('B')) return _c(gradeText, _theme.scoreGood);
    if (grade.startsWith('C')) return _c(gradeText, _theme.scoreFair);
    return _c(gradeText, _theme.scorePoor);
  }

  /// Returns a colour-coded severity badge for the given [severity] enum value.
  ///
  /// Accepts any type whose `toString()` ends with the severity name (e.g.
  /// `VulnerabilitySeverity.critical`).
  String _formatSeverity(dynamic severity) {
    final severityStr = severity.toString().split('.').last.toUpperCase();

    return switch (severityStr) {
      'CRITICAL' => _c('🔴 CRITICAL', _theme.error),
      'HIGH' => _c('🟠 HIGH', _theme.error),
      'MEDIUM' => _c('🟡 MEDIUM', _theme.warning),
      'LOW' => _c('🟢 LOW', _theme.success),
      _ => _c('⚪ UNKNOWN', _theme.muted),
    };
  }
}
