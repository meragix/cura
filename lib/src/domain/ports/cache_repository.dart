import 'package:cura/src/domain/entities/package_info.dart';

/// Port : Cache local pour packages
abstract class CacheRepository {
  /// Initialize cache (create tables si nécessaire)
  Future<void> initialize();

  /// Get cached package
  /// Returns null si cache miss ou expiré
  Future<CachedPackageInfo?> get(String packageName);

  /// Set package in cache
  Future<void> set(String packageName, PackageInfo packageInfo);

  /// Clear all cache
  Future<void> clear();

  /// Remove expired entries
  Future<void> cleanup();

  /// Close database connection
  Future<void> close();
}

/// Wrapper pour info cachée (avec TTL)
class CachedPackageInfo {
  final PackageInfo data;
  final DateTime cachedAt;
  final int ttlHours;

  const CachedPackageInfo({
    required this.data,
    required this.cachedAt,
    required this.ttlHours,
  });

  bool get isExpired {
    final expiresAt = cachedAt.add(Duration(hours: ttlHours));
    return DateTime.now().isAfter(expiresAt);
  }

  Duration get timeUntilExpiry {
    final expiresAt = cachedAt.add(Duration(hours: ttlHours));
    return expiresAt.difference(DateTime.now());
  }
}
