import 'package:args/command_runner.dart';
import 'package:cura/src/domain/ports/config_repository.dart';

/// Subcommand : cura config show
class ConfigShowCommand extends Command<int> {
  final ConfigRepository _configRepository;

  ConfigShowCommand({required ConfigRepository configRepository}) : _configRepository = configRepository;

  @override
  String get name => 'show';

  @override
  String get description => 'Show current configuration';

  @override
  Future<int> run() async {
    final config = await _configRepository.load();

    print('Configuration:');
    print('  Theme: ${config.theme}');
    print('  Colors: ${config.useColors}');
    print('  Emojis: ${config.useEmojis}');
    print('  Min Score: ${config.minScore}');
    print('  Cache TTL: ${config.cacheMaxAgeHours}h');
    print('  Max Concurrency: ${config.maxConcurrency}');
    print('  GitHub Token: ${config.githubToken != null ? "✓ Set" : "✗ Not set"}');

    return 0;
  }
}
