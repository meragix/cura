import 'dart:convert';
import 'dart:io';
import 'package:cura/src/core/constants.dart';
import 'package:cura/src/core/helper/utils.dart';
import 'package:cura/src/domain/models/package_info.dart';
import 'package:path/path.dart' as path;

class CacheEntry {
  final PackageInfo packageInfo;
  final DateTime cachedAt;

  CacheEntry({
    required this.packageInfo,
    required this.cachedAt,
  });

  bool get isValid {
    final now = DateTime.now();
    return now.difference(cachedAt) < CuraConstants.cacheValidityDuration;
  }

  Map<String, dynamic> toJson() => {
        'packageInfo': packageInfo.toJson(),
        'cachedAt': cachedAt.toIso8601String(),
      };

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      packageInfo: PackageInfo.fromJson(json['packageInfo']),
      cachedAt: DateTime.parse(json['cachedAt']),
    );
  }
}

class CacheService {
  final String _cacheDir;
  late final File _cacheFile;
  Map<String, CacheEntry> _cache = {};

  CacheService({String? cacheDir})
      : _cacheDir = cacheDir ?? _getDefaultCacheDir() {
    _cacheFile = File(path.join(_cacheDir, CuraConstants.cacheFileName));
    _loadCache();
  }

  static String _getDefaultCacheDir() {
    final home = HelperUtils.getHomeDirectory();
    return path.join(home, CuraConstants.curaDirName);
  }

  void _loadCache() {
    try {
      if (!_cacheFile.existsSync()) {
        _cacheFile.createSync(recursive: true);
        _cacheFile.writeAsStringSync('{}');
        return;
      }

      final content = _cacheFile.readAsStringSync();
      if (content.isEmpty || content == '{}') return;

      final Map<String, dynamic> jsonData = jsonDecode(content);

      _cache = jsonData.map((key, value) {
        try {
          return MapEntry(key, CacheEntry.fromJson(value));
        } catch (e) {
          // Ignore les entrées corrompues
          return MapEntry(key, null as CacheEntry);
        }
      })
        ..removeWhere((key, value) => value == null);

      // Nettoyer les entrées expirées
      _cleanExpiredEntries();
    } catch (e) {
      // Si le cache est corrompu, on le réinitialise
      _cache = {};
      _saveCache();
    }
  }

  void _saveCache() {
    try {
      final jsonData =
          _cache.map((key, value) => MapEntry(key, value.toJson()));
      _cacheFile.writeAsStringSync(jsonEncode(jsonData));
    } catch (e) {
      // Échec silencieux de sauvegarde
    }
  }

  void _cleanExpiredEntries() {
    final now = DateTime.now();
    _cache.removeWhere((_, entry) {
      return now.difference(entry.cachedAt) >
          CuraConstants.cacheValidityDuration;
    });
  }

  PackageInfo? get(String packageName) {
    final entry = _cache[packageName];
    if (entry == null || !entry.isValid) {
      return null;
    }
    return entry.packageInfo;
  }

  void set(String packageName, PackageInfo info) {
    _cache[packageName] = CacheEntry(
      packageInfo: info,
      cachedAt: DateTime.now(),
    );
    _saveCache();
  }

  void clear() {
    _cache.clear();
    _saveCache();
  }

  int get size => _cache.length;

  Map<String, DateTime> getCacheStats() {
    return _cache.map((key, value) => MapEntry(key, value.cachedAt));
  }
}
