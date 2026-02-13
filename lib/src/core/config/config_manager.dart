import 'dart:io';

import 'package:cura/src/core/config/cura_config.dart';
import 'package:cura/src/core/constants.dart';
import 'package:cura/src/core/error/exception.dart';
import 'package:cura/src/core/helper/utils.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

class ConfigManager {
  static CuraConfig? _cachedConfig;

  /// Charge la configuration
  static CuraConfig load() {
    if (_cachedConfig != null) return _cachedConfig!;

    try {
      final configFile = _getConfigFile();

      if (!configFile.existsSync()) {
        // Créer la config par défaut
        _cachedConfig = CuraConfig.defaultConfig();
        save(_cachedConfig!);
        return _cachedConfig!;
      }

      final yamlString = configFile.readAsStringSync();
      final yaml = loadYaml(yamlString) as YamlMap;

      _cachedConfig = CuraConfig.fromYaml(yaml);

      // Valider la config
      validate(_cachedConfig!);

      return _cachedConfig!;
    } catch (e) {
      print('Warning: Failed to load config, using defaults: $e');
      _cachedConfig = CuraConfig.defaultConfig();
      return _cachedConfig!;
    }
  }

  /// Sauvegarde la configuration
  static void save(CuraConfig config) {
    try {
      final configFile = _getConfigFile();
      final configDir = configFile.parent;

      if (!configDir.existsSync()) {
        configDir.createSync(recursive: true);
      }

      configFile.writeAsStringSync(config.toYamlString());
      _cachedConfig = config;
    } catch (e) {
      throw ConfigException('Failed to save config: $e');
    }
  }

  /// Reset à la config par défaut
  static void reset() {
    final config = CuraConfig.defaultConfig();
    save(config);
  }

  /// Vérifie si le fichier de config existe
  static bool exists() {
    return _getConfigFile().existsSync();
  }

  /// Retourne le chemin du fichier de config
  static String getConfigPath() {
    return _getConfigFile().path;
  }

  /// Ouvre le fichier de config dans l'éditeur
  static void edit() {
    final configPath = getConfigPath();

    // Créer le fichier s'il n'existe pas
    if (!exists()) {
      save(CuraConfig.defaultConfig());
    }

    // Essayer d'ouvrir avec l'éditeur par défaut
    final editors = [
      Platform.environment['EDITOR'],
      'code', // VS Code
      'nano',
      'vim',
      'vi',
    ].whereType<String>();

    for (final editor in editors) {
      try {
        Process.runSync(editor, [configPath], runInShell: true);
        return;
      } catch (e) {
        continue;
      }
    }

    print('Could not open editor. Edit manually: $configPath');
  }

  /// Valide la configuration
  static void validate(CuraConfig config) {
    final errors = <String>[];

    // Valider les poids du score
    if (!config.scoreWeights.isValid) {
      errors.add('Score weights must sum to 100');
    }

    // Valider le min_score
    if (config.minScore < 0 || config.minScore > 100) {
      errors.add('min_score must be between 0 and 100');
    }

    // Valider le thème
    final validThemes = ['dark', 'light', 'minimal', 'dracula'];
    if (!validThemes.contains(config.theme)) {
      errors.add(
          'Invalid theme: ${config.theme}. Valid: ${validThemes.join(", ")}');
    }

    if (errors.isNotEmpty) {
      throw ConfigException(
          'Invalid config:\n${errors.map((e) => '  - $e').join('\n')}');
    }
  }

  /// Retourne le fichier de config
  static File _getConfigFile() {
    final home = HelperUtils.getHomeDirectory();
    final configDir = path.join(home, CuraConstants.curaDirName);
    return File(path.join(configDir, CuraConstants.configFileName));
  }

  /// Invalide le cache
  static void invalidateCache() {
    _cachedConfig = null;
  }
}
