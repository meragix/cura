import 'package:cura/src/domain/entities/package_audit_result.dart';
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
/// 3. Assembles and returns a [PackageAuditResult] containing all data
///    needed for the detailed view report.
///
/// Issue detection and suggestion generation are not yet implemented for the
/// single-package view; see TODO(#42) and TODO(#44) in the code below.
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
        issues: [], // TODO(#42): implement issue detection for single-package view
        suggestions: [], // TODO(#44): implement suggestion engine
        fromCache: fromCache,
      );

      return Result<PackageAuditResult>.success(audit);
    });
  }
}
