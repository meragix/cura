import 'package:cura/src/infrastructure/config/models/cura_config.dart';

/// Port : Repository de configuration
abstract class ConfigRepository {
  /// Load merged config (global + project)
  Future<CuraConfig> load();

  /// Save config (project-level)
  Future<void> save(CuraConfig config);

  /// Check if config exists
  Future<bool> exists();

  /// Create default config
  Future<void> createDefault();

  /// Get specific value
  Future<T?> getValue<T>(String key);

  /// Set specific value
  Future<void> setValue(String key, dynamic value);
}
