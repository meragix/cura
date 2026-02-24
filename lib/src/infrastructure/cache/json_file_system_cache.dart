import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// A lightweight, fail-safe cache store that persists entries as individual
/// JSON files under [cacheDir].
///
/// ### Namespace layout on disk
/// ```
/// <cacheDir>/
///   aggregated/        ← AggregatedPackageData (pub.dev + GitHub + OSV)
///     dio.json
///     provider.json
///   <namespace>/       ← reserved for future namespaces (e.g. suggestions)
///     <key>.json
/// ```
///
/// ### JSON file schema (schemaVersion: 1)
/// ```json
/// {
///   "schemaVersion": 1,
///   "key": "dio",
///   "cachedAt": "2026-02-24T10:00:00.000Z",
///   "expiresAt": "2026-02-25T10:00:00.000Z",
///   "data": { ... }
/// }
/// ```
///
/// ### Atomicity
/// All writes use the **write-then-rename** pattern:
/// 1. Encode JSON and write to `<key>.json.tmp` with `flush: true`.
/// 2. On Windows, delete `<key>.json` if it already exists (rename is not
///    atomic on Windows when the target exists, but the worst case is a
///    transient stale read — acceptable for a cache).
/// 3. Rename `.tmp` → `.json` (atomic on POSIX via `rename(2)`).
///
/// ### Fail-safe contract
/// Every public method swallows all exceptions:
/// - [get] returns `null` on any IO/parse failure → treated as a cache miss.
/// - [put] fails silently → the next call fetches fresh data from the network.
/// - [delete], [clearAll], [cleanupExpired] never throw.
///
/// This guarantees
/// that a degraded or missing cache never crashes the CLI.
class JsonFileSystemCache {
  static const int _schemaVersion = 1;
  static const String _jsonExt = '.json';
  static const String _tmpExt = '.tmp'; // appended to the full .json path → <key>.json.tmp

  /// Well-known namespace for [AggregatedPackageData] entries.
  static const String aggregatedNamespace = 'aggregated';

  /// Root directory for all cache namespaces (e.g. `~/.cura/cache`).
  final String cacheDir;

  /// Creates a [JsonFileSystemCache] rooted at [cacheDir].
  ///
  /// Call [initialize] before any read/write operation to ensure the directory
  /// hierarchy exists on disk.
  const JsonFileSystemCache({required this.cacheDir});

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Creates [cacheDir] and the [aggregatedNamespace] sub-directory.
  ///
  /// Safe to call multiple times — [Directory.create] with `recursive: true`
  /// is a no-op when the path already exists.
  Future<void> initialize() async {
    try {
      await Directory(p.join(cacheDir, aggregatedNamespace))
          .create(recursive: true);
    } catch (_) {
      // Cannot create cache directory — subsequent ops will fail gracefully.
    }
  }

  // ---------------------------------------------------------------------------
  // Core read / write
  // ---------------------------------------------------------------------------

  /// Returns the `data` payload for [key] in [namespace], or `null` when:
  ///
  /// - No file exists for the key (cache miss).
  /// - The file cannot be parsed as valid JSON (corrupted entry).
  /// - The `expiresAt` timestamp is in the past (TTL expired).
  /// - Any [FileSystemException] or [FormatException] occurs.
  ///
  /// Expired entries are deleted opportunistically before returning `null`.
  Future<Map<String, dynamic>?> get(String namespace, String key) async {
    try {
      final file = _fileFor(namespace, key);
      if (!await file.exists()) return null;

      final envelope = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final expiresAt = DateTime.parse(envelope['expiresAt'] as String);

      if (DateTime.now().isAfter(expiresAt)) {
        _fireAndForget(file.delete()); // opportunistic eviction
        return null;
      }

      return envelope['data'] as Map<String, dynamic>;
    } catch (_) {
      return null; // corruption or IO error → cache miss
    }
  }

  /// Persists [data] for [key] in [namespace] using atomic write-then-rename.
  ///
  /// [expiresAt] is stored verbatim in the envelope and is evaluated on
  /// subsequent [get] calls to determine entry validity.
  ///
  /// Silent on any failure — the cache is never a correctness requirement.
  Future<void> put(
    String namespace,
    String key,
    Map<String, dynamic> data,
    DateTime expiresAt,
  ) async {
    try {
      final dir = await _ensureNamespaceDir(namespace);
      final target = File(p.join(dir.path, '$key$_jsonExt'));

      final envelope = <String, dynamic>{
        'schemaVersion': _schemaVersion,
        'key': key,
        'cachedAt': DateTime.now().toUtc().toIso8601String(),
        'expiresAt': expiresAt.toUtc().toIso8601String(),
        'data': data,
      };

      await _writeAtomic(target, envelope);
    } catch (_) {
      // Silent fail — cache is a performance optimisation only.
    }
  }

