import 'dart:io';

import 'package:cura/src/domain/ports/config_repository.dart';
import 'package:cura/src/infrastructure/config/models/config_defaults.dart';
import 'package:cura/src/infrastructure/config/models/cura_config.dart';
import 'package:yaml/yaml.dart';

/// YAML-backed [ConfigRepository] that loads configuration hierarchically.
///
/// Resolution order (highest priority → lowest):
/// 1. Project config (`./.cura/config.yaml`)
/// 2. Global config (`~/.cura/config.yaml`)
/// 3. [ConfigDefaults.defaultConfig]
///
/// Writing ([save]) always targets the **project** config file so that changes
/// made at runtime are scoped to the current repository and do not affect the
/// user's global settings.
class YamlConfigRepository implements ConfigRepository {
  final String _globalConfigPath;
  final String _projectConfigPath;

  YamlConfigRepository({
    required String globalConfigPath,
    required String projectConfigPath,
  })  : _globalConfigPath = globalConfigPath,
        _projectConfigPath = projectConfigPath;

  // ===========================================================================
  // ConfigRepository interface
  // ===========================================================================

  @override
  Future<CuraConfig> load() async {
    final globalConfig = await _loadFile(_globalConfigPath);
    final projectConfig = await _loadFile(_projectConfigPath);

    // Fallback → global → merge with project.
    final base = globalConfig ?? ConfigDefaults.defaultConfig;
    return base.mergeWith(projectConfig);
  }

  /// Saves [config] to the **project** config file as a human-readable YAML
  /// document with inline comments.
  @override
  Future<void> save(CuraConfig config) async {
    final file = File(_projectConfigPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(config.toYamlString(isProject: true));
  }

  @override
  Future<bool> exists() async {
    if (await File(_globalConfigPath).exists()) return true;
    return File(_projectConfigPath).exists();
  }

  /// Creates the global config file with default values if it does not already
  /// exist.
  @override
  Future<void> createDefault() async {
    final file = File(_globalConfigPath);
    await file.parent.create(recursive: true);
    if (!await file.exists()) {
      await file.writeAsString(ConfigDefaults.defaultConfig.toYamlString());
    }
  }

  @override
  Future<T?> getValue<T>(String key) async {
    final config = await load();
    return _readValue(config, key) as T?;
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    final config = await load();
    await save(_writeValue(config, key, value));
  }

  // ===========================================================================
  // Private helpers
  // ===========================================================================

  /// Parses a YAML config file.  Returns `null` when the file does not exist
  /// or its content is empty / unparseable.
  Future<CuraConfig?> _loadFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;

    try {
      final content = await file.readAsString();
      final yaml = loadYaml(content);
      if (yaml is! Map) return null;
      return CuraConfig.fromYaml(yaml);
    } catch (_) {
      // Corrupt or unreadable file → treat as absent.
      return null;
    }
  }

  dynamic _readValue(CuraConfig config, String key) {
    return switch (key) {
      'theme' => config.theme,
      'use_colors' || 'useColors' => config.useColors,
      'use_emojis' || 'useEmojis' => config.useEmojis,
      'min_score' || 'minScore' => config.minScore,
      'max_concurrency' || 'maxConcurrency' => config.maxConcurrency,
      'timeout_seconds' || 'timeoutSeconds' => config.timeoutSeconds,
      'max_retries' || 'maxRetries' => config.maxRetries,
      'auto_update' || 'autoUpdate' => config.autoUpdate,
      'github_token' || 'githubToken' => config.githubToken,
      _ => null,
    };
  }

  CuraConfig _writeValue(CuraConfig config, String key, dynamic value) {
    return switch (key) {
      'theme' => config.copyWith(theme: value as String),
      'use_colors' || 'useColors' => config.copyWith(useColors: value as bool),
      'use_emojis' || 'useEmojis' => config.copyWith(useEmojis: value as bool),
      'min_score' || 'minScore' => config.copyWith(minScore: value as int),
      'max_concurrency' ||
      'maxConcurrency' =>
        config.copyWith(maxConcurrency: value as int),
      'timeout_seconds' ||
      'timeoutSeconds' =>
        config.copyWith(timeoutSeconds: value as int),
      'max_retries' ||
      'maxRetries' =>
        config.copyWith(maxRetries: value as int),
      'auto_update' ||
      'autoUpdate' =>
        config.copyWith(autoUpdate: value as bool),
      _ => config,
    };
  }
}
