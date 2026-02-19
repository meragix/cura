import 'dart:io';

import 'package:yaml/yaml.dart';

/// Application info (version, build, etc.)
class AppInfo {
  /// App name
  static const String name = 'Cura';

  /// App description
  static const String description = 'Dart/Flutter package health auditor';

  /// Author
  static const String author = 'Meragix';

  /// Homepage
  static const String homepage = 'https://github.com/meragix/cura';

  /// Current version (loaded from pubspec.yaml)
  static String? _version;

  /// Get version (lazy load from pubspec.yaml)
  static Future<String> getVersion() async {
    if (_version != null) return _version!;

    try {
      // Try to read from pubspec.yaml (development mode)
      final pubspecFile = File('pubspec.yaml');

      if (await pubspecFile.exists()) {
        final content = await pubspecFile.readAsString();
        final yaml = loadYaml(content) as Map;
        _version = yaml['version']?.toString() ?? 'unknown';
        return _version!;
      }

      // Fallback: embedded version (production mode)
      _version = const String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
      return _version!;
    } catch (e) {
      _version = 'unknown';
      return _version!;
    }
  }

  /// Get full version string
  static Future<String> getFullVersion() async {
    final version = await getVersion();
    return '$name v$version';
  }

  /// Get detailed info
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
