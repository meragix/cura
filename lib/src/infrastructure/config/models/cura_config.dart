import 'package:cura/src/infrastructure/config/models/score_weights.dart';
import 'package:yaml/yaml.dart';

/// Fully-resolved, non-nullable configuration for a Cura session.
///
/// ## Hierarchy
///
/// Values are resolved in priority order (highest → lowest):
/// 1. CLI flags
/// 2. Project config (`./.cura/config.yaml`)
/// 3. Global config (`~/.cura/config.yaml`)
/// 4. Defaults (see [ConfigDefaults])
///
/// ## Parsing
///
/// - JSON round-trip (SQLite cache, inter-process): [fromJson] / [toJson]
/// - YAML files (human-editable configs):          [fromYaml] / [toYamlString]
///
/// ## Merging
///
/// Call [mergeWith] to overlay a project config on top of a global config.
/// Project values always win; [githubToken] falls back to the global value
/// if the project file does not declare one.
class CuraConfig {
  // ── Appearance ──────────────────────────────────────────────────────────────

  final String theme;
  final bool useColors;
  final bool useEmojis;

  // ── Cache ───────────────────────────────────────────────────────────────────

  final int cacheMaxAgeHours;
  final bool enableCache;

  // ── Performance ─────────────────────────────────────────────────────────────

  final int maxConcurrency;
  final int timeoutSeconds;

  /// Maximum number of retry attempts for failed HTTP requests.
  final int maxRetries;

  /// Whether to refresh the cache automatically in the background.
  final bool autoUpdate;

  // ── Scoring ─────────────────────────────────────────────────────────────────

  final int minScore;
  final ScoreWeights scoreWeights;

  // ── Behaviour ───────────────────────────────────────────────────────────────

  final bool showSuggestions;
  final int maxSuggestionsPerPackage;
  final bool failOnVulnerable;
  final bool failOnDiscontinued;

  // ── Exclusions ──────────────────────────────────────────────────────────────

  final List<String> ignoredPackages;
  final List<String> trustedPublishers;

  // ── Logging ─────────────────────────────────────────────────────────────────

  final bool verboseLogging;
  final bool quiet;

  // ── API ─────────────────────────────────────────────────────────────────────

  final String? githubToken;

  // ── Constructor ─────────────────────────────────────────────────────────────

  const CuraConfig({
    this.theme = 'dark',
    this.useColors = true,
    this.useEmojis = true,
    this.cacheMaxAgeHours = 24,
    this.enableCache = true,
    this.maxConcurrency = 5,
    this.timeoutSeconds = 10,
    this.maxRetries = 3,
    this.autoUpdate = false,
    this.minScore = 70,
    this.scoreWeights = const ScoreWeights(),
    this.showSuggestions = true,
    this.maxSuggestionsPerPackage = 3,
    this.failOnVulnerable = true,
    this.failOnDiscontinued = true,
    this.ignoredPackages = const [],
    this.trustedPublishers = const [],
    this.verboseLogging = false,
    this.quiet = false,
    this.githubToken,
  });

  // ── copyWith ─────────────────────────────────────────────────────────────────

