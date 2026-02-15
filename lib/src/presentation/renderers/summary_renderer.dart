
import 'package:cura/src/domain/models/package_health.dart';
import 'package:cura/src/presentation/loggers/cura_logger.dart';
import 'package:mason_logger/mason_logger.dart';

/// Renderer pour les résumés statistiques
class SummaryRenderer {
  final CuraLogger logger;

  SummaryRenderer({required this.logger});

  void render(List<PackageHealth> data) {
    if (data.isEmpty) {
      logger.warning('No packages analyzed.');
      return;
    }

    final summary = _calculateSummary(data);

    logger.info('');
    logger.section('SUMMARY');
    logger.info('   Total packages: ${summary.total}');
    logger.info('   Average score: ${summary.avgScore.toStringAsFixed(1)}/100');
    logger.info('   ${green.wrap('✓')} Healthy: ${summary.healthy}');

    if (summary.warnings > 0) {
      logger.info('   ${yellow.wrap('⚠')} Warnings: ${summary.warnings}');
    }

    if (summary.critical > 0) {
      logger.info('   ${red.wrap('✗')} Critical: ${summary.critical}');
    }
  }

  Summary _calculateSummary(List<PackageHealth> data) {
    int healthy = 0;
    int warnings = 0;
    int critical = 0;
    double totalScore = 0;

    for (final pkg in data) {
      totalScore += pkg.score.total;

      // On se base sur les Grades (A, B = Healthy / C, D = Warning / F = Critical)
      final grade = pkg.score.grade;
      if (grade == 'A' || grade == 'B') {
        healthy++;
      } else if (grade == 'F') {
        critical++;
      } else {
        warnings++;
      }
    }

    return Summary(
      total: data.length,
      healthy: healthy,
      warnings: warnings,
      critical: critical,
      avgScore: totalScore / data.length,
    );
  }
}

class Summary {
  final int total;
  final int healthy;
  final int warnings;
  final int critical;
  final double avgScore;

  const Summary({
    required this.total,
    required this.healthy,
    required this.warnings,
    required this.critical,
    required this.avgScore,
  });
}
