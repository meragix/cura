import 'dart:convert';

import 'package:cura/src/domain/entities/aggregated_package_data.dart';
import 'package:cura/src/domain/entities/github_metrics.dart';
import 'package:cura/src/domain/entities/package_info.dart';
import 'package:cura/src/domain/entities/vulnerability.dart';
import 'package:cura/src/domain/ports/package_data_aggregator.dart';
import 'package:cura/src/domain/value_objects/package_result.dart';
import 'package:cura/src/infrastructure/cache/database/cache_database.dart';
import 'package:cura/src/infrastructure/cache/models/cached_entry.dart';
import 'package:cura/src/infrastructure/cache/strategies/ttl_strategy.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Decorator that adds a SQLite-backed cache layer to any
/// [PackageDataAggregator].
///
/// Implements the **Decorator** pattern: every call is intercepted, the cache
/// is consulted first, and the underlying [_delegate] (typically a
/// [MultiApiAggregator]) is only reached on a cache miss. Successful
/// responses are persisted so subsequent calls can be served without hitting
/// the network.
///
/// ### Cache key
/// The cache key is the lowercase package name as returned by pub.dev.
///
/// ### TTL policy
/// TTLs are determined by [TtlStrategy.getAggregatedTtl] based on the
/// package's pub.dev popularity score (0–100). More popular packages are
/// cached longer because their metadata changes less frequently.
///
/// ### Failure isolation
/// Cache read and write errors are silently swallowed: a read failure falls
/// through to the delegate, and a write failure does not surface to callers.
/// This ensures the cache is always a performance optimisation and never a
/// correctness dependency.
///
/// ### Concurrency
/// [fetchMany] processes packages **sequentially** by design. Cache hits are
/// sub-millisecond operations, so the sequential overhead is negligible. On
/// cache misses the delegate's own concurrency pool (e.g. [PoolManager]) still
/// caps upstream API load.
class CachedAggregator implements PackageDataAggregator {
  final PackageDataAggregator _delegate;

  /// Creates a [CachedAggregator] that wraps [delegate].
  CachedAggregator({required PackageDataAggregator delegate})
      : _delegate = delegate;

  // ---------------------------------------------------------------------------
  // PackageDataAggregator interface
  // ---------------------------------------------------------------------------

  /// Returns cached [AggregatedPackageData] for [packageName] when available
  /// and not expired; otherwise delegates to [_delegate] and caches the
  /// successful response.
  ///
  /// The returned [PackageSuccess.fromCache] flag is `true` when the result
  /// was served from the local SQLite store.
  @override
  Future<PackageResult> fetchAll(String packageName) async {
    // 1. Check cache first.
    final cached = await _getFromCache(packageName);
    if (cached != null && !cached.isExpired) {
      return PackageSuccess(data: cached.data, fromCache: true);
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

  /// Reads a [CachedAggregatedData] entry for [packageName] from SQLite.
  ///
  /// Returns `null` on a cache miss or if any read error occurs.
  Future<CachedAggregatedData?> _getFromCache(String packageName) async {
    try {
      final db = await CacheDatabase.instance;

      final rows = await db.query(
        'aggregated_cache',
        where: 'key = ?',
        whereArgs: [packageName],
        limit: 1,
      );

      if (rows.isEmpty) return null;

      final row = rows.first;

      return CachedAggregatedData(
        key: row['key'] as String,
        data: _deserialize(row['data'] as String),
        cachedAt:
            DateTime.fromMillisecondsSinceEpoch(row['cached_at'] as int),
        ttlHours: row['ttl_hours'] as int,
      );
    } catch (_) {
      // Degrade gracefully — a read failure is treated as a cache miss.
      return null;
    }
  }

  /// Persists [data] for [packageName] in SQLite with a TTL derived from
  /// [TtlStrategy.getAggregatedTtl].
  ///
  /// Uses `REPLACE` conflict resolution so a stale row is atomically
  /// overwritten. Write errors are silently ignored.
  Future<void> _saveToCache(
    String packageName,
    AggregatedPackageData data,
  ) async {
    try {
      final db = await CacheDatabase.instance;
      final ttl = TtlStrategy.getAggregatedTtl(
        popularity: data.packageInfo.popularity,
      );

      await db.insert(
        'aggregated_cache',
        {
          'key': packageName,
          'data': _serialize(data),
          'cached_at': DateTime.now().millisecondsSinceEpoch,
          'ttl_hours': ttl,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {
      // Silent fail — the cache is never a correctness requirement.
    }
  }

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Encodes [data] to a JSON string for SQLite storage.
  String _serialize(AggregatedPackageData data) {
    return jsonEncode({
      'package_info': data.packageInfo.toJson(),
      'github_metrics': data.githubMetrics?.toJson(),
      'vulnerabilities':
          data.vulnerabilities.map((v) => v.toJson()).toList(),
    });
  }

  /// Decodes a JSON string produced by [_serialize] back into
  /// [AggregatedPackageData].
  AggregatedPackageData _deserialize(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;

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

/// Typed alias for a [CachedEntry] holding [AggregatedPackageData].
typedef CachedAggregatedData = CachedEntry<AggregatedPackageData>;
