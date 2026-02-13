import 'package:args/command_runner.dart';
import 'package:cura/src/commands/config_command.dart';

class ConfigCLICommand extends Command<int> {
  @override
  final name = 'config';

  @override
  final description = 'Manage Cura configuration';

  ConfigCLICommand() {
    addSubcommand(ConfigShowCommand());
    addSubcommand(ConfigEditCommand());
    addSubcommand(ConfigResetCommand());
    addSubcommand(ConfigSetCommand());
    addSubcommand(ConfigGetCommand());
    addSubcommand(ConfigValidateCommand());
  }

  @override
  Future<int> run() async => 0;
}

class ConfigShowCommand extends Command<int> {
  @override
  final name = 'show';

  @override
  final description = 'Show current configuration';

  @override
  Future<int> run() async {
    ConfigCommand().show();
    return 0;
  }
}

class ConfigEditCommand extends Command<int> {
  @override
  final name = 'edit';

  @override
  final description = 'Edit configuration in your editor';

  @override
  Future<int> run() async {
    ConfigCommand().edit();
    return 0;
  }
}

class ConfigResetCommand extends Command<int> {
  @override
  final name = 'reset';

  @override
  final description = 'Reset configuration to defaults';

  @override
  Future<int> run() async {
    ConfigCommand().reset();
    return 0;
  }
}

class ConfigSetCommand extends Command<int> {
  @override
  final name = 'set';

  @override
  final description = 'Set a configuration value';

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.length != 2) {
      print('Usage: cura config set <key> <value>');
      return 1;
    }

    ConfigCommand().set(args[0], args[1]);
    return 0;
  }
}

class ConfigGetCommand extends Command<int> {
  @override
  final name = 'get';

  @override
  final description = 'Get a configuration value';

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.length != 1) {
      print('Usage: cura config get <key>');
      return 1;
    }

    ConfigCommand().get(args[0]);
    return 0;
  }
}

class ConfigValidateCommand extends Command<int> {
  @override
  final name = 'validate';

  @override
  final description = 'Validate configuration file';

  @override
  Future<int> run() async {
    ConfigCommand().validate();
    return 0;
  }
}
