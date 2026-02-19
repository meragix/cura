import 'package:cura/src/domain/entities/health_check_report.dart';
import 'package:cura/src/domain/ports/package_data_aggregator.dart';
import 'package:cura/src/domain/usecases/calculate_score.dart';
import 'package:cura/src/domain/value_objects/package_result.dart';
import 'package:cura/src/domain/value_objects/result.dart';

/// Use Case : Check health (CI/CD mode)
class CheckHealth {
  final PackageDataAggregator _aggregator;
  final CalculateScore _scoreCalculator;

  CheckHealth({
    required PackageDataAggregator aggregator,
    required CalculateScore scoreCalculator,
  })  : _aggregator = aggregator,
        _scoreCalculator = scoreCalculator;

  Future<Result<HealthCheckReport>> execute({
    required int minScore,
    required bool failOnVulnerable,
    required bool failOnDiscontinued,
  }) async {
    // 1. Parse pubspec
    //final parser = PubspecParser();
    // todo: Read pubspec file

    // 2. Fetch all packages
    final packageNames = ['dio']; // todo: Extract from pubspec

    var totalScore = 0;
    var belowThreshold = 0;
    var vulnerableCount = 0;
    var discontinuedCount = 0;

    await for (final result in _aggregator.fetchMany(packageNames)) {
      if (result is PackageFailure) continue;

      result.mapValue(
        (aggregated, fromCache) {
          final score = _scoreCalculator.execute(
            aggregated.packageInfo,
            githubMetrics: aggregated.githubMetrics,
            vulnerabilities: aggregated.vulnerabilities,
          );

          totalScore += score.total;

          if (score.total < minScore) {
            belowThreshold++;
          }

          if (aggregated.hasCriticalVulns) {
            vulnerableCount++;
          }

          if (aggregated.packageInfo.isDiscontinued) {
            discontinuedCount++;
          }
        },
      );
    }

    final report = HealthCheckReport(
      totalPackages: packageNames.length,
      averageScore: totalScore ~/ packageNames.length,
      belowThreshold: belowThreshold,
      vulnerablePackages: vulnerableCount,
      discontinuedPackages: discontinuedCount,
      hasFailed: belowThreshold > 0 ||
          (failOnVulnerable && vulnerableCount > 0) ||
          (failOnDiscontinued && discontinuedCount > 0),
    );

    return Result.success(report);
  }
}