  /// Deletes the cache file for [key] in [namespace].
  ///
  /// No-op when the file does not exist. Silent on any [FileSystemException].
  Future<void> delete(String namespace, String key) async {
    try {
      final file = _fileFor(namespace, key);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Maintenance
  // ---------------------------------------------------------------------------

  /// Deletes every `.json` entry across all namespaces under [cacheDir].
  ///
  /// Namespace directories are preserved. Silent on any failure.
  Future<void> clearAll() async {
    try {
      final root = Directory(cacheDir);
      if (!await root.exists()) return;

      await for (final entity in root.list(recursive: true)) {
        if (entity is File && entity.path.endsWith(_jsonExt)) {
          _fireAndForget(entity.delete());
        }
      }
    } catch (_) {}
  }

  /// Removes expired `.json` entries and orphaned `.json.tmp` files.
  ///
  /// - `.tmp` files that are older than 1 hour are considered orphaned
  ///   (left behind by a crash during a previous write).
  /// - `.json` files whose `expiresAt` is in the past are deleted.
  /// - `.json` files that cannot be parsed (corrupted) are also deleted.
  ///
  /// Returns the total number of files deleted.
  Future<int> cleanupExpired() async {
    var deleted = 0;
    try {
      final root = Directory(cacheDir);
      if (!await root.exists()) return 0;

      final now = DateTime.now();

      await for (final entity in root.list(recursive: true)) {
        if (entity is! File) continue;

        if (entity.path.endsWith(_tmpExt)) {
          deleted += await _deleteOrphanedTmp(entity, now);
          continue;
        }

        if (entity.path.endsWith(_jsonExt)) {
          deleted += await _deleteIfExpired(entity, now);
        }
      }
    } catch (_) {}

    return deleted;
  }

  /// Returns the number of **valid** (non-expired) entries per namespace.
  ///
  /// Keys are namespace sub-directory names; values are non-expired file counts.
  /// Expired, unreadable, or corrupted files are not counted.
  Future<Map<String, int>> stats() async {
    final counts = <String, int>{};
    try {
      final root = Directory(cacheDir);
      if (!await root.exists()) return counts;

      final now = DateTime.now();

      await for (final entity in root.list()) {
        if (entity is! Directory) continue;
        final namespace = p.basename(entity.path);
        counts[namespace] = await _countValid(entity, now);
      }
    } catch (_) {}

    return counts;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  File _fileFor(String namespace, String key) =>
      File(p.join(cacheDir, namespace, '$key$_jsonExt'));

  Future<Directory> _ensureNamespaceDir(String namespace) async {
    final dir = Directory(p.join(cacheDir, namespace));
    await dir.create(recursive: true);
    return dir;
  }

  /// Writes [json] to [target] using write-then-rename.
  ///
  /// Throws [FileSystemException] on failure so the caller's `catch (_)` can
  /// honour the fail-safe contract.
  Future<void> _writeAtomic(File target, Map<String, dynamic> json) async {
    final tmp = File('${target.path}$_tmpExt');
    try {
      await tmp.writeAsString(jsonEncode(json), flush: true);

      // On Windows, rename fails when the destination already exists.
      if (Platform.isWindows && await target.exists()) {
        await target.delete();
      }

      await tmp.rename(target.path);
    } catch (e) {
      _fireAndForget(tmp.delete()); // clean up orphaned .tmp
      rethrow;
    }
  }

  Future<int> _deleteOrphanedTmp(File file, DateTime now) async {
    try {
      final stat = await file.stat();
      if (now.difference(stat.modified) > const Duration(hours: 1)) {
        await file.delete();
        return 1;
      }
    } catch (_) {}
    return 0;
  }

  Future<int> _deleteIfExpired(File file, DateTime now) async {
    try {
      final envelope =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final expiresAt = DateTime.parse(envelope['expiresAt'] as String);
      if (now.isAfter(expiresAt)) {
        await file.delete();
        return 1;
      }
      return 0;
    } catch (_) {
      // Unparseable / corrupted entry — remove it.
      await file.delete().catchError((_) => file as FileSystemEntity);
      return 1;
    }
  }

  Future<int> _countValid(Directory namespace, DateTime now) async {
    var count = 0;
    try {
      await for (final file in namespace.list()) {
        if (file is! File || !file.path.endsWith(_jsonExt)) continue;
        try {
          final envelope =
              jsonDecode(await file.readAsString()) as Map<String, dynamic>;
          final expiresAt = DateTime.parse(envelope['expiresAt'] as String);
          if (!now.isAfter(expiresAt)) count++;
        } catch (_) {}
      }
    } catch (_) {}
    return count;
  }

  /// Schedules [future] to run in the background without awaiting the result.
  ///
  /// Used for non-critical side-effects (opportunistic eviction, orphan
  /// cleanup) where the outcome does not affect program correctness.
  // ignore: avoid_void_async
  void _fireAndForget(Future<void> future) => future.catchError((_) {});
}
