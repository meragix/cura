import 'package:cura/src/domain/entities/aggregated_package_data.dart';
import 'package:cura/src/domain/entities/github_metrics.dart';
import 'package:cura/src/domain/entities/package_info.dart';
import 'package:cura/src/domain/entities/vulnerability.dart';
import 'package:cura/src/domain/ports/package_data_aggregator.dart';
import 'package:cura/src/domain/value_objects/package_result.dart';
import 'package:cura/src/infrastructure/cache/json_file_system_cache.dart';
import 'package:cura/src/infrastructure/cache/strategies/ttl_strategy.dart';

/// Decorator that adds a JSON-file-backed cache layer to any
/// [PackageDataAggregator].
///
/// Implements the **Decorator** pattern: every call is intercepted, the cache
/// is consulted first, and the underlying [_delegate] (typically a
/// [MultiApiAggregator]) is only reached on a cache miss. Successful
/// responses are persisted so subsequent calls can be served without hitting
/// the network.
///
/// ### Cache namespace
/// All entries are stored under [JsonFileSystemCache.aggregatedNamespace]
/// (`aggregated/`). The file name is the lowercase package name as returned
/// by pub.dev (e.g. `~/.cura/cache/aggregated/dio.json`).
///
/// ### TTL policy
/// TTLs are computed by [TtlStrategy.getAggregatedTtl] based on the package's
/// pub.dev popularity score (0–100). More popular packages are cached longer
/// because their metadata changes less frequently.
///
/// ### Failure isolation
/// Cache read and write errors are silently swallowed: a read failure falls
/// through to the delegate, and a write failure does not surface to callers.
/// The cache is always a performance optimisation and never a correctness
/// dependency.
///
/// ### Concurrency
/// [fetchMany] processes packages **sequentially** by design. Cache hits are
/// sub-millisecond file reads, so the sequential overhead is negligible. On
/// cache misses the delegate's own concurrency pool still caps upstream load.
class CachedAggregator implements PackageDataAggregator {
  final PackageDataAggregator _delegate;
  final JsonFileSystemCache _cache;

  /// Creates a [CachedAggregator] that wraps [delegate] with [cache].
  CachedAggregator({
    required PackageDataAggregator delegate,
    required JsonFileSystemCache cache,
  })  : _delegate = delegate,
        _cache = cache;

  // ---------------------------------------------------------------------------
  // PackageDataAggregator interface
  // ---------------------------------------------------------------------------

  /// Returns cached [AggregatedPackageData] for [packageName] when available
  /// and not expired; otherwise delegates to [_delegate] and caches the
  /// successful response.
  ///
  /// The returned [PackageSuccess.fromCache] flag is `true` when the result
  /// was served from the local JSON file store.
  @override
  Future<PackageResult> fetchAll(String packageName) async {
    // 1. Check cache first.
    final cached = await _getFromCache(packageName);
    if (cached != null) {
      return PackageSuccess(data: cached, fromCache: true);
    }

    // 2. Cache miss — delegate to the underlying aggregator.
    final result = await _delegate.fetchAll(packageName);

    // 3. Persist on success so the next call can be served from cache.
    if (result is PackageSuccess) {
      await _saveToCache(packageName, result.data);
    }

    return result;
  }

  /// Streams results for [packageNames] by calling [fetchAll] sequentially.
  ///
  /// Results are emitted in the **same order** as the input list. Sequential
  /// processing is intentional: cache hits complete instantly, and on cache
  /// misses the concurrency is governed by the delegate's pool.
  @override
  Stream<PackageResult> fetchMany(List<String> packageNames) async* {
    for (final name in packageNames) {
      yield await fetchAll(name);
    }
  }

  /// Forwards [dispose] to the underlying delegate.
  @override
  Future<void> dispose() => _delegate.dispose();

  // ---------------------------------------------------------------------------
  // Cache operations
  // ---------------------------------------------------------------------------

  /// Reads [AggregatedPackageData] for [packageName] from the JSON cache.
  ///
  /// Returns `null` on a cache miss, expired entry, or any IO/parse failure.
  Future<AggregatedPackageData?> _getFromCache(String packageName) async {
    final raw = await _cache.get(
      JsonFileSystemCache.aggregatedNamespace,
      packageName,
    );
    if (raw == null) return null;
    try {
      return _deserialize(raw);
    } catch (_) {
      return null;
    }
  }

  /// Persists [data] for [packageName] with a TTL derived from
  /// [TtlStrategy.getAggregatedTtl].
  Future<void> _saveToCache(
    String packageName,
    AggregatedPackageData data,
  ) async {
    final ttl = TtlStrategy.getAggregatedTtl(
      popularity: data.packageInfo.popularity,
    );
    final expiresAt = DateTime.now().add(Duration(hours: ttl));

    await _cache.put(
      JsonFileSystemCache.aggregatedNamespace,
      packageName,
      _serialize(data),
      expiresAt,
    );
  }

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Encodes [data] to a JSON-compatible [Map] for storage.
  Map<String, dynamic> _serialize(AggregatedPackageData data) {
    return {
      'package_info': data.packageInfo.toJson(),
      'github_metrics': data.githubMetrics?.toJson(),
      'vulnerabilities': data.vulnerabilities.map((v) => v.toJson()).toList(),
    };
  }

  /// Decodes a [Map] produced by [_serialize] back into [AggregatedPackageData].
  ///
  /// The [map] argument is the `data` field already extracted from the JSON
  /// file envelope by [JsonFileSystemCache.get] — no additional JSON decoding
  /// is needed here.
  AggregatedPackageData _deserialize(Map<String, dynamic> map) {
    return AggregatedPackageData(
      packageInfo: PackageInfo.fromJson(
        map['package_info'] as Map<String, dynamic>,
      ),
      githubMetrics: map['github_metrics'] != null
          ? GitHubMetrics.fromJson(
              map['github_metrics'] as Map<String, dynamic>,
            )
          : null,
      vulnerabilities: (map['vulnerabilities'] as List)
          .map((v) => Vulnerability.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }
}
