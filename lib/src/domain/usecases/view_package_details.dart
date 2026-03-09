import 'package:cura/src/domain/entities/aggregated_package_data.dart';
import 'package:cura/src/domain/entities/package_audit_result.dart';
import 'package:cura/src/domain/entities/package_info.dart';
import 'package:cura/src/domain/entities/score.dart';
import 'package:cura/src/domain/entities/vulnerability.dart';
import 'package:cura/src/domain/ports/package_data_aggregator.dart';
import 'package:cura/src/domain/usecases/calculate_score.dart';
import 'package:cura/src/domain/value_objects/package_result.dart';
import 'package:cura/src/domain/value_objects/result.dart';

/// Domain use case that retrieves and scores a single pub.dev package.
///
/// [ViewPackageDetails] is the core orchestrator for the `cura view` command.
/// Unlike [CheckPackagesUsecase], which processes a batch of packages as a
/// stream, this use case operates on a single package name and returns a
/// single [Result]<[PackageAuditResult]>.
///
/// For the given package it:
///
/// 1. Fetches aggregated data (pub.dev metadata, GitHub metrics, CVEs) via
///    [PackageDataAggregator.fetchAll], benefiting from the caching decorator
///    transparently.
/// 2. Computes a composite health [Score] via [CalculateScore].
/// 3. Identifies [AuditIssue]s (discontinued status, critical CVEs, low score,
///    staleness) — same logic as [CheckPackagesUsecase].
/// 4. Derives human-readable suggestions from [Score.recommendations], which
///    are already produced by [RecommendationEngine] inside [CalculateScore].
/// 5. Assembles and returns a [PackageAuditResult] containing all data
///    needed for the detailed view report.
class ViewPackageDetails {
  final PackageDataAggregator _aggregator;
  final CalculateScore _scoreCalculator;

  /// Creates a [ViewPackageDetails] use case.
  ///
  /// - [aggregator] provides aggregated package data from all external APIs,
  ///   with optional caching applied transparently by [CachedAggregator].
  /// - [scoreCalculator] computes the composite health score from the
  ///   aggregated data.
  ViewPackageDetails({
    required PackageDataAggregator aggregator,
    required CalculateScore scoreCalculator,
  })  : _aggregator = aggregator,
        _scoreCalculator = scoreCalculator;

  /// Fetches and scores the package identified by [packageName].
  ///
  /// Returns:
  /// - [Result.success] wrapping a fully populated [PackageAuditResult] when
  ///   the package is found and all APIs respond successfully.
  /// - [Result.failure] wrapping an exception when the package does not exist,
  ///   the network is unavailable, or any API returns an unrecoverable error.
  Future<Result<PackageAuditResult>> execute(String packageName) async {
    final result = await _aggregator.fetchAll(packageName);

    return switch (result) {
      PackageFailure(:final error) => Result.failure(error),
      PackageSuccess(
        :final data,
        :final fromCache,
        :final requestCount,
        :final cachedAt
      ) =>
        await _buildAuditResult(data, fromCache, requestCount, cachedAt),
    };
  }

  Future<Result<PackageAuditResult>> _buildAuditResult(
    AggregatedPackageData aggregated,
    bool fromCache,
    int requestCount,
    DateTime? cachedAt,
  ) async {
    final score = _scoreCalculator.execute(
      aggregated.packageInfo,
      githubMetrics: aggregated.githubMetrics,
      vulnerabilities: aggregated.vulnerabilities,
    );

    final issues = _identifyIssues(
      aggregated.packageInfo,
      score,
      aggregated.vulnerabilities,
    );

    final audit = PackageAuditResult(
      name: aggregated.name,
      version: aggregated.version,
      packageInfo: aggregated.packageInfo,
      githubMetrics: aggregated.githubMetrics,
      score: score,
      vulnerabilities: aggregated.vulnerabilities,
      issues: issues,
      recommendations: score.recommendations,
      fromCache: fromCache,
      cachedAt: cachedAt,
      requestCount: requestCount,
    );

    return Result.success(audit);
  }

  /// Inspects [packageInfo], [score], and [vulnerabilities] to produce a list
  /// of [AuditIssue]s that require attention.
  ///
  /// Mirrors [CheckPackagesUsecase._identifyIssues] exactly — same conditions,
  /// same severity mapping.
  ///
  /// | Condition                          | Issue type    | Severity  |
  /// |------------------------------------|---------------|-----------|
  /// | `packageInfo.isDiscontinued`       | discontinued  | critical  |
  /// | Critical CVEs in [vulnerabilities] | vulnerability | critical  |
  /// | `score.total < 50`                 | lowScore      | warning   |
  /// | No update in more than 730 days    | stale         | warning   |
  List<AuditIssue> _identifyIssues(
    PackageInfo packageInfo,
    Score score,
    List<Vulnerability> vulnerabilities,
  ) {
    final issues = <AuditIssue>[];

    if (packageInfo.isDiscontinued) {
      issues.add(AuditIssue.discontinued(packageInfo.name));
    }

    final criticalVulns = vulnerabilities
        .where((v) => v.severity == VulnerabilitySeverity.critical)
        .toList();

    if (criticalVulns.isNotEmpty) {
      issues.add(AuditIssue.criticalVulnerabilities(
        count: criticalVulns.length,
        cveIds: criticalVulns.map((v) => v.id).toList(),
      ));
    }

    if (score.total < 50) {
      issues.add(AuditIssue.lowScore(
        score: score.total,
        threshold: 50,
      ));
    }

    final daysSinceUpdate =
        DateTime.now().difference(packageInfo.lastPublished).inDays;

    if (daysSinceUpdate > 730) {
      issues.add(AuditIssue.stale(daysSinceUpdate: daysSinceUpdate));
    }

    return issues;
  }
}
