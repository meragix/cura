class CacheConstants {
  const CacheConstants._();

  /// Sub-directory under the user's home folder where cache files are stored.
  /// Resolved at runtime as `${homeDir}/$cacheSubDir`.
  static const String cacheSubDir = '.cura/cache';

  /// Namespace for [AggregatedPackageData] entries (`aggregated/`).
  static const String aggregatedNamespace = 'aggregated';
}
