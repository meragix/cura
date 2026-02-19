import 'dart:convert';
import 'dart:io';

import 'package:cura/src/domain/entities/package_info.dart';
import 'package:cura/src/domain/ports/cache_repository.dart';
import 'package:cura/src/shared/constants/cache_constants.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SqliteCacheRepository implements CacheRepository {
  final String _databasePath;
  final int _maxAgeHours;
  Database? _database;

  SqliteCacheRepository({
    required String databasePath,
    int maxAgeHours = CacheConstants.defaultTtlHours,
  })  : _databasePath = databasePath,
        _maxAgeHours = maxAgeHours;

  @override
  Future<void> initialize() async {
    // Initialize FFI for desktop
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // Create directory if needed
    final dir = path.dirname(_databasePath);
    await Directory(dir).create(recursive: true);

    // Open database
    _database = await openDatabase(
      _databasePath,
      version: CacheConstants.databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE package_cache (
        name TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        cached_at INTEGER NOT NULL,
        ttl_hours INTEGER NOT NULL
      )
    ''');

    // Index pour cleanup
    await db.execute('''
      CREATE INDEX idx_cached_at ON package_cache(cached_at)
    ''');
  }

  @override
  Future<CachedPackageInfo?> get(String packageName) async {
    _ensureInitialized();

    final results = await _database!.query(
      'package_cache',
      where: 'name = ?',
      whereArgs: [packageName],
    );

    if (results.isEmpty) return null;

    final row = results.first;
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(
      row['cached_at'] as int,
    );
    final ttlHours = row['ttl_hours'] as int;

    final packageInfo = _deserializePackageInfo(row['data'] as String);

    return CachedPackageInfo(
      data: packageInfo,
      cachedAt: cachedAt,
      ttlHours: ttlHours,
    );
  }

  @override
  Future<void> set(String packageName, PackageInfo packageInfo) async {
    _ensureInitialized();

    await _database!.insert(
      'package_cache',
      {
        'name': packageName,
        'data': _serializePackageInfo(packageInfo),
        'cached_at': DateTime.now().millisecondsSinceEpoch,
        'ttl_hours': _maxAgeHours,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> clear() async {
    _ensureInitialized();
    await _database!.delete('package_cache');
  }

  @override
  Future<void> cleanup() async {
    _ensureInitialized();

    final cutoff = DateTime.now().subtract(Duration(hours: _maxAgeHours)).millisecondsSinceEpoch;

    await _database!.delete(
      'package_cache',
      where: 'cached_at < ?',
      whereArgs: [cutoff],
    );
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  void _ensureInitialized() {
    if (_database == null) {
      throw StateError('Cache not initialized. Call initialize() first.');
    }
  }

  // Serialization (simple JSON for POC, improved with protobuf if performance is critical)
  String _serializePackageInfo(PackageInfo info) {
    return jsonEncode({
      'name': info.name,
      'version': info.version,
      'description': info.description,
      'lastPublished': info.lastPublished.toIso8601String(),
      'panaScore': info.panaScore,
      'likes': info.likes,
      'popularity': info.popularity,
      'grantedPoints': info.grantedPoints,
      'maxPoints': info.maxPoints,
      'isNullSafe': info.isNullSafe,
      'isDart3Compatible': info.isDart3Compatible,
      'isDiscontinued': info.isDiscontinued,
      'isFlutterFavorite': info.isFlutterFavorite,
      'isNew': info.isNew,
      'isWasmReady': info.isWasmReady,
      'publisherId': info.publisherId,
      'supportedPlatforms': info.supportedPlatforms,
      'repositoryUrl': info.repositoryUrl,
      'homepageUrl': info.homepageUrl,
      'license': info.license,
    });
  }

  PackageInfo _deserializePackageInfo(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;

    return PackageInfo(
      name: map['name'] as String,
      version: map['version'] as String,
      description: map['description'] as String,
      lastPublished: DateTime.parse(map['lastPublished'] as String),
      panaScore: map['panaScore'] as int,
      likes: map['likes'] as int,
      popularity: map['popularity'] as int,
      grantedPoints: map['grantedPoints'] as int,
      maxPoints: map['maxPoints'] as int,
      isNullSafe: map['isNullSafe'] as bool,
      isDiscontinued: map['isDiscontinued'] as bool,
      isDart3Compatible: map['isDart3Compatible'] as bool,
      isFlutterFavorite: map['isFlutterFavorite'] as bool,
      isNew: map['isNew'] as bool,
      isWasmReady: map['isWasmReady'] as bool,
      publisherId: map['publisherId'] as String?,
      supportedPlatforms: (map['supportedPlatforms'] as List<dynamic>).cast<String>(),
      repositoryUrl: map['repositoryUrl'] as String?,
      homepageUrl: map['homepageUrl'] as String?,
      license: map['license'] as String?,
    );
  }
}
