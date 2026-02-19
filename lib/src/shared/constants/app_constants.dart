// lib/src/shared/constants/app_constants.dart

import 'package:cura/src/shared/app_info.dart';

/// Constantes globales de l'application
class AppConstants {
  const AppConstants._();

  // Application
  static const String appName = 'cura';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Dart/Flutter package health auditor';

  // Directories
  static const String configDir = '.cura';
  static const String cacheDir = '.cura/cache';
  static const String globalConfigFile = 'config.yaml';
  static const String projectConfigFile = '.cura/config.yaml';

  /// Version (loaded dynamically from pubspec.yaml)
  static Future<String> getVersion() => AppInfo.getVersion();
}
