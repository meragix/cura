import 'package:args/command_runner.dart';
import 'package:cura/src/domain/ports/config_repository.dart';


class ConfigGetCommand extends Command<int> {
  final ConfigRepository _configRepository;

  ConfigGetCommand({required ConfigRepository configRepository})
      : _configRepository = configRepository;

  @override
  String get name => 'get';

  @override
  String get description => 'Get a configuration value';

  @override
  String get invocation => 'cura config get <key>';

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      print('Error: Missing key');
      print('Usage: $invocation');
      return 1;
    }

    final key = argResults!.rest.first;

    try {
      final value = await _configRepository.getValue(key);
      print(value ?? 'null');
      return 0;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
