import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;

/// Singleton SQLite database used as the local cache store for Cura.
///
/// ### Schema (v1)
/// - `package_cache` — raw [PackageInfo] rows keyed by package name.
/// - `aggregated_cache` — full [AggregatedPackageData] blobs (pub.dev +
///   GitHub + OSV) keyed by package name.
///
/// Both tables share the same four columns:
/// | Column      | Type    | Description                              |
/// |-------------|---------|------------------------------------------|
/// | key         | TEXT PK | Package name                             |
/// | data        | TEXT    | JSON-encoded payload                     |
/// | cached_at   | INTEGER | Unix epoch in milliseconds               |
/// | ttl_hours   | INTEGER | Time-to-live in hours                    |
///
/// ### Concurrency safety
/// Dart's event loop is single-threaded, but `await` yields control back to
/// the scheduler. A naive `if (db != null) return db` guard is therefore
/// insufficient when two callers race before the first initialisation
/// completes. This class resolves that by memoising the initialisation
/// [Future] itself ([_initFuture]), so all concurrent callers await the same
/// in-flight operation and receive the same [Database] instance.
class CacheDatabase {
  CacheDatabase._();

  static Database? _database;

  /// Memoised initialisation future — prevents concurrent double-init.
  static Future<Database>? _initFuture;

  /// Returns the shared [Database] instance, initialising it on first access.
  ///
  /// Concurrent calls that arrive before the database is ready all await the
  /// same [Future], ensuring [_initDatabase] is invoked exactly once.
  static Future<Database> get instance async {
    if (_database != null) return _database!;
    _initFuture ??= _initDatabase();
    return _initFuture!;
  }

  /// Opens (or creates) the SQLite database at `~/.cura/cache/cura_cache.db`.
  ///
  /// Registers the FFI factory on desktop platforms (Windows, Linux, macOS)
  /// before opening the file.
  static Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await _getDatabasePath();

    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    return _database!;
  }

  /// Resolves the absolute path for the database file.
  ///
  /// Creates `~/.cura/cache/` if it does not already exist.
  /// Throws an [Exception] when the home directory cannot be determined from
  /// the environment (`HOME` on Unix, `USERPROFILE` on Windows).
  static Future<String> _getDatabasePath() async {
    final homeDir =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];

    if (homeDir == null) {
      throw Exception(
        'Cannot determine the home directory. '
        'Set the HOME (Unix) or USERPROFILE (Windows) environment variable.',
      );
    }

    final cacheDir = path.join(homeDir, '.cura', 'cache');
    await Directory(cacheDir).create(recursive: true);

    return path.join(cacheDir, 'cura_cache.db');
  }

  /// Creates all tables and performance indexes on a fresh database.
  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE package_cache (
        key       TEXT    PRIMARY KEY,
        data      TEXT    NOT NULL,
        cached_at INTEGER NOT NULL,
        ttl_hours INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE aggregated_cache (
        key       TEXT    PRIMARY KEY,
        data      TEXT    NOT NULL,
        cached_at INTEGER NOT NULL,
        ttl_hours INTEGER NOT NULL
      )
    ''');

    // Indexes on cached_at allow efficient expiry sweeps (cleanupExpired).
    await db.execute(
      'CREATE INDEX idx_package_cached_at ON package_cache(cached_at)',
    );
    await db.execute(
      'CREATE INDEX idx_aggregated_cached_at ON aggregated_cache(cached_at)',
    );
  }

  /// Applies incremental schema migrations when the database version increases.
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Placeholder for v1 → v2 migration.
      // Example: await db.execute('ALTER TABLE aggregated_cache ADD COLUMN ...');
    }
  }

  /// Closes the database connection and resets the singleton state.
  ///
  /// After this call, the next access to [instance] will re-open the database.
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _initFuture = null;
    }
  }

  /// Deletes all rows from every cache table.
  ///
  /// The database connection and schema are preserved; only the cached data
  /// is removed.
  static Future<void> clearAll() async {
    final db = await instance;
    await db.delete('package_cache');
    await db.delete('aggregated_cache');
  }

  /// Removes all rows whose TTL has elapsed from every cache table.
  ///
  /// Expiry is evaluated as `cached_at + ttl_hours * 3 600 000 ms < now`.
  /// Call this periodically (e.g., on startup) to reclaim disk space.
  static Future<void> cleanupExpired() async {
    final db = await instance;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    const expiredWhere = 'cached_at + (ttl_hours * 3600000) < ?';

    await db.delete('package_cache',
        where: expiredWhere, whereArgs: [nowMs]);
    await db.delete('aggregated_cache',
        where: expiredWhere, whereArgs: [nowMs]);
  }
}
