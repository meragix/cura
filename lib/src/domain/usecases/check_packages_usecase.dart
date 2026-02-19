import 'package:cura/src/domain/entities/package_audit_result.dart';
import 'package:cura/src/domain/entities/package_info.dart';
import 'package:cura/src/domain/entities/score.dart';
import 'package:cura/src/domain/entities/vulnerability.dart';
import 'package:cura/src/domain/ports/package_data_aggregator.dart';
import 'package:cura/src/domain/usecases/calculate_score.dart';
import 'package:cura/src/domain/value_objects/package_result.dart';
import 'package:cura/src/domain/value_objects/result.dart';

class CheckPackagesUsecase {
  final PackageDataAggregator _aggregator;
  final CalculateScore _scoreCalculator;

  CheckPackagesUsecase({
    required PackageDataAggregator aggregator,
    required CalculateScore scoreCalculator,
    int minScore = 70,
    bool failOnVulnerable = false,
    bool failOnDiscontinued = false,
  })  : _aggregator = aggregator,
        _scoreCalculator = scoreCalculator;

  Stream<Result<PackageAuditResult>> execute(
    List<String> packageNames,
  ) async* {
    await for (final packageResult in _aggregator.fetchMany(packageNames)) {
      // Transform PackageResult → Result<PackageAuditResult>
      yield await packageResult.mapAsync<PackageAuditResult>(
        (aggregated, fromCache) async {
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
            issues: _identifyIssues(
                aggregated.packageInfo, score, aggregated.vulnerabilities),
            suggestions: [], // todo Implement suggestion engine
            fromCache: fromCache,
          );
          return Result.success(audit);
        },
      );
    }
  }

  /// Identifier les problèmes critiques
  List<AuditIssue> _identifyIssues(
    PackageInfo packageInfo,
    Score score,
    List<Vulnerability> vulnerabilities,
  ) {
    final issues = <AuditIssue>[];

    // Issue 1 : Package discontinued
    if (packageInfo.isDiscontinued) {
      issues.add(AuditIssue.discontinued(packageInfo.name));
    }

    // Issue 2 : Vulnerabilities critiques
    final criticalVulns = vulnerabilities
        .where((v) => v.severity == VulnerabilitySeverity.critical)
        .toList();

    if (criticalVulns.isNotEmpty) {
      issues.add(AuditIssue.criticalVulnerabilities(
        count: criticalVulns.length,
        cveIds: criticalVulns.map((v) => v.id).toList(),
      ));
    }

    // Issue 3 : Score très faible
    if (score.total < 50) {
      issues.add(AuditIssue.lowScore(
        score: score.total,
        threshold: 50,
      ));
    }

    // Issue 4 : Pas de mise à jour depuis longtemps
    final daysSinceUpdate =
        DateTime.now().difference(packageInfo.lastPublished).inDays;

    if (daysSinceUpdate > 730) {
      // 2 ans
      issues.add(AuditIssue.stale(
        daysSinceUpdate: daysSinceUpdate,
      ));
    }

    return issues;
  }
}
