import 'package:args/command_runner.dart';
import 'package:cura/src/domain/ports/config_repository.dart';

/// Sub-command: `cura config set <key> <value>`
///
/// Updates a single configuration value in the **project** config file
/// (`./.cura/config.yaml`), creating it if it does not already exist.
///
/// Both `snake_case` and `camelCase` key variants are accepted:
/// ```sh
/// cura config set min_score 80
/// cura config set minScore 80          # equivalent
/// cura config set github_token ghp_…
/// cura config set theme light
/// cura config set fail_on_vulnerable false
/// ```
///
/// The string [value] is coerced to the correct Dart type before being
/// written: `"true"` / `"false"` → [bool], an integer string → [int],
/// everything else → [String].
///
/// Exits with code `0` on success, `1` on error.
class ConfigSetCommand extends Command<int> {
  final ConfigRepository _configRepository;

  /// Creates the sub-command backed by [configRepository].
  ConfigSetCommand({required ConfigRepository configRepository})
      : _configRepository = configRepository;

  @override
  String get name => 'set';

  @override
  String get description => 'Set a configuration value.';

  @override
  String get invocation => 'cura config set <key> <value>';

  @override
  Future<int> run() async {
    if (argResults!.rest.length < 2) {
      print('Error: missing key or value.');
      print('Usage: $invocation');
      return 1;
    }

    final key = argResults!.rest[0];
    final value = argResults!.rest[1];

    try {
      await _configRepository.updateKey(key, _parseValue(value));
      print('✓ $key = $value');
      return 0;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }

  /// Coerces [value] from a CLI string to the most appropriate Dart type.
  ///
  /// Conversion priority:
  /// 1. `"true"` / `"false"` (case-insensitive) → [bool]
  /// 2. Integer string → [int]
  /// 3. Anything else → [String]
  dynamic _parseValue(String value) {
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;

    final intValue = int.tryParse(value);
    if (intValue != null) return intValue;

    return value;
  }
}
