import 'dart:io';

import 'package:cura/src/domain/ports/config_repository.dart';
import 'package:cura/src/infrastructure/config/models/config_defaults.dart';
import 'package:cura/src/infrastructure/config/models/cura_config.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

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

  /// Writes a single value to the project config file using a surgical
  /// YAML edit that preserves comments and formatting.
  ///
  /// If the project config file does not exist yet, it is created from the
  /// default project template before the edit is applied.
  ///
  /// Unknown keys are silently ignored.
  @override
  Future<void> setValue(String key, dynamic value) async {
    final projectFile = File(_projectConfigPath);

    if (!await projectFile.exists()) {
      await projectFile.parent.create(recursive: true);
      await projectFile.writeAsString(
        ConfigDefaults.defaultConfig.toYamlString(isProject: true),
      );
    }

    var content = await projectFile.readAsString();

    // Uncomment the github_token line when it is still commented out.
    if (key == 'github_token') {
      content = _uncommentKey(content, 'github_token');
    }

    final editor = YamlEditor(content);
    try {
      editor.update(key.split('.'), value);
      await projectFile.writeAsString(editor.toString());

      if (key == 'github_token') {
        await _ensureSecurePermissions(projectFile);
      }
    } catch (e) {
      throw StateError('Failed to update config key "$key": $e');
    }
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

  /// Removes the leading `#` comment marker from a line that starts with
  /// `# <key>:` so that the key becomes active in the YAML file.
  String _uncommentKey(String content, String key) {
    final pattern =
        RegExp(r'^#\s*(' + RegExp.escape(key) + r':.*)$', multiLine: true);
    if (content.contains(pattern)) {
      return content.replaceAllMapped(pattern, (match) => match.group(1)!);
    }
    return content;
  }

  /// Sets file permissions to `600` (owner read/write only) on non-Windows
  /// platforms.  Failures are silently swallowed to avoid blocking the caller
  /// in restricted environments.
  Future<void> _ensureSecurePermissions(File configFile) async {
    if (Platform.isWindows) return;
    try {
      await Process.run('chmod', ['600', configFile.path]);
    } catch (_) {
      // Silent failure: chmod may be unavailable in some environments.
    }
  }
}
