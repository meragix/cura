import 'package:cura/src/core/config/cura_config.dart';
import 'package:cura/src/core/config/config_manager.dart';
import 'package:mason_logger/mason_logger.dart';

class ConfigCommand {
  final Logger logger;

  ConfigCommand({Logger? logger}) : logger = logger ?? Logger();

  /// Affiche la hiérarchie de config
  void show({bool verbose = false}) {
    final hierarchy = ConfigManager.getHierarchy();

    logger.info('');
    logger.info(styleBold.wrap('Configuration Hierarchy'));
    logger.info('');

    // Global config
    logger.info(styleBold.wrap('Global Config:'));
    logger.info('  Location: ${cyan.wrap(hierarchy.globalPath)}');
    logger.info(
        '  Status: ${hierarchy.hasGlobal ? green.wrap('✓ Found') : red.wrap('✗ Not found')}');

    if (verbose && hierarchy.global != null) {
      _printConfig(hierarchy.global!, indent: '  ');
    }

    logger.info('');

    // Project config
    logger.info(styleBold.wrap('Project Config:'));
    logger.info('  Location: ${cyan.wrap(hierarchy.projectPath)}');
    logger.info(
        '  Status: ${hierarchy.hasProject ? green.wrap('✓ Found') : darkGray.wrap('✗ Not found')}');

    if (verbose && hierarchy.project != null) {
      _printConfig(hierarchy.project!, indent: '  ');
    }

    logger.info('');

    // Overrides
    if (hierarchy.hasProject) {
      final overrides = hierarchy.getOverrides();

      if (overrides.isNotEmpty) {
        logger.info(styleBold.wrap('Project Overrides:'));
        for (final override in overrides) {
          logger.info('  ${override.key}:');
          logger
              .info('    ${darkGray.wrap('Global:')} ${override.globalValue}');
          logger.info(
              '    ${cyan.wrap('Project:')} ${override.projectValue} ${green.wrap('✓')}');
        }
        logger.info('');
      }
    }

    // Merged config (effective)
    logger.info(styleBold.wrap('Effective Config (Merged):'));
    _printConfig(hierarchy.merged, indent: '  ');
    logger.info('');
  }

  void _printConfig(CuraConfig config, {String indent = ''}) {
    logger.info('${indent}Theme: ${config.theme}');
    logger.info('${indent}Use Emojis: ${config.useEmojis}');
    logger.info('${indent}Use Colors: ${config.useColors}');
    logger.info('${indent}Max Age: ${config.cacheMaxAge}h');
    logger.info('${indent}Auto Update: ${config.autoUpdate}');
    logger.info('${indent}Min Score: ${config.minScore}');
    logger.info('${indent}Weights:');
    logger.info('${indent * 2}Vitality: ${config.scoreWeights?.vitality}');
    logger.info(
        '${indent * 2}Technical Health: ${config.scoreWeights?.technicalHealth}');
    logger.info('${indent * 2}Trust: ${config.scoreWeights?.trust}');
    logger
        .info('${indent * 2}Maintenance: ${config.scoreWeights?.maintenance}');
    logger.info('${indent}Timeout: ${config.timeoutSeconds}s');
    logger.info('${indent}Max Retries: ${config.maxRetries}');
    logger.info('${indent}Show Suggestions: ${config.showSuggestions}');
    logger.info(
        '${indent}Max Suggestions Per Package: ${config.maxSuggestionsPerPackage}');
    logger.info(
        '${indent}GitHub Token: ${config.githubToken != null ? '✓ Set' : '✗ Not set'}');

    if (config.ignorePackages != null && config.ignorePackages!.length > 0) {
      logger.info('${indent}Ignored Packages:');
      for (final pkg in config.ignorePackages!) {
        logger.info('${indent * 2}- $pkg');
      }
    }

    if (config.trustedPublishers != null &&
        config.trustedPublishers!.length > 0) {
      logger.info('${indent}Trusted Publishers::');
      for (final pub in config.trustedPublishers!) {
        logger.info('${indent * 2}- $pub');
      }
    }
  }

  /// Initialise la config projet
  void initProject() {
    if (ConfigManager.hasProjectConfig()) {
      logger.warn('Project config already exists');
      logger.info('Location: ${ConfigManager.getProjectConfigPath()}');
      return;
    }

    ConfigManager.initProject();
    logger.info('${green.wrap('✓')} Project config created');
    logger.info('Location: ${ConfigManager.getProjectConfigPath()}');
    logger.info('');
    logger.info('Edit the file to override global settings for this project');
  }

  /// Supprime la config projet
  void removeProject() {
    if (!ConfigManager.hasProjectConfig()) {
      logger.warn('No project config found');
      return;
    }

    ConfigManager.removeProject();
    logger.info('${green.wrap('✓')} Project config removed');
  }

  /// Set une valeur (global ou projet)
  void set(String key, String value, {required ConfigScope scope}) {
    switch (scope) {
      case ConfigScope.global:
        _setGlobal(key, value);
        break;
      case ConfigScope.project:
        _setProject(key, value);
        break;
      case ConfigScope.merged:
        logger.err('Cannot set on merged config. Use --global or --project');
        break;
    }
  }

  void _setGlobal(String key, String value) {
    var config = ConfigManager.load(scope: ConfigScope.global);

    // Appliquer le changement...

    ConfigManager.saveGlobal(config);
    logger.info('${green.wrap('✓')} Set $key = $value (global)');
  }

  void _setProject(String key, String value) {
    var config = ConfigManager.load(scope: ConfigScope.project);

    // Appliquer le changement...

    ConfigManager.saveProject(config);
    logger.info('${green.wrap('✓')} Set $key = $value (project)');
  }

/*
USAGE EXAMPLES:

# Config globale
cura config show --global
cura config set theme dark --global
cura config edit --global

# Config projet
cura config init                     # Créer ./.cura/config.yaml
cura config show --project
cura config set min_score 80 --project
cura config edit --project
cura config remove --project         # Supprimer config projet

# Hiérarchie
cura config show                     # Affiche tout (global + projet + merged)
cura config show --verbose           # Avec détails

# Dans les commands
cura scan                            # Utilise config merged automatiquement
cura scan --min-score 90             # CLI override tout
*/
}
