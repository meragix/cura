import 'package:args/command_runner.dart';
import 'package:cura/src/domain/ports/config_repository.dart';

/// Sub-command: `cura config init [--force]`
///
/// Writes the global config file (`~/.cura/config.yaml`) populated with
/// built-in defaults so users have a ready-made template to customise.
///
/// By default this is a **safe** operation: if the file already exists the
/// command exits with a message and returns exit code `1`.  Pass `--force`
/// to overwrite an existing config with the defaults.
///
/// ```sh
/// cura config init            # create ~/.cura/config.yaml (safe)
/// cura config init --force    # overwrite any existing config
/// ```
///
/// Exits with code `0` on success, `1` when the file exists and `--force`
/// was not provided.
class ConfigInitCommand extends Command<int> {
  final ConfigRepository _configRepository;

  /// Creates the sub-command backed by [configRepository].
  ///
  /// Registers the `--force` / `-f` flag during construction.
  ConfigInitCommand({required ConfigRepository configRepository})
      : _configRepository = configRepository {
    argParser.addFlag(
      'force',
      abbr: 'f',
      negatable: false,
      help: 'Overwrite the existing config file with built-in defaults.',
    );
  }

  @override
  String get name => 'init';

  @override
  String get description =>
      'Create the global config file with built-in defaults.';

  @override
  Future<int> run() async {
    final force = argResults!['force'] as bool;

    if (!force && await _configRepository.exists()) {
      print(
        'Configuration already exists. '
        'Run with --force to overwrite.',
      );
      return 1;
    }

    await _configRepository.createDefault(force: force);
    print('✓ Configuration initialised at ~/.cura/config.yaml');
    return 0;
  }
}
