import 'package:cura/src/domain/entities/package_audit_result.dart';
import 'package:cura/src/domain/ports/package_data_aggregator.dart';
import 'package:cura/src/domain/usecases/calculate_score.dart';
import 'package:cura/src/domain/value_objects/package_result.dart';
import 'package:cura/src/domain/value_objects/result.dart';

class ViewPackageDetails {
  final PackageDataAggregator _aggregator;
  final CalculateScore _scoreCalculator;

  ViewPackageDetails({
    required PackageDataAggregator aggregator,
    required CalculateScore scoreCalculator,
  })  : _aggregator = aggregator,
        _scoreCalculator = scoreCalculator;

  Future<Result<PackageAuditResult>> execute(String packageName) async {
    final result = await _aggregator.fetchAll(packageName);

    return result.mapAsync<PackageAuditResult>((aggregated, fromCache) async {
      final score = _scoreCalculator.execute(
        aggregated.packageInfo,
        githubMetrics: aggregated.githubMetrics,
        vulnerabilities: aggregated.vulnerabilities,
      );

      final audit = PackageAuditResult(
        name: aggregated.name,
        version: aggregated.version,
        packageInfo: aggregated.packageInfo,
        githubMetrics: aggregated.githubMetrics,
        score: score,
        vulnerabilities: aggregated.vulnerabilities,
        issues: [], // todo Implement issues
        suggestions: [], // todo Implement suggestion engine
        fromCache: fromCache,
      );

      return Result<PackageAuditResult>.success(audit);
    });
  }
}
