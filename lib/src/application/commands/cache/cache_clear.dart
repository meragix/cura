import 'package:args/command_runner.dart';
import 'package:cura/src/infrastructure/cache/json_file_system_cache.dart';
import 'package:cura/src/presentation/loggers/console_logger.dart';

/// Sub-command: `cura cache clear`
///
/// Prompts the user for confirmation and then deletes every JSON entry in
/// every cache namespace via [JsonFileSystemCache.clearAll].
///
/// ### Behaviour
/// - Prints a confirmation prompt before acting (defaults to **no**).
/// - Cancels silently when the user declines.
/// - Exits with code `1` when the cache operation fails.
class CacheClearCommand extends Command<int> {
  final ConsoleLogger _logger;
  final JsonFileSystemCache _cache;

  /// Creates a [CacheClearCommand].
  CacheClearCommand({
    required ConsoleLogger logger,
    required JsonFileSystemCache cache,
  })  : _logger = logger,
        _cache = cache;

  @override
  String get name => 'clear';

  @override
  String get description => 'Clear all cache entries';

  @override
  Future<int> run() async {
    _logger.spacer();

    if (!_logger.confirm('Clear all cache?', defaultValue: false)) {
      _logger.info('Cancelled');
      return 0;
    }

    _logger.info('Clearing cache...');

    try {
      await _cache.clearAll();
      _logger.success('Cache cleared');
      _logger.spacer();
      return 0;
    } catch (e) {
      _logger.error('Failed to clear cache: $e');
      return 1;
    }
  }
}
