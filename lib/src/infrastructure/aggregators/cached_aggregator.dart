import 'package:cura/src/domain/ports/cache_repository.dart';
import 'package:cura/src/domain/ports/package_data_aggregator.dart';
import 'package:cura/src/domain/value_objects/package_result.dart';

/// Decorator : Cache pour AggregatedPackageData
///
/// Cache TOUT (pub.dev + GitHub + OSV) en un seul bloc
class CachedAggregator implements PackageDataAggregator {
  final PackageDataAggregator _delegate;
  final CacheRepository _cache;

  CachedAggregator({
    required PackageDataAggregator delegate,
    required CacheRepository cache,
  })  : _delegate = delegate,
        _cache = cache;

  @override
  Future<PackageResult> fetchAll(String packageName) async {
    // 1. Tenter le cache (PackageInfo uniquement pour v1)
    final cached = await _cache.get(packageName);
    if (cached != null && !cached.isExpired) {
      // Cache hit : reconstruire AggregatedPackageData
      // Note : GitHub + OSV pas cachés pour v1
      return _delegate.fetchAll(packageName);
    }

    // 2. Cache miss → déléguer
    final result = await _delegate.fetchAll(packageName);

    // 3. Stocker en cache si succès
    if (result is PackageSuccess) {
      final aggregated = result.data;
      await _cache.set(packageName, aggregated.packageInfo);
      // todo: Cacher aussi GitHub + OSV
    }

    return result;
  }

  @override
  Stream<PackageResult> fetchMany(
    List<String> packageNames,
  ) async* {
    for (final name in packageNames) {
      yield await fetchAll(name);
    }
  }

  @override
  Future<void> dispose() => _delegate.dispose();
}
