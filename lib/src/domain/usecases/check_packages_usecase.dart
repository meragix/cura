import 'package:cura/src/domain/entities/package_audit_result.dart';
import 'package:cura/src/domain/entities/package_info.dart';
import 'package:cura/src/domain/entities/score.dart';
import 'package:cura/src/domain/entities/vulnerability.dart';
import 'package:cura/src/domain/ports/package_data_aggregator.dart';
import 'package:cura/src/domain/usecases/calculate_score.dart';
import 'package:cura/src/domain/value_objects/package_result.dart';
import 'package:cura/src/domain/value_objects/result.dart';

/// Domain use case that audits a list of pub.dev packages concurrently.
///
/// [CheckPackagesUsecase] is the core orchestrator of the `cura check`
/// pipeline. For each package name it:
///
/// 1. Delegates data fetching to [PackageDataAggregator], which fans out
///    requests to pub.dev, GitHub, and OSV.dev APIs (with optional caching).
/// 2. Computes a composite health [Score] via [CalculateScore].
/// 3. Identifies [AuditIssue]s (discontinued status, critical CVEs, low score,
///    staleness).
/// 4. Yields a [Result]<[PackageAuditResult]> for each package so the caller
///    can render progress incrementally.
///
/// Results are emitted as a [Stream] — one element per package — preserving
/// concurrency order determined by the aggregator's internal pool.
///
/// ## Staleness threshold
///
/// A package is considered stale when it has not received a new version in
/// more than **730 days** (2 years). This threshold is intentionally
/// conservative to avoid false positives on stable, mature packages.
class CheckPackagesUsecase {
  final PackageDataAggregator _aggregator;
  final CalculateScore _scoreCalculator;

  /// Creates a [CheckPackagesUsecase].
  ///
  /// - [aggregator] provides aggregated package data from all external APIs.
  /// - [scoreCalculator] computes the composite health score for each package.
  /// - [minScore], [failOnVulnerable], and [failOnDiscontinued] are acceptance
  ///   criteria that will be used by the command layer to determine the final
  ///   exit code.
  ///
  /// > **Note:** `minScore`, `failOnVulnerable`, and `failOnDiscontinued` are
  /// > currently consumed by the composition root and not yet forwarded to this
  /// > use case at runtime. See TODO(#42) in [CheckCommand].
  CheckPackagesUsecase({
    required PackageDataAggregator aggregator,
    required CalculateScore scoreCalculator,
    int minScore = 70,
    bool failOnVulnerable = false,
    bool failOnDiscontinued = false,
  })  : _aggregator = aggregator,
        _scoreCalculator = scoreCalculator;

  /// Audits [packageNames] and streams one [Result]<[PackageAuditResult]>
  /// per package.
  ///
  /// Packages are processed with the concurrency level configured on the
  /// underlying [PackageDataAggregator]. Each emitted [Result] is either:
  ///
  /// - [Success] — contains a fully populated [PackageAuditResult].
  /// - [Failure] — contains an exception from the aggregator or scorer;
  ///   the caller should surface the error and continue processing remaining
  ///   packages.
  ///
  /// The stream completes only after every package in [packageNames] has been
  /// processed or has failed.
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
            suggestions: [], // TODO(#44): implement suggestion engine
            fromCache: fromCache,
          );
          return Result.success(audit);
        },
      );
    }
  }

  /// Inspects [packageInfo], [score], and [vulnerabilities] to produce a list
  /// of [AuditIssue]s that require attention.
  ///
  /// Issues are evaluated in the following order of severity:
  ///
  /// | Condition                              | Issue type    | Severity  |
  /// |----------------------------------------|---------------|-----------|
  /// | `packageInfo.isDiscontinued`           | discontinued  | critical  |
  /// | Critical CVEs in [vulnerabilities]     | vulnerability | critical  |
  /// | `score.total < 50`                     | lowScore      | warning   |
  /// | No update in more than 730 days        | stale         | warning   |
  List<AuditIssue> _identifyIssues(
    PackageInfo packageInfo,
    Score score,
    List<Vulnerability> vulnerabilities,
  ) {
    final issues = <AuditIssue>[];

    // Issue 1: Package is marked as discontinued on pub.dev.
    if (packageInfo.isDiscontinued) {
      issues.add(AuditIssue.discontinued(packageInfo.name));
    }

    // Issue 2: One or more critical CVEs are present.
    final criticalVulns = vulnerabilities
        .where((v) => v.severity == VulnerabilitySeverity.critical)
        .toList();

    if (criticalVulns.isNotEmpty) {
      issues.add(AuditIssue.criticalVulnerabilities(
        count: criticalVulns.length,
        cveIds: criticalVulns.map((v) => v.id).toList(),
      ));
    }

    // Issue 3: Composite score is below the critical threshold of 50.
    if (score.total < 50) {
      issues.add(AuditIssue.lowScore(
        score: score.total,
        threshold: 50,
      ));
    }

    // Issue 4: No new release published in over 730 days (2 years).
    final daysSinceUpdate =
        DateTime.now().difference(packageInfo.lastPublished).inDays;

    if (daysSinceUpdate > 730) {
      issues.add(AuditIssue.stale(
        daysSinceUpdate: daysSinceUpdate,
      ));
    }

    return issues;
  }
}
