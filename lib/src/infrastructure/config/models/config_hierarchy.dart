import 'package:cura/src/infrastructure/config/models/cura_config.dart';

/// Which configuration scope to read or display.
enum ConfigScope {
  /// Global config only (`~/.cura/config.yaml`).
  global,

  /// Project config only (`./.cura/config.yaml`).
  project,

  /// Merged result: project overrides global overrides defaults.
  merged,
}

/// Snapshot of the entire configuration hierarchy at a point in time.
///
/// Used by the `cura config` command to display where each value comes from
/// and which project settings override the global defaults.
class ConfigHierarchy {
  /// Absolute path to the global config file.
  final String globalPath;

  /// Absolute path to the project config file.
  final String projectPath;

  /// Whether a global config file exists on disk.
  final bool hasGlobal;

  /// Whether a project config file exists on disk.
  final bool hasProject;

  /// Parsed global config, or `null` if the file does not exist.
  final CuraConfig? global;

  /// Parsed project config, or `null` if the file does not exist.
  final CuraConfig? project;

  /// Fully merged config (project → global → defaults).
  final CuraConfig merged;

  ConfigHierarchy({
    required this.globalPath,
    required this.projectPath,
    required this.hasGlobal,
    required this.hasProject,
    this.global,
    this.project,
    required this.merged,
  });

  /// Returns the list of fields where the project config explicitly differs
  /// from the global config.
  ///
  /// Returns an empty list when no project config is loaded or when there is
  /// no global config to compare against.
  List<ConfigOverride> getOverrides() {
    if (!hasProject || project == null || global == null) return const [];

    final g = global!;
    final p = project!;
    final overrides = <ConfigOverride>[];

    void check(String key, Object gVal, Object pVal) {
      if (gVal != pVal) {
        overrides.add(
          ConfigOverride(
            key: key,
            globalValue: gVal.toString(),
            projectValue: pVal.toString(),
          ),
        );
      }
    }

    check('theme', g.theme, p.theme);
    check('min_score', g.minScore, p.minScore);
    check('use_colors', g.useColors, p.useColors);
    check('use_emojis', g.useEmojis, p.useEmojis);
    check('cache_max_age_hours', g.cacheMaxAgeHours, p.cacheMaxAgeHours);
    check('enable_cache', g.enableCache, p.enableCache);
    check('max_concurrency', g.maxConcurrency, p.maxConcurrency);
    check('timeout_seconds', g.timeoutSeconds, p.timeoutSeconds);
    check('max_retries', g.maxRetries, p.maxRetries);
    check('auto_update', g.autoUpdate, p.autoUpdate);
    check('fail_on_vulnerable', g.failOnVulnerable, p.failOnVulnerable);
    check('fail_on_discontinued', g.failOnDiscontinued, p.failOnDiscontinued);
    check('show_suggestions', g.showSuggestions, p.showSuggestions);

    return overrides;
  }
}

/// A single field that differs between the global and project configs.
class ConfigOverride {
  final String key;
  final String globalValue;
  final String projectValue;

  const ConfigOverride({
    required this.key,
    required this.globalValue,
    required this.projectValue,
  });
}
