// import 'dart:io';

// import 'package:cura/src/core/config/config_hierarchy.dart';
// import 'package:cura/src/infrastructure/config/models/cura_config.dart';
// import 'package:cura/src/core/constants.dart';
// import 'package:cura/src/domain/value_objects/exception.dart';
// import 'package:cura/src/core/helper/utils.dart';
// import 'package:path/path.dart' as path;
// import 'package:yaml/yaml.dart';

enum ConfigScope {
  /// Configuration globale (~/.cura/config.yaml)
  global,

  /// Configuration projet (./.cura/config.yaml)
  project,

  /// Configuration fusionnée (project > global > defaults)
  merged,
}

class ConfigManager {
//   static CuraConfig? _cachedGlobal;
//   static CuraConfig? _cachedProject;
//   static String? _lastProjectPath;

//   /// Charge la configuration selon le scope
//   static CuraConfig load({
//     ConfigScope scope = ConfigScope.merged,
//     String? projectPath,
//   }) {
//     switch (scope) {
//       case ConfigScope.global:
//         return _loadGlobal();

//       case ConfigScope.project:
//         return _loadProject(projectPath ?? Directory.current.path);

//       case ConfigScope.merged:
//         return _loadMerged(projectPath ?? Directory.current.path);
//     }
//   }

//   /// Charge la config globale (~/.cura/config.yaml)
//   static CuraConfig _loadGlobal() {
//     if (_cachedGlobal != null) return _cachedGlobal!;

//     try {
//       final configFile = _getGlobalConfigFile();

//       if (!configFile.existsSync()) {
//         // Créer config globale par défaut
//         _cachedGlobal = CuraConfig.defaultConfig();
//         saveGlobal(_cachedGlobal!);
//         return _cachedGlobal!;
//       }

//       final yamlString = configFile.readAsStringSync();
//       final yaml = loadYaml(yamlString) as YamlMap;

//       _cachedGlobal = CuraConfig.fromYaml(yaml);
//       return _cachedGlobal!;
//     } catch (e) {
//       print('Warning: Failed to load global config: $e');
//       _cachedGlobal = CuraConfig.defaultConfig();
//       return _cachedGlobal!;
//     }
//   }

//   /// Charge la config projet (./.cura/config.yaml)
//   static CuraConfig _loadProject(String projectPath) {
//     // Invalider le cache si le path a changé
//     if (_lastProjectPath != projectPath) {
//       _cachedProject = null;
//       _lastProjectPath = projectPath;
//     }

//     if (_cachedProject != null) return _cachedProject!;

//     try {
//       final configFile = _getProjectConfigFile(projectPath);

//       if (!configFile.existsSync()) {
//         // Pas de config projet → retourner config vide
//         return CuraConfig.empty();
//       }

//       final yamlString = configFile.readAsStringSync();
//       final yaml = loadYaml(yamlString) as YamlMap;

//       _cachedProject = CuraConfig.fromYaml(yaml);
//       return _cachedProject!;
//     } catch (e) {
//       print('Warning: Failed to load project config: $e');
//       return CuraConfig.empty();
//     }
//   }

//   /// Charge la config fusionnée (project overrides global)
//   static CuraConfig _loadMerged(String projectPath) {
//     final global = _loadGlobal();
//     final project = _loadProject(projectPath);

//     // Fusionner: project > global > defaults
//     return global.mergeWith(project);
//   }

//   /// Sauvegarde la config globale
//   static void saveGlobal(CuraConfig config) {
//     try {
//       final configFile = _getGlobalConfigFile();
//       final configDir = configFile.parent;

//       if (!configDir.existsSync()) {
//         configDir.createSync(recursive: true);
//       }

//       configFile.writeAsStringSync(config.toYamlString());
//       _cachedGlobal = config;
//     } catch (e) {
//       throw ConfigException('Failed to save global config: $e');
//     }
//   }

//   /// Sauvegarde la config projet
//   static void saveProject(CuraConfig config, [String? projectPath]) {
//     try {
//       projectPath ??= Directory.current.path;

//       final configFile = _getProjectConfigFile(projectPath);
//       final configDir = configFile.parent;

//       if (!configDir.existsSync()) {
//         configDir.createSync(recursive: true);
//       }

//       configFile.writeAsStringSync(config.toYamlString(isProject: true));
//       _cachedProject = config;
//       _lastProjectPath = projectPath;
//     } catch (e) {
//       throw ConfigException('Failed to save project config: $e');
//     }
//   }

//   /// Initialise la config projet depuis la globale
//   static void initProject([String? projectPath]) {
//     projectPath ??= Directory.current.path;

//     // Créer un fichier projet minimal qui override juste ce qui est nécessaire
//     final projectConfig = CuraConfig.projectTemplate();
//     saveProject(projectConfig, projectPath);
//   }

//   /// Vérifie si une config projet existe
//   static bool hasProjectConfig([String? projectPath]) {
//     projectPath ??= Directory.current.path;
//     return _getProjectConfigFile(projectPath).existsSync();
//   }

//   /// Retourne le chemin de la config globale
//   static String getGlobalConfigPath() {
//     return _getGlobalConfigFile().path;
//   }

//   /// Retourne le chemin de la config projet
//   static String getProjectConfigPath([String? projectPath]) {
//     projectPath ??= Directory.current.path;
//     return _getProjectConfigFile(projectPath).path;
//   }

//   /// Affiche la hiérarchie de config
//   static ConfigHierarchy getHierarchy([String? projectPath]) {
//     projectPath ??= Directory.current.path;

//     final hasGlobal = _getGlobalConfigFile().existsSync();
//     final hasProject = _getProjectConfigFile(projectPath).existsSync();

//     return ConfigHierarchy(
//       globalPath: getGlobalConfigPath(),
//       projectPath: getProjectConfigPath(projectPath),
//       hasGlobal: hasGlobal,
//       hasProject: hasProject,
//       global: hasGlobal ? _loadGlobal() : null,
//       project: hasProject ? _loadProject(projectPath) : null,
//       merged: _loadMerged(projectPath),
//     );
//   }

//   /// Supprime la config projet
//   static void removeProject([String? projectPath]) {
//     projectPath ??= Directory.current.path;

//     final configFile = _getProjectConfigFile(projectPath);
//     if (configFile.existsSync()) {
//       configFile.deleteSync();
//     }

//     final configDir = configFile.parent;
//     if (configDir.existsSync() && configDir.listSync().isEmpty) {
//       configDir.deleteSync();
//     }

//     _cachedProject = null;
//   }

//   /// Invalide tous les caches
//   static void invalidateCache() {
//     _cachedGlobal = null;
//     _cachedProject = null;
//     _lastProjectPath = null;
//   }

//   // Helpers privés
//   static File _getGlobalConfigFile() {
//     final home = HelperUtils.getHomeDirectory();
//     final configDir = path.join(home, CuraConstants.curaDirName);
//     return File(path.join(configDir, CuraConstants.configFileName));
//   }

//   static File _getProjectConfigFile(String projectPath) {
//     final configDir = path.join(projectPath, CuraConstants.curaDirName);
//     return File(path.join(configDir, CuraConstants.configFileName));
//   }
// }
}