  CuraConfig copyWith({
    String? theme,
    bool? useColors,
    bool? useEmojis,
    int? cacheMaxAgeHours,
    bool? enableCache,
    int? maxConcurrency,
    int? timeoutSeconds,
    int? maxRetries,
    bool? autoUpdate,
    int? minScore,
    ScoreWeights? scoreWeights,
    bool? showSuggestions,
    int? maxSuggestionsPerPackage,
    bool? failOnVulnerable,
    bool? failOnDiscontinued,
    List<String>? ignoredPackages,
    List<String>? trustedPublishers,
    bool? verboseLogging,
    bool? quiet,
    String? githubToken,
  }) {
    return CuraConfig(
      theme: theme ?? this.theme,
      useColors: useColors ?? this.useColors,
      useEmojis: useEmojis ?? this.useEmojis,
      cacheMaxAgeHours: cacheMaxAgeHours ?? this.cacheMaxAgeHours,
      enableCache: enableCache ?? this.enableCache,
      maxConcurrency: maxConcurrency ?? this.maxConcurrency,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      maxRetries: maxRetries ?? this.maxRetries,
      autoUpdate: autoUpdate ?? this.autoUpdate,
      minScore: minScore ?? this.minScore,
      scoreWeights: scoreWeights ?? this.scoreWeights,
      showSuggestions: showSuggestions ?? this.showSuggestions,
      maxSuggestionsPerPackage:
          maxSuggestionsPerPackage ?? this.maxSuggestionsPerPackage,
      failOnVulnerable: failOnVulnerable ?? this.failOnVulnerable,
      failOnDiscontinued: failOnDiscontinued ?? this.failOnDiscontinued,
      ignoredPackages: ignoredPackages ?? this.ignoredPackages,
      trustedPublishers: trustedPublishers ?? this.trustedPublishers,
      verboseLogging: verboseLogging ?? this.verboseLogging,
      quiet: quiet ?? this.quiet,
      githubToken: githubToken ?? this.githubToken,
    );
  }

  // ── Merge ────────────────────────────────────────────────────────────────────

  /// Returns a new config where every field is taken from [other] (typically
  /// the project config), with this config (typically global) as the fallback.
  ///
  /// The [githubToken] is the only field where the global value is preferred
  /// when [other] has none, because API tokens are usually stored globally.
  CuraConfig mergeWith(CuraConfig? other) {
    if (other == null) return this;
    return CuraConfig(
      theme: other.theme,
      useColors: other.useColors,
      useEmojis: other.useEmojis,
      cacheMaxAgeHours: other.cacheMaxAgeHours,
      enableCache: other.enableCache,
      maxConcurrency: other.maxConcurrency,
      timeoutSeconds: other.timeoutSeconds,
      maxRetries: other.maxRetries,
      autoUpdate: other.autoUpdate,
      minScore: other.minScore,
      scoreWeights: other.scoreWeights,
      showSuggestions: other.showSuggestions,
      maxSuggestionsPerPackage: other.maxSuggestionsPerPackage,
      failOnVulnerable: other.failOnVulnerable,
      failOnDiscontinued: other.failOnDiscontinued,
      ignoredPackages: other.ignoredPackages,
      trustedPublishers: other.trustedPublishers,
      verboseLogging: other.verboseLogging,
      quiet: other.quiet,
      githubToken: other.githubToken ?? githubToken,
    );
  }

  // ── JSON (cache / inter-process) ─────────────────────────────────────────────

