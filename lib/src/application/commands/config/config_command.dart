import 'package:args/command_runner.dart';
import 'package:cura/src/application/commands/config/config_get.dart';
import 'package:cura/src/application/commands/config/config_init.dart';
import 'package:cura/src/application/commands/config/config_set.dart';
import 'package:cura/src/application/commands/config/config_show.dart';
import 'package:cura/src/domain/ports/config_repository.dart';

/// Parent command for all `cura config` sub-commands.
///
/// Delegates to four sub-commands:
///
/// | Sub-command | Description                                       |
/// |-------------|---------------------------------------------------|
/// | `show`      | Print all active configuration values             |
/// | `get`       | Print the value of a single configuration key     |
/// | `set`       | Update a single configuration key                 |
/// | `init`      | Create the global config file with defaults       |
///
/// Usage:
/// ```
/// cura config show
/// cura config get min_score
/// cura config set theme light
/// cura config init [--force]
/// ```
class ConfigCommand extends Command<int> {
  /// Creates the command and registers all sub-commands.
  ///
  /// [configRepository] is forwarded to every sub-command so that they all
  /// operate on the same repository instance.
  ConfigCommand({required ConfigRepository configRepository}) {
    addSubcommand(ConfigShowCommand(configRepository: configRepository));
    addSubcommand(ConfigSetCommand(configRepository: configRepository));
    addSubcommand(ConfigGetCommand(configRepository: configRepository));
    addSubcommand(ConfigInitCommand(configRepository: configRepository));
  }

  @override
  String get name => 'config';

  @override
  String get description => 'Read and write Cura configuration.';
}
