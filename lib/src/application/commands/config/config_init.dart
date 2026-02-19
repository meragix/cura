import 'package:args/command_runner.dart';
import 'package:cura/src/domain/ports/config_repository.dart';

/// Subcommand : cura config init
class ConfigInitCommand extends Command<int> {
  final ConfigRepository _configRepository;

  ConfigInitCommand({required ConfigRepository configRepository})
      : _configRepository = configRepository;

  @override
  String get name => 'init';

  @override
  String get description => 'Initialize configuration with defaults';

  @override
  Future<int> run() async {
    if (await _configRepository.exists()) {
      print('Configuration already exists. Use --force to overwrite.');
      return 1;
    }

    await _configRepository.createDefault();
    print('✓ Configuration initialized');
    return 0;
  }
}
