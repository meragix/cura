import 'dart:async';

import 'package:cura/src/domain/entities/aggregated_package_data.dart';
import 'package:cura/src/domain/ports/package_data_aggregator.dart';
import 'package:cura/src/domain/value_objects/errors.dart';
import 'package:cura/src/domain/value_objects/exception.dart';
import 'package:cura/src/domain/value_objects/package_result.dart';
import 'package:cura/src/infrastructure/api/clients/github_client.dart';
import 'package:cura/src/infrastructure/api/clients/osv_client.dart';
import 'package:cura/src/infrastructure/api/clients/pub_dev_client.dart';
import 'package:cura/src/shared/utils/pool_manager.dart';

/// Facade that orchestrates data retrieval from three independent APIs:
/// pub.dev, GitHub, and OSV.dev.
///
/// ### Fetching strategy
/// - **pub.dev** is mandatory: a failure propagates as [PackageResult.failure].
/// - **GitHub** is optional: an unavailable repository or a failed request
///   resolves to `null`.
/// - **OSV.dev** is optional: a failed request resolves to an empty list.
///
/// ### Concurrency
/// All requests are throttled through a shared [PoolManager] to avoid
/// overwhelming upstream rate limits. GitHub and OSV calls for the same
/// package are issued in parallel via [Future.wait].
class MultiApiAggregator implements PackageDataAggregator {
  final PubDevApiClient _pubDevClient;
  final GitHubApiClient _githubClient;
  final OsvApiClient _osvClient;
  final PoolManager _pool;

  /// Creates a [MultiApiAggregator] with the provided API clients.
  ///
  /// [maxConcurrency] caps the number of simultaneous package fetches.
  /// Defaults to 5 when not specified.
  MultiApiAggregator({
    required PubDevApiClient pubDevClient,
    required GitHubApiClient githubClient,
    required OsvApiClient osvClient,
    int maxConcurrency = 5,
  })  : _pubDevClient = pubDevClient,
        _githubClient = githubClient,
        _osvClient = osvClient,
        _pool = PoolManager(maxConcurrency: maxConcurrency);

  /// Fetches aggregated data for a single [packageName].
  ///
  /// The call is queued through the pool to respect [maxConcurrency].
  /// Returns [PackageResult.success] on success or [PackageResult.failure]
  /// when pub.dev is unreachable, the package is not found, or a timeout
  /// occurs.
  @override
  Future<PackageResult> fetchAll(String packageName) {
    return _pool.execute(() => _fetchSingle(packageName));
  }

  /// Streams aggregated results for each name in [packageNames].
  ///
  /// Results are emitted as they complete; **order is not guaranteed**.
  /// Each individual fetch respects the shared concurrency pool.
  /// An empty [packageNames] list immediately completes the stream.
  @override
  Stream<PackageResult> fetchMany(List<String> packageNames) async* {
    if (packageNames.isEmpty) return;

    final controller = StreamController<PackageResult>();
    var remaining = packageNames.length;

    for (final name in packageNames) {
      _pool.execute(() => _fetchSingle(name)).then(
        (result) {
          controller.add(result);
          if (--remaining == 0) controller.close();
        },
        onError: (Object error, StackTrace stack) {
          controller.addError(error, stack);
          if (--remaining == 0) controller.close();
        },
      );
    }

    yield* controller.stream;
  }

  /// Fetches and assembles data for [packageName] from all three APIs.
  ///
  /// pub.dev is awaited first because its response is required to derive the
  /// repository URL and package name used by the subsequent calls. GitHub and
  /// OSV are then fetched concurrently and degrade gracefully on failure.
  Future<PackageResult> _fetchSingle(String packageName) async {
    try {
      // 1. pub.dev is mandatory — propagate any failure immediately.
      final packageInfo = await _pubDevClient.getPackageInfo(packageName);

      // 2. GitHub and OSV are optional — fetch concurrently.
      final (githubMetrics, vulnerabilities) = await Future.wait([
        _fetchGitHubSafe(packageInfo.repositoryUrl),
        _fetchOsvSafe(packageInfo.name),
      ]).then((results) => (results[0], results[1]));

      // 3. Assemble the aggregated result.
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
      return PackageResult.failure(
          PackageProviderError.rateLimit(e.retryAfter!));
    } catch (e) {
      return PackageResult.failure(PackageProviderError.network(e.toString()));
    }
  }

  /// Attempts to fetch GitHub repository metrics for [repositoryUrl].
  ///
  /// Returns `null` if [repositoryUrl] is absent, empty, or the request fails.
  Future<dynamic> _fetchGitHubSafe(String? repositoryUrl) async {
    if (repositoryUrl == null || repositoryUrl.isEmpty) return null;

    try {
      return await _githubClient.fetchMetrics(repositoryUrl);
    } catch (_) {
      return null;
    }
  }

  /// Attempts to fetch known vulnerabilities for [packageName] from OSV.dev.
  ///
  /// Returns an empty list if the request fails, ensuring scoring can proceed
  /// without vulnerability data.
  Future<dynamic> _fetchOsvSafe(String packageName) async {
    try {
      return await _osvClient.queryVulnerabilities(packageName);
    } catch (_) {
      return [];
    }
  }

  /// Closes the concurrency pool and releases its underlying resources.
  @override
  Future<void> dispose() => _pool.close();
}
