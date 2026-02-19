import 'dart:async';

import 'package:cura/src/domain/entities/aggregated_package_data.dart';
import 'package:cura/src/domain/ports/package_data_aggregator.dart';
import 'package:cura/src/domain/value_objects/errors.dart';
import 'package:cura/src/domain/value_objects/exception.dart';
import 'package:cura/src/domain/value_objects/package_result.dart';
import 'package:cura/src/infrastructure/api/clients/github_client.dart';
import 'package:cura/src/infrastructure/api/clients/osv_client.dart';
import 'package:cura/src/infrastructure/api/clients/pub_dev_client.dart';
import 'package:pool/pool.dart';

/// Aggregator : Orchestration des 3 APIs (pub.dev + GitHub + OSV)
///
/// Stratégie :
/// - pub.dev : OBLIGATOIRE (fail si erreur)
/// - GitHub : OPTIONNEL (null si pas de repo ou fail)
/// - OSV : OPTIONNEL ([] si fail)
///
/// Performance :
/// - Fetching parallèle (Future.wait)
/// - Pool pour limiter concurrence globale
class MultiApiAggregator implements PackageDataAggregator {
  final PubDevApiClient _pubDevClient;
  final GitHubApiClient _githubClient;
  final OsvApiClient _osvClient;
  final Pool _pool;

  MultiApiAggregator({
    required PubDevApiClient pubDevClient,
    required GitHubApiClient githubClient,
    required OsvApiClient osvClient,
    int maxConcurrency = 5,
  })  : _pubDevClient = pubDevClient,
        _githubClient = githubClient,
        _osvClient = osvClient,
        _pool = Pool(maxConcurrency);

  @override
  Future<PackageResult> fetchAll(String packageName) async {
    return _pool.withResource(() => _fetchSingle(packageName));
  }

  @override
  Stream<PackageResult> fetchMany(
    List<String> packageNames,
  ) async* {
    final controller = StreamController<PackageResult>();
    var remaining = packageNames.length;

    for (final name in packageNames) {
      _pool.withResource(() => _fetchSingle(name)).then((result) {
        controller.add(result);
        if (--remaining == 0) {
          controller.close();
        }
      });
    }

    yield* controller.stream;
  }

  Future<PackageResult> _fetchSingle(
    String packageName,
  ) async {
    try {
      // 1. Fetch pub.dev (REQUIRED - fail fast)
      final packageInfo = await _pubDevClient.getPackageInfo(packageName);

      // 2. Fetch GitHub + OSV en parallèle (OPTIONAL)
      final (githubMetrics, vulnerabilities) = await Future.wait([
        _fetchGitHubSafe(packageInfo.repositoryUrl),
        _fetchOsvSafe(packageInfo.name),
      ]).then((results) => (results[0], results[1]));

      // 3. Aggregate
      final aggregated = AggregatedPackageData(
        packageInfo: packageInfo,
        githubMetrics: githubMetrics,
        vulnerabilities: vulnerabilities,
      );

      return PackageResult.success(data: aggregated, fromCache: false);
    } on PackageNotFoundException {
      return PackageResult.failure(PackageProviderError.notFound(packageName));
    } on TimeoutException {
      return PackageResult.failure(PackageProviderError.timeout(packageName));
    } on RateLimitException catch (e) {
      return PackageResult.failure(PackageProviderError.rateLimit(e.retryAfter!));
    } catch (e) {
      return PackageResult.failure(PackageProviderError.network(e.toString()));
    }
  }

  Future<dynamic> _fetchGitHubSafe(String? repositoryUrl) async {
    if (repositoryUrl == null || repositoryUrl.isEmpty) return null;

    try {
      return await _githubClient.fetchMetrics(repositoryUrl);
    } catch (e) {
      // GitHub fail → continue sans metrics
      return null;
    }
  }

  Future<dynamic> _fetchOsvSafe(String packageName) async {
    try {
      return await _osvClient.queryVulnerabilities(packageName);
    } catch (e) {
      // OSV fail → continue sans vulns
      return [];
    }
  }

  @override
  Future<void> dispose() => _pool.close();
}
