
import 'package:cura/src/core/config/config_manager.dart';
import 'package:cura/src/core/error/exception.dart';
import 'package:mason_logger/mason_logger.dart';

class ConfigCommand {
  final Logger logger;

  ConfigCommand({Logger? logger}) : logger = logger ?? Logger();

  /// Affiche la config actuelle
  void show() {
    final config = ConfigManager.load();
    
    logger.info('');
    logger.info(styleBold.wrap('Current Configuration'));
    logger.info('Location: ${cyan.wrap(ConfigManager.getConfigPath())}');
    logger.info('');
    
    logger.info(styleBold.wrap('Appearance:'));
    logger.info('  Theme: ${config.theme}');
    logger.info('  Use Emojis: ${config.useEmojis}');
    logger.info('  Use Colors: ${config.useColors}');
    logger.info('');
    
    logger.info(styleBold.wrap('Cache:'));
    logger.info('  Max Age: ${config.cacheMaxAge}h');
    logger.info('  Auto Update: ${config.autoUpdate}');
    logger.info('');
    
    logger.info(styleBold.wrap('Scoring:'));
    logger.info('  Min Score: ${config.minScore}');
    logger.info('  Weights:');
    logger.info('    Vitality: ${config.scoreWeights.vitality}');
    logger.info('    Technical Health: ${config.scoreWeights.technicalHealth}');
    logger.info('    Trust: ${config.scoreWeights.trust}');
    logger.info('    Maintenance: ${config.scoreWeights.maintenance}');
    logger.info('');
    
    logger.info(styleBold.wrap('API:'));
    logger.info('  Timeout: ${config.timeoutSeconds}s');
    logger.info('  Max Retries: ${config.maxRetries}');
    logger.info('  GitHub Token: ${config.githubToken != null ? '✓ Set' : '✗ Not set'}');
    logger.info('');
    
    if (config.ignorePackages.isNotEmpty) {
      logger.info(styleBold.wrap('Ignored Packages:'));
      for (final pkg in config.ignorePackages) {
        logger.info('  - $pkg');
      }
      logger.info('');
    }
    
    if (config.trustedPublishers.isNotEmpty) {
      logger.info(styleBold.wrap('Trusted Publishers:'));
      for (final pub in config.trustedPublishers) {
        logger.info('  - $pub');
      }
      logger.info('');
    }
  }

  /// Édite la config
  void edit() {
    ConfigManager.edit();
  }

  /// Reset la config
  void reset() {
    logger.info('Resetting configuration to defaults...');
    ConfigManager.reset();
    logger.info('${green.wrap('✓')} Configuration reset successfully');
    logger.info('Location: ${ConfigManager.getConfigPath()}');
  }

  /// Set une valeur
  void set(String key, String value) {
    var config = ConfigManager.load();
    
    config = switch (key) {
      'theme' => config.merge(theme: value),
      'use_emojis' => config.merge(useEmojis: value.toLowerCase() == 'true'),
      'use_colors' => config.merge(useColors: value.toLowerCase() == 'true'),
      'cache_max_age' => config.merge(cacheMaxAge: int.parse(value)),
      'auto_update' => config.merge(autoUpdate: value.toLowerCase() == 'true'),
      'min_score' => config.merge(minScore: int.parse(value)),
      'github_token' => config.merge(githubToken: value),
      'timeout_seconds' => config.merge(timeoutSeconds: int.parse(value)),
      'max_retries' => config.merge(maxRetries: int.parse(value)),
      'show_suggestions' => config.merge(showSuggestions: value.toLowerCase() == 'true'),
      _ => throw ConfigException('Unknown config key: $key'),
    };

    ConfigManager.save(config);
    logger.info('${green.wrap('✓')} Set $key = $value');
  }

  /// Get une valeur
  void get(String key) {
    final config = ConfigManager.load();
    
    final value = switch (key) {
      'theme' => config.theme,
      'use_emojis' => config.useEmojis.toString(),
      'use_colors' => config.useColors.toString(),
      'cache_max_age' => config.cacheMaxAge.toString(),
      'auto_update' => config.autoUpdate.toString(),
      'min_score' => config.minScore.toString(),
      'github_token' => config.githubToken ?? '(not set)',
      'timeout_seconds' => config.timeoutSeconds.toString(),
      'max_retries' => config.maxRetries.toString(),
      'show_suggestions' => config.showSuggestions.toString(),
      _ => throw ConfigException('Unknown config key: $key'),
    };

    logger.info('$key: $value');
  }

  /// Valide la config
  void validate() {
    try {
      final config = ConfigManager.load();
      ConfigManager.validate(config);
      logger.info('${green.wrap('✓')} Configuration is valid');
    } on ConfigException catch (e) {
      logger.err('${red.wrap('✗')} Invalid configuration:');
      logger.err(e.message);
    }
  }
}