import 'package:args/command_runner.dart';
import 'package:cura/src/domain/ports/config_repository.dart';

/// Sub-command: `cura config show`
///
/// Prints all active configuration values, grouped by category.  The displayed
/// values reflect the **merged** result of the global config
/// (`~/.cura/config.yaml`) overridden by the project config
/// (`./.cura/config.yaml`), which in turn falls back to built-in defaults.
///
/// Example output:
/// ```
/// Active configuration (merged):
///
///   [Appearance]
///     theme:                       dark
///     use_colors:                  true
///     use_emojis:                  true
///
///   [Cache]
///     cache_max_age_hours:         24
///     enable_cache:                true
///     auto_update:                 false
///   ...
/// ```
class ConfigShowCommand extends Command<int> {
  final ConfigRepository _configRepository;

  /// Creates the sub-command backed by [configRepository].
  ConfigShowCommand({required ConfigRepository configRepository})
      : _configRepository = configRepository;

  @override
  String get name => 'show';

  @override
  String get description => 'Print all active configuration values.';

  @override
  Future<int> run() async {
    final config = await _configRepository.load();

    print('Active configuration (merged):');
    print('');

    // ── Appearance ─────────────────────────────────────────────────────────
    print('  [Appearance]');
    _row('theme', config.theme);
    _row('use_colors', config.useColors);
    _row('use_emojis', config.useEmojis);
    print('');

    // ── Cache ───────────────────────────────────────────────────────────────
    print('  [Cache]');
    _row('cache_max_age_hours', '${config.cacheMaxAgeHours}h');
    _row('enable_cache', config.enableCache);
    _row('auto_update', config.autoUpdate);
    print('');

    // ── Scoring ─────────────────────────────────────────────────────────────
    print('  [Scoring]');
    _row('min_score', config.minScore);
    _row('score_weights.vitality', config.scoreWeights.vitality);
    _row('score_weights.technical_health', config.scoreWeights.technicalHealth);
    _row('score_weights.trust', config.scoreWeights.trust);
    _row('score_weights.maintenance', config.scoreWeights.maintenance);
    if (!config.scoreWeights.isValid) {
      print(
        '    Warning: score_weights do not sum to 100 '
        '(current total: ${config.scoreWeights.total})',
      );
    }
    print('');

    // ── Performance ─────────────────────────────────────────────────────────
    print('  [Performance]');
    _row('max_concurrency', config.maxConcurrency);
    _row('timeout_seconds', config.timeoutSeconds);
    _row('max_retries', config.maxRetries);
    print('');

    // ── Behaviour ───────────────────────────────────────────────────────────
    print('  [Behaviour]');
    _row('fail_on_vulnerable', config.failOnVulnerable);
    _row('fail_on_discontinued', config.failOnDiscontinued);
    _row('show_suggestions', config.showSuggestions);
    _row('max_suggestions_per_package', config.maxSuggestionsPerPackage);
    print('');

    // ── Logging ─────────────────────────────────────────────────────────────
    print('  [Logging]');
    _row('verbose_logging', config.verboseLogging);
    _row('quiet', config.quiet);
    print('');

    // ── API ─────────────────────────────────────────────────────────────────
    print('  [API]');
    _row(
      'github_token',
      config.githubToken != null ? '✓ set' : '✗ not set',
    );
    print('');

    // ── Exclusions ──────────────────────────────────────────────────────────
    print('  [Exclusions]');
    if (config.ignoredPackages.isEmpty) {
      _row('ignore_packages', '(none)');
    } else {
      for (final pkg in config.ignoredPackages) {
        print('    - $pkg');
      }
    }
    if (config.trustedPublishers.isEmpty) {
      _row('trusted_publishers', '(none)');
    } else {
      for (final pub in config.trustedPublishers) {
        print('    - $pub');
      }
    }

    return 0;
  }

  /// Prints a key-value row with fixed-width key padding.
  void _row(String key, Object value) {
    print('    ${key.padRight(32)}$value');
  }
}
