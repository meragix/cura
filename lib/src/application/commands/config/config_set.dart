import 'package:args/command_runner.dart';
import 'package:cura/src/domain/ports/config_repository.dart';

/// Subcommand : cura config set <key> <value>
class ConfigSetCommand extends Command<int> {
  final ConfigRepository _configRepository;

  ConfigSetCommand({required ConfigRepository configRepository}) : _configRepository = configRepository;

  @override
  String get name => 'set';

  @override
  String get description => 'Set a configuration value';

  @override
  String get invocation => 'cura config set <key> <value>';

  @override
  Future<int> run() async {
    if (argResults!.rest.length < 2) {
      print('Error: Missing key or value');
      print('Usage: $invocation');
      return 1;
    }

    final key = argResults!.rest[0];
    final value = argResults!.rest[1];

    try {
      await _configRepository.setValue(key, _parseValue(value));
      print('✓ Set $key = $value');
      return 0;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }

  dynamic _parseValue(String value) {
    // Try to parse as bool
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;

    // Try to parse as int
    final intValue = int.tryParse(value);
    if (intValue != null) return intValue;

    // Default to string
    return value;
  }
}
