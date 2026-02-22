import 'dart:io';

import 'package:cura/src/domain/ports/config_repository.dart';
import 'package:cura/src/infrastructure/config/models/config_defaults.dart';
import 'package:cura/src/infrastructure/config/models/cura_config.dart';
import 'package:yaml/yaml.dart';

/// YAML-backed [ConfigRepository] that loads configuration hierarchically.
///
/// ## Resolution order (highest priority → lowest)
///
/// 1. Project config (`./.cura/config.yaml`)
/// 2. Global config  (`~/.cura/config.yaml`)
/// 3. [ConfigDefaults.defaultConfig]
///
/// ## Write target
///
/// [save] and [setValue] always write to the **project** config file so that
/// changes are scoped to the current repository and do not affect global
/// settings.  [createDefault] writes to the **global** config file.
class YamlConfigRepository implements ConfigRepository {
  /// Absolute path to the global config file (`~/.cura/config.yaml`).
  final String _globalConfigPath;

  /// Absolute path to the project config file (`./.cura/config.yaml`).
  final String _projectConfigPath;

  /// Creates a repository that reads from [globalConfigPath] and
  /// [projectConfigPath].
  YamlConfigRepository({
    required String globalConfigPath,
    required String projectConfigPath,
  })  : _globalConfigPath = globalConfigPath,
        _projectConfigPath = projectConfigPath;

  // ===========================================================================
  // ConfigRepository interface
  // ===========================================================================

  /// Loads and merges all available config files.
  ///
  /// Returns the merged result of global config (fallback) overridden by the
  /// project config (if present).  Falls back to [ConfigDefaults.defaultConfig]
  /// when no global config file exists.
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
  ///
  /// The parent directory is created automatically when it does not exist.
  @override
  Future<void> save(CuraConfig config) async {
    final file = File(_projectConfigPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(config.toYamlString(isProject: true));
  }

  /// Returns `true` when at least one config file exists on disk.
  @override
  Future<bool> exists() async {
    if (await File(_globalConfigPath).exists()) return true;
    return File(_projectConfigPath).exists();
  }

  /// Creates the global config file with default values.
  ///
  /// When [force] is `false` (the default) this is a no-op if the file already
  /// exists, preserving any user customisations.  Set [force] to `true` to
  /// overwrite an existing global config with [ConfigDefaults.defaultConfig].
  @override
  Future<void> createDefault({bool force = false}) async {
    final file = File(_globalConfigPath);
    await file.parent.create(recursive: true);
    if (force || !await file.exists()) {
      await file.writeAsString(ConfigDefaults.defaultConfig.toYamlString());
    }
  }

  /// Reads a single value from the merged config by [key].
  ///
  /// Accepts both `snake_case` and `camelCase` key variants.
  /// Returns `null` for unrecognised keys.
  @override
  Future<T?> getValue<T>(String key) async {
    final config = await load();
    return _readValue(config, key) as T?;
  }

  /// Writes a single value to the project config file.
  ///
  /// Loads the current merged config, applies the change with [_writeValue],
  /// then persists the updated config via [save].  Unknown keys are silently
  /// ignored.
  @override
  Future<void> setValue(String key, dynamic value) async {
    final config = await load();
    await save(_writeValue(config, key, value));
  }

  // ===========================================================================
  // Private helpers
  // ===========================================================================

  /// Parses a YAML config file at [path].
  ///
  /// Returns `null` when the file does not exist, is empty, or cannot be
  /// parsed — treating all such cases as "config absent".
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

  /// Maps a config [key] to the corresponding value in [config].
  ///
  /// Supports both `snake_case` (YAML convention) and `camelCase` (Dart
  /// convention) for every field.  Returns `null` for unrecognised keys.
  dynamic _readValue(CuraConfig config, String key) {
    return switch (key) {
      // Appearance
      'theme' => config.theme,
      'use_colors' || 'useColors' => config.useColors,
      'use_emojis' || 'useEmojis' => config.useEmojis,
      // Cache
      'cache_max_age_hours' || 'cacheMaxAgeHours' => config.cacheMaxAgeHours,
      'enable_cache' || 'enableCache' => config.enableCache,
      'auto_update' || 'autoUpdate' => config.autoUpdate,
      // Scoring
      'min_score' || 'minScore' => config.minScore,
      // Performance
      'max_concurrency' || 'maxConcurrency' => config.maxConcurrency,
      'timeout_seconds' || 'timeoutSeconds' => config.timeoutSeconds,
      'max_retries' || 'maxRetries' => config.maxRetries,
      // Behaviour
      'fail_on_vulnerable' || 'failOnVulnerable' => config.failOnVulnerable,
      'fail_on_discontinued' ||
      'failOnDiscontinued' =>
        config.failOnDiscontinued,
      'show_suggestions' || 'showSuggestions' => config.showSuggestions,
      'max_suggestions_per_package' ||
      'maxSuggestionsPerPackage' =>
        config.maxSuggestionsPerPackage,
      // Logging
      'verbose_logging' || 'verboseLogging' => config.verboseLogging,
      'quiet' => config.quiet,
      // API
      'github_token' || 'githubToken' => config.githubToken,
      _ => null,
    };
  }

  /// Returns a copy of [config] with the field identified by [key] set to
  /// [value].
  ///
  /// Supports both `snake_case` and `camelCase` key variants.  Returns
  /// [config] unchanged when [key] is not recognised.
  CuraConfig _writeValue(CuraConfig config, String key, dynamic value) {
    return switch (key) {
      // Appearance
      'theme' => config.copyWith(theme: value as String),
      'use_colors' || 'useColors' => config.copyWith(useColors: value as bool),
      'use_emojis' || 'useEmojis' => config.copyWith(useEmojis: value as bool),
      // Cache
      'cache_max_age_hours' ||
      'cacheMaxAgeHours' =>
        config.copyWith(cacheMaxAgeHours: value as int),
      'enable_cache' ||
      'enableCache' =>
        config.copyWith(enableCache: value as bool),
      'auto_update' ||
      'autoUpdate' =>
        config.copyWith(autoUpdate: value as bool),
      // Scoring
      'min_score' || 'minScore' => config.copyWith(minScore: value as int),
      // Performance
      'max_concurrency' ||
      'maxConcurrency' =>
        config.copyWith(maxConcurrency: value as int),
      'timeout_seconds' ||
      'timeoutSeconds' =>
        config.copyWith(timeoutSeconds: value as int),
      'max_retries' ||
      'maxRetries' =>
        config.copyWith(maxRetries: value as int),
      // Behaviour
      'fail_on_vulnerable' ||
      'failOnVulnerable' =>
        config.copyWith(failOnVulnerable: value as bool),
      'fail_on_discontinued' ||
      'failOnDiscontinued' =>
        config.copyWith(failOnDiscontinued: value as bool),
      'show_suggestions' ||
      'showSuggestions' =>
        config.copyWith(showSuggestions: value as bool),
      'max_suggestions_per_package' ||
      'maxSuggestionsPerPackage' =>
        config.copyWith(maxSuggestionsPerPackage: value as int),
      // Logging
      'verbose_logging' ||
      'verboseLogging' =>
        config.copyWith(verboseLogging: value as bool),
      'quiet' => config.copyWith(quiet: value as bool),
      // API
      'github_token' ||
      'githubToken' =>
        config.copyWith(githubToken: value as String),
      _ => config,
    };
  }
}
