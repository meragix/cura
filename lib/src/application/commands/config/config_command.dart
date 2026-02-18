import 'package:args/command_runner.dart';
import 'package:cura/src/application/commands/config/config_get.dart';
import 'package:cura/src/application/commands/config/config_init.dart';
import 'package:cura/src/application/commands/config/config_set.dart';
import 'package:cura/src/application/commands/config/config_show.dart';
import 'package:cura/src/domain/ports/config_repository.dart';

/// Command : cura config
///
/// Parent command pour toutes les sous-commandes config
class ConfigCommand extends Command<int> {
  ConfigCommand({required ConfigRepository configRepository}) {
    addSubcommand(ConfigShowCommand(configRepository: configRepository));
    addSubcommand(ConfigSetCommand(configRepository: configRepository));
    addSubcommand(ConfigGetCommand(configRepository: configRepository));
    addSubcommand(ConfigInitCommand(configRepository: configRepository));
  }

  @override
  String get name => 'config';

  @override
  String get description => 'Manage Cura configuration';
}
