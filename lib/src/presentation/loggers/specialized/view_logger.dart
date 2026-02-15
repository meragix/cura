import 'package:cura/src/domain/models/cura_score.dart';
import 'package:cura/src/domain/models/package_health.dart';
import 'package:cura/src/domain/models/package_info.dart';
import 'package:cura/src/presentation/formatters/date_formatter.dart';
import 'package:cura/src/presentation/formatters/score_formatter.dart';
import 'package:cura/src/presentation/loggers/cura_logger.dart';
import 'package:mason_logger/mason_logger.dart';

/// Logger spécialisé pour la commande view
class ViewLogger {
  final CuraLogger _logger;
  final ScoreFormatter _scoreFormatter;

  ViewLogger({
    required CuraLogger logger,
    ScoreFormatter? scoreFormatter,
  })  : _logger = logger,
        _scoreFormatter = scoreFormatter ?? ScoreFormatter();

  void printPackageView(PackageHealth data) {
    if (data.score.total >= 70) {
      _printHealthyPackage(data);
    } else {
      _printUnhealthyPackage(data);
    }
  }

  void _printHealthyPackage(PackageHealth data) {
    // Header
    _logger.info('');
    _logger.info(
        '${_scoreFormatter.getGradeEmoji(data.score.grade)} ${styleBold.wrap(data.info.name)} '
        '${darkGray.wrap('v${data.info.version}')}');
    _logger.info('');

    // Score
    final gradeColor = _scoreFormatter.getGradeColor(data.score.grade);
    _logger.info(
        '${gradeColor.wrap('●')} Score: ${gradeColor.wrap('${data.score.total}/100')} '
        '${gradeColor.wrap('(${data.score.grade})')}');

    // Breakdown
    _printMiniBreakdown(data.score);

    // Métriques
    _printMetrics(data.info);

    // Recommandation
    _logger.info('');
    _logger.section('✓ Recommended');
    for (final r in data.score.recommendations) {
      _logger.info('  → $r');
    }
    _logger.info('');
  }

  void _printUnhealthyPackage(PackageHealth data) {
    // Header compact
    _logger.info('');
    _logger.info(
        '${_scoreFormatter.getGradeEmoji(data.score.grade)} ${styleBold.wrap(data.info.name)} '
        '${darkGray.wrap('v${data.info.version}')}');
    _logger.info('');

    // Score principal avec warning
    final gradeColor = _scoreFormatter.getGradeColor(data.score.grade);
    _logger.info(
        '${gradeColor.wrap('●')} Score: ${gradeColor.wrap('${data.score.total}/100')} '
        '${gradeColor.wrap('(${data.score.grade})')}');

    // Mini breakdown
    _printMiniBreakdown(data.score);

    // Issues (section importante pour packages problématiques)
    if (data.score.redFlags.isNotEmpty) {
      _logger.info('');
      //  _logger.warning('${styleBold.wrap('CRITICAL ISSUES')}');
      _logger.info('${red.wrap(styleBold.wrap('CRITICAL ISSUES'))}');
      for (final issue in data.score.redFlags) {
        _logger.info('  ${red.wrap('✖')} $issue');
      }
    }

    _logger.info('');

    // Métriques clés (plus succinct que pour healthy)
    _logger.info('${styleBold.wrap('Analysis Details')}');

    final publisher =
        data.info.publisherId ?? red.wrap('Unverified Publisher ⚠');
    _logger.info('  • Source:      $publisher');

    final timeAgo = DateFormatter.timeAgo(data.info.published);
    _logger.info(
        '  • Last Sync:   $timeAgo ${data.info.isStale ? red.wrap('(Outdated)') : ''}');
    _logger.info(
        '  • Pub Points:  ${data.info.panaScore}/${data.info.maxPanaScore} ${_getScoreIndicator(data.info.panaScore, data.info.maxPanaScore)}');

    // Recommandation (critiques pour packages problématiques)
    if (data.score.recommendations.isNotEmpty) {
      _logger.info('');
      _logger.warning('Suggested Actions:', showSymbol: false);
      for (final r in data.score.recommendations) {
        _logger.info('  ${yellow.wrap('→')} $r');
      }
    }

    // Recommandation
    // _logger.info('');
    //_logger.muted("ℹ Run 'cura suggest <package>' for detailed analysis");
    _logger.info('');
  }

  void _printMiniBreakdown(CuraScore score) {
    final vitality = _scoreFormatter.miniBar(score.maintenance, 40);
    final tech = _scoreFormatter.miniBar(score.trust, 30);
    final trust = _scoreFormatter.miniBar(score.maintenance, 20);
    final maint = _scoreFormatter.miniBar(score.maintenance, 10);

    _logger
        .info('└─ $vitality Vitality  $tech Tech  $trust Trust  $maint Maint');
  }

  void _printMetrics(PackageInfo pkg) {
    _logger.info('');
    // Highlights (métriques clés uniquement)
    _logger.info('${styleBold.wrap('Key Metrics')}');

    if (pkg.publisherId != null) {
      final publisherEmoji = pkg.hasVerifiedPublisher ? '✓' : '';
      _logger.info('  • Source:      ${pkg.publisherId} $publisherEmoji');
    }

    _logger.info(
        '  • Pub Score:   ${pkg.panaScore}/${pkg.maxPanaScore} ${_getScoreIndicator(pkg.panaScore, pkg.maxPanaScore)}');
    _logger.info(
        '  • Popularity:  ${pkg.popularity}% ${_getPopularityIndicator(pkg.popularity)}');

    // if (pkg.githubStars != null) {
    //   logger.info('  GitHub:      ⭐ ${_formatNumber(data.githubStars!)}');
    // }

    final days = DateFormatter.dateInDay(pkg.published);
    final updateEmoji = days < 90
        ? '🟢'
        : days < 365
            ? '🟡'
            : '🟠';
    _logger.info(
        '  • Last Sync:   ${DateFormatter.formatDaysAgo(days)} $updateEmoji');

    // Repository
    if (pkg.hasRepository) {
      _logger.info('  • Repository:  ${pkg.repositoryUrl}');
    }
  }

  String _getScoreIndicator(int score, int max) {
    final percentage = (score / max * 100).round();

    if (percentage >= 90) return green.wrap('●')!;
    if (percentage >= 70) return lightGreen.wrap('●')!;
    if (percentage >= 50) return yellow.wrap('●')!;
    return red.wrap('●')!;
  }

  String _getPopularityIndicator(int popularity) {
    if (popularity >= 90) return green.wrap('●●●')!;
    if (popularity >= 70) return lightGreen.wrap('●●○')!;
    if (popularity >= 50) return yellow.wrap('●○○')!;
    return red.wrap('○○○')!;
  }

  void _printFooter(PackageHealth summary) {
    _logger.muted("ℹ Run 'cura suggest <package>' for detailed analysis");
    _logger.info('');
  }
}
