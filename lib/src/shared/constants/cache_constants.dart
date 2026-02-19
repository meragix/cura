class CacheConstants {
  const CacheConstants._();

  // TTLs (Time To Live)
  static const int defaultTtlHours = 24;
  static const int popularPackageTtlHours = 6; // Packages with >1000 likes
  static const int stablePackageTtlHours = 72; // Mature packages (v2.0+)

  // Limits
  static const int maxCacheSize = 1000; // Max entries
  static const int maxCacheSizeMb = 100; // Max size in MB

  // Database
  static const String databaseName = 'cura_cache.db';
  static const int databaseVersion = 1;
}
