import 'dart:io';

import 'package:yaml/yaml.dart';

/// Static metadata about the Cura application.
///
/// ## Version resolution order
/// 1. `APP_VERSION` compile-time define — set via `--define=APP_VERSION=x.y.z`
///    during `dart compile exe` or `dart pub global activate`. This is the
///    authoritative source in all production / CI builds.
/// 2. `pubspec.yaml` located relative to the running script — used when
///    running through `dart run bin/cura.dart` (development workflow).
/// 3. `'dev'` as an explicit sentinel — never silently reports a wrong version.
class AppInfo {
  const AppInfo._();

  static const String name = 'Cura';
  static const String description = 'Dart/Flutter package health auditor';
  static const String author = 'Meragix';
  static const String homepage = 'https://github.com/meragix/cura';

  // Cached after the first resolution — safe to call repeatedly within a
  // single process without incurring repeated disk I/O.
  static String? _cachedVersion;

  /// Resolves and returns the current version string (e.g. `'1.2.3'`).
  ///
  /// The result is memoised; subsequent calls return the cached value
  /// immediately without any I/O.
  static Future<String> getVersion() async {
    if (_cachedVersion != null) return _cachedVersion!;

    // 1. Compile-time define (production / CI builds).
    const envVersion = String.fromEnvironment('APP_VERSION');
    if (envVersion.isNotEmpty) {
      return _cachedVersion = envVersion;
    }

    // 2. pubspec.yaml — development mode (`dart run bin/cura.dart`).
    //    Resolve relative to the script path, NOT the CWD, so the lookup
    //    works regardless of where the user invokes the command from.
    try {
      final scriptDir = File(Platform.script.toFilePath()).parent;
      final candidates = [
        File('${scriptDir.path}/../pubspec.yaml'), // bin/ → project root
        File('${scriptDir.path}/pubspec.yaml'), //    script at project root
        File('pubspec.yaml'), //                      CWD last resort
      ];

      for (final file in candidates) {
        if (await file.exists()) {
          final content = await file.readAsString();
          final yaml = loadYaml(content) as Map;
          return _cachedVersion = yaml['version']?.toString() ?? 'dev';
        }
      }
    } catch (_) {}

    // 3. Explicit 'dev' sentinel — never silently report a wrong version.
    return _cachedVersion = 'dev';
  }

  /// Returns `'Cura v<version>'` — suitable for `--version` output.
  static Future<String> getFullVersion() async {
    return '$name v${await getVersion()}';
  }

  /// Returns a multi-line details block used by the `version` command.
  static Future<String> getDetailedInfo() async {
    final version = await getVersion();

    return '''
$name v$version
$description

Author:   $author
Homepage: $homepage
''';
  }
}
