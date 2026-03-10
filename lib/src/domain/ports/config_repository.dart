import 'package:cura/src/infrastructure/config/models/cura_config.dart';

/// Port: persistence contract for Cura's configuration.
///
/// Implementations must apply the standard resolution order when reading:
/// 1. Project config   (`./.cura/config.yaml`)
/// 2. Global config    (`~/.cura/config.yaml`)
/// 3. Built-in defaults (see `ConfigDefaults.defaultConfig`)
///
/// Write operations ([save], [setValue]) always target the **project** config
/// file so that runtime changes are scoped to the current repository and do
/// not silently affect the user's global settings.
abstract class ConfigRepository {
  /// Returns the fully-merged [CuraConfig] for the current session.
  ///
  /// The result is a snapshot: subsequent calls may return different values if
  /// the underlying files are modified between calls.
  Future<CuraConfig> load();

  /// Persists [config] to the project-level config file as a human-readable
  /// YAML document.
  ///
  /// The parent directory is created automatically if it does not exist.
  Future<void> save(CuraConfig config);

  /// Returns `true` when at least one config file (global or project) exists
  /// on disk.
  Future<bool> exists();

  /// Writes the default global config file (`~/.cura/config.yaml`).
  ///
  /// When [force] is `false` (the default), the method is a no-op if the file
  /// already exists.  Set [force] to `true` to overwrite an existing file with
  /// the built-in defaults.
  Future<void> createDefault({bool force = false});

  /// Reads a single configuration value by [key].
  ///
  /// [key] may be either `snake_case` (as used in YAML files) or `camelCase`
  /// (as used in Dart code).  Returns `null` when the key is not recognised.
  ///
  /// Example:
  /// ```dart
  /// final theme = await repo.getValue<String>('theme');
  /// final score = await repo.getValue<int>('min_score');
  /// ```
  Future<T?> getValue<T>(String key);

  /// Writes a single configuration value identified by [key].
  ///
  /// [key] may be either `snake_case` or `camelCase`.  Unknown keys are
  /// silently ignored — the config is saved unchanged.  Use [getValue] to
  /// verify that the key was recognised after a [setValue] call.
  ///
  /// Throws a [TypeError] when [value] cannot be cast to the field's expected
  /// type (e.g. passing a [String] for a boolean field).
  Future<void> setValue(String key, dynamic value);
}
