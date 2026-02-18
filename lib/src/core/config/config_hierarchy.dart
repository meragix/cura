import 'package:cura/src/infrastructure/config/models/cura_config.dart';

/// Représente la hiérarchie de configuration
class ConfigHierarchy {
  final String globalPath;
  final String projectPath;
  final bool hasGlobal;
  final bool hasProject;
  final CuraConfig? global;
  final CuraConfig? project;
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

  /// Liste des overrides du projet
  List<ConfigOverride> getOverrides() {
    if (!hasProject || project == null || global == null) {
      return [];
    }

    final overrides = <ConfigOverride>[];

    if (project?.theme != null && project!.theme != global?.theme) {
      overrides.add(ConfigOverride(
        key: 'theme',
        globalValue: global!.theme!,
        projectValue: project!.theme!,
      ));
    }

    if (project?.minScore != null && project!.minScore != global?.minScore) {
      overrides.add(ConfigOverride(
        key: 'min_score',
        globalValue: global!.minScore.toString(),
        projectValue: project!.minScore!.toString(),
      ));
    }

    // Ajouter d'autres comparaisons si nécessaire

    return overrides;
  }
}

class ConfigOverride {
  final String key;
  final String globalValue;
  final String projectValue;

  ConfigOverride({
    required this.key,
    required this.globalValue,
    required this.projectValue,
  });
}