  factory CuraConfig.fromJson(Map<String, dynamic> json) {
    return CuraConfig(
      theme: json['theme'] as String? ?? 'dark',
      useColors: json['useColors'] as bool? ?? true,
      useEmojis: json['useEmojis'] as bool? ?? true,
      cacheMaxAgeHours: json['cacheMaxAgeHours'] as int? ?? 24,
      enableCache: json['enableCache'] as bool? ?? true,
      maxConcurrency: json['maxConcurrency'] as int? ?? 5,
      timeoutSeconds: json['timeoutSeconds'] as int? ?? 10,
      maxRetries: json['maxRetries'] as int? ?? 3,
      autoUpdate: json['autoUpdate'] as bool? ?? false,
      minScore: json['minScore'] as int? ?? 70,
      scoreWeights: json['scoreWeights'] != null
          ? ScoreWeights.fromJson(
              json['scoreWeights'] as Map<String, dynamic>,
            )
          : const ScoreWeights(),
      showSuggestions: json['showSuggestions'] as bool? ?? true,
      maxSuggestionsPerPackage: json['maxSuggestionsPerPackage'] as int? ?? 3,
      failOnVulnerable: json['failOnVulnerable'] as bool? ?? true,
      failOnDiscontinued: json['failOnDiscontinued'] as bool? ?? true,
      ignoredPackages: (json['ignoredPackages'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      trustedPublishers: (json['trustedPublishers'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      verboseLogging: json['verboseLogging'] as bool? ?? false,
      quiet: json['quiet'] as bool? ?? false,
      githubToken: json['githubToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'useColors': useColors,
      'useEmojis': useEmojis,
      'cacheMaxAgeHours': cacheMaxAgeHours,
      'enableCache': enableCache,
      'maxConcurrency': maxConcurrency,
      'timeoutSeconds': timeoutSeconds,
      'maxRetries': maxRetries,
      'autoUpdate': autoUpdate,
      'minScore': minScore,
      'scoreWeights': scoreWeights.toJson(),
      'showSuggestions': showSuggestions,
      'maxSuggestionsPerPackage': maxSuggestionsPerPackage,
      'failOnVulnerable': failOnVulnerable,
      'failOnDiscontinued': failOnDiscontinued,
      'ignoredPackages': ignoredPackages,
      'trustedPublishers': trustedPublishers,
      'verboseLogging': verboseLogging,
      'quiet': quiet,
      'githubToken': githubToken,
    };
  }

  // ── YAML (human-editable config files) ───────────────────────────────────────

  /// Parses a [CuraConfig] from a YAML mapping.
  ///
  /// YAML keys use `snake_case` (conventional for YAML files).
  /// Unknown keys are silently ignored, and missing keys fall back to defaults,
  /// so config files only need to declare the values they want to override.
  factory CuraConfig.fromYaml(Map yaml) {
    Map<String, dynamic>? weightsMap;
    if (yaml['score_weights'] is Map) {
      weightsMap = (yaml['score_weights'] as Map).map(
        (k, v) => MapEntry(k.toString(), v),
      );
    }

    List<String> _list(dynamic raw) =>
        (raw is YamlList) ? raw.map((e) => e.toString()).toList() : const [];

    return CuraConfig(
      theme: yaml['theme'] as String? ?? 'dark',
      useColors: yaml['use_colors'] as bool? ?? true,
      useEmojis: yaml['use_emojis'] as bool? ?? true,
      cacheMaxAgeHours:
          (yaml['cache_max_age_hours'] ?? yaml['cache_max_age']) as int? ?? 24,
      enableCache: yaml['enable_cache'] as bool? ?? true,
      maxConcurrency: yaml['max_concurrency'] as int? ?? 5,
      timeoutSeconds: yaml['timeout_seconds'] as int? ?? 10,
      maxRetries: yaml['max_retries'] as int? ?? 3,
      autoUpdate: yaml['auto_update'] as bool? ?? false,
      minScore: yaml['min_score'] as int? ?? 70,
      scoreWeights: weightsMap != null
          ? ScoreWeights(
              vitality: weightsMap['vitality'] as int? ?? 40,
              technicalHealth: (weightsMap['technical_health'] ??
                      weightsMap['technicalHealth']) as int? ??
                  30,
              trust: weightsMap['trust'] as int? ?? 20,
              maintenance: weightsMap['maintenance'] as int? ?? 10,
            )
          : const ScoreWeights(),
      showSuggestions: yaml['show_suggestions'] as bool? ?? true,
      maxSuggestionsPerPackage:
          yaml['max_suggestions_per_package'] as int? ?? 3,
      failOnVulnerable: yaml['fail_on_vulnerable'] as bool? ?? true,
      failOnDiscontinued: yaml['fail_on_discontinued'] as bool? ?? true,
      ignoredPackages: _list(yaml['ignore_packages']),
      trustedPublishers: _list(yaml['trusted_publishers']),
      verboseLogging: yaml['verbose_logging'] as bool? ?? false,
      quiet: yaml['quiet'] as bool? ?? false,
      githubToken: yaml['github_token'] as String?,
    );
  }

  /// Serialises the config to a commented YAML string suitable for writing
  /// to a config file.
  ///
  /// Pass `isProject: true` to emit only the fields commonly overridden at
  /// the project level (producing a leaner `.cura/config.yaml`).
  String toYamlString({bool isProject = false}) {
    return isProject ? _toProjectYaml() : _toGlobalYaml();
  }

  String _toGlobalYaml() {
    final ignorePkgLines = ignoredPackages.isEmpty
        ? '  # - example_package'
        : ignoredPackages.map((p) => '  - $p').join('\n');

    final trustedPubLines = trustedPublishers.isEmpty
        ? '  # - dart.dev\n  # - flutter.dev'
        : trustedPublishers.map((p) => '  - $p').join('\n');

    final tokenLine = githubToken != null
        ? 'github_token: $githubToken'
        : '# github_token: ghp_your_token_here';

    return '''
# Cura Configuration File
# Global config at: ~/.cura/config.yaml

# =============================================================================
# APPEARANCE
# =============================================================================
theme: $theme                         # dark | light | minimal
use_emojis: $useEmojis                # Show emojis in output
use_colors: $useColors                # Enable coloured output

# =============================================================================
# CACHE
# =============================================================================
cache_max_age_hours: $cacheMaxAgeHours  # Cache TTL in hours
enable_cache: $enableCache
auto_update: $autoUpdate              # Refresh cache in background

# =============================================================================
# SCORING
# =============================================================================
min_score: $minScore                  # Minimum acceptable score (CI/CD gate)

# Custom dimension weights — must sum to 100
score_weights:
  vitality: ${scoreWeights.vitality}              # Release recency (0–40)
  technical_health: ${scoreWeights.technicalHealth}    # Pana/null-safety/Dart3 (0–30)
  trust: ${scoreWeights.trust}                 # Popularity, likes (0–20)
  maintenance: ${scoreWeights.maintenance}           # Publisher, Flutter Fav (0–10)

# =============================================================================
# PERFORMANCE
# =============================================================================
max_concurrency: $maxConcurrency      # Parallel API requests
timeout_seconds: $timeoutSeconds      # HTTP timeout per request
max_retries: $maxRetries              # Retry attempts on failure

# =============================================================================
# BEHAVIOUR
# =============================================================================
fail_on_vulnerable: $failOnVulnerable
fail_on_discontinued: $failOnDiscontinued
show_suggestions: $showSuggestions
max_suggestions_per_package: $maxSuggestionsPerPackage

# =============================================================================
# API
# =============================================================================
# GitHub Personal Access Token (raises rate limit from 60 → 5 000 req/hr)
# Create one at: https://github.com/settings/tokens
$tokenLine

# =============================================================================
# EXCLUSIONS
# =============================================================================
ignore_packages:
$ignorePkgLines

trusted_publishers:
$trustedPubLines
''';
  }

  String _toProjectYaml() {
    final buf = StringBuffer();

    buf.writeln('# Cura Project Configuration');
    buf.writeln('# Overrides ~/.cura/config.yaml for this project only.');
    buf.writeln('');
    buf.writeln(
      '# =============================================================================',
    );
    buf.writeln('# PROJECT OVERRIDES');
    buf.writeln(
      '# =============================================================================',
    );
    buf.writeln('');
    buf.writeln('min_score: $minScore');
    buf.writeln('');

    if (ignoredPackages.isNotEmpty) {
      buf.writeln('ignore_packages:');
      for (final pkg in ignoredPackages) {
        buf.writeln('  - $pkg');
      }
      buf.writeln('');
    }

    if (trustedPublishers.isNotEmpty) {
      buf.writeln('trusted_publishers:');
      for (final pub in trustedPublishers) {
        buf.writeln('  - $pub');
      }
      buf.writeln('');
    }

    buf.writeln('# Uncomment to override global settings:');
    buf.writeln('# theme: dark');
    buf.writeln('# show_suggestions: true');
    buf.writeln('# cache_max_age_hours: 24');
    buf.writeln('# fail_on_vulnerable: true');
    buf.writeln('# fail_on_discontinued: true');

    return buf.toString();
  }
}
