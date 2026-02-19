import 'dart:io';

import 'package:cura/src/domain/ports/config_repository.dart';
import 'package:cura/src/infrastructure/config/models/config_defaults.dart';
import 'package:cura/src/infrastructure/config/models/cura_config.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

/// YAML configuration repository (hierarchical: global + project)
class YamlConfigRepository implements ConfigRepository {
  final String _globalConfigPath;
  final String _projectConfigPath;

  YamlConfigRepository({
    required String globalConfigPath,
    required String projectConfigPath,
  })  : _globalConfigPath = globalConfigPath,
        _projectConfigPath = projectConfigPath;

  @override
  Future<CuraConfig> load() async {
    // 1. Load global config
    final globalConfig = await _loadConfig(_globalConfigPath);

    // 2. Load project config
    final projectConfig = await _loadConfig(_projectConfigPath);

    // 3. Merge (project overrides global)
    return _mergeConfigs(globalConfig, projectConfig);
  }

  @override
  Future<void> save(CuraConfig config) async {
    // Save to project config (user choice)
    await _saveConfig(_projectConfigPath, config);
  }

  @override
  Future<bool> exists() async {
    return await File(_globalConfigPath).exists() || await File(_projectConfigPath).exists();
  }

  @override
  Future<void> createDefault() async {
    // Create global config with defaults
    final dir = File(_globalConfigPath).parent;
    await dir.create(recursive: true);

    await _saveConfig(_globalConfigPath, ConfigDefaults.defaultConfig);
  }

  @override
  Future<T?> getValue<T>(String key) async {
    final config = await load();
    // Simple key access (extend avec path navigation si besoin)
    return _getValueFromConfig(config, key) as T?;
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    final config = await load();
    final updated = _updateConfigValue(config, key, value);
    await save(updated);
  }

  // ===========================================================================
  // PRIVATE METHODS
  // ===========================================================================

  Future<CuraConfig?> _loadConfig(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;

    final content = await file.readAsString();
    final yaml = loadYaml(content) as Map<dynamic, dynamic>?;

    if (yaml == null) return null;

    // Convert YamlMap to Map<String, dynamic>
    final map = _yamlToMap(yaml);

    try {
      return CuraConfig.fromJson(map);
    } catch (e) {
      // Invalid config → fallback to default
      return null;
    }
  }

  Future<void> _saveConfig(String path, CuraConfig config) async {
    final file = File(path);
    await file.parent.create(recursive: true);

    final writer = YamlWriter();
    final yaml = writer.write(config.toJson());

    await file.writeAsString(yaml);
  }

  CuraConfig _mergeConfigs(CuraConfig? global, CuraConfig? project) {
    if (global == null && project == null) {
      return ConfigDefaults.defaultConfig;
    }

    if (project == null) return global!;
    if (global == null) return project;

    // Project overrides global (field by field)
    return global.copyWith(
      theme: project.theme,
      useColors: project.useColors,
      useEmojis: project.useEmojis,
      cacheMaxAgeHours: project.cacheMaxAgeHours,
      enableCache: project.enableCache,
      maxConcurrency: project.maxConcurrency,
      timeoutSeconds: project.timeoutSeconds,
      minScore: project.minScore,
      scoreWeights: project.scoreWeights,
      showSuggestions: project.showSuggestions,
      maxSuggestionsPerPackage: project.maxSuggestionsPerPackage,
      failOnVulnerable: project.failOnVulnerable,
      failOnDiscontinued: project.failOnDiscontinued,
      ignoredPackages: project.ignoredPackages,
      trustedPublishers: project.trustedPublishers,
      verboseLogging: project.verboseLogging,
      quiet: project.quiet,
      githubToken: project.githubToken ?? global.githubToken,
    );
  }

  Map<String, dynamic> _yamlToMap(Map<dynamic, dynamic> yaml) {
    final result = <String, dynamic>{};

    yaml.forEach((key, value) {
      if (value is YamlMap) {
        result[key.toString()] = _yamlToMap(value);
      } else if (value is YamlList) {
        result[key.toString()] = value.map((e) => e.toString()).toList();
      } else {
        result[key.toString()] = value;
      }
    });

    return result;
  }

  dynamic _getValueFromConfig(CuraConfig config, String key) {
    return switch (key) {
      'theme' => config.theme,
      'useColors' => config.useColors,
      'useEmojis' => config.useEmojis,
      'minScore' => config.minScore,
      _ => null,
    };
  }

  CuraConfig _updateConfigValue(CuraConfig config, String key, dynamic value) {
    return switch (key) {
      'theme' => config.copyWith(theme: value as String),
      'useColors' => config.copyWith(useColors: value as bool),
      'useEmojis' => config.copyWith(useEmojis: value as bool),
      'minScore' => config.copyWith(minScore: value as int),
      _ => config,
    };
  }
}
