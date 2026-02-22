import 'package:args/command_runner.dart';
import 'package:cura/src/domain/ports/config_repository.dart';

/// Sub-command: `cura config get <key>`
///
/// Prints the current value of a single configuration key from the merged
/// config (project → global → defaults).
///
/// Both `snake_case` and `camelCase` key variants are accepted:
/// ```sh
/// cura config get min_score      # → 70
/// cura config get theme          # → dark
/// cura config get github_token   # → (not set)
/// ```
///
/// Exits with code `0` on success, `1` on error.
class ConfigGetCommand extends Command<int> {
  final ConfigRepository _configRepository;

  /// Creates the sub-command backed by [configRepository].
  ConfigGetCommand({required ConfigRepository configRepository})
      : _configRepository = configRepository;

  @override
  String get name => 'get';

  @override
  String get description => 'Print the value of a configuration key.';

  @override
  String get invocation => 'cura config get <key>';

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      print('Error: missing key.');
      print('Usage: $invocation');
      return 1;
    }

    final key = argResults!.rest.first;

    try {
      final value = await _configRepository.getValue(key);
      // Print a human-readable placeholder for null (e.g. optional token).
      print(value ?? '(not set)');
      return 0;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
