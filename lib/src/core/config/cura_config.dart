import 'package:cura/src/core/config/score_weights.dart';
import 'package:yaml/yaml.dart';

class CuraConfig {
  // Apparence
  final String theme;
  final bool useEmojis;
  final bool useColors;

  // Comportement
  final int cacheMaxAge; // en heures
  final bool autoUpdate;
  final int minScore;

  // API
  final String? githubToken;
  final int timeoutSeconds;
  final int maxRetries;

  // Suggestions
  final bool showSuggestions;
  final int maxSuggestionsPerPackage;

  // Scoring (poids personnalisables)
  final ScoreWeights scoreWeights;

  // Exclusions
  final List<String> ignorePackages;
  final List<String> trustedPublishers;

  const CuraConfig({
    this.theme = 'dark',
    this.useEmojis = true,
    this.useColors = true,
    this.cacheMaxAge = 24,
    this.autoUpdate = true,
    this.minScore = 70,
    this.githubToken,
    this.timeoutSeconds = 10,
    this.maxRetries = 3,
    this.showSuggestions = true,
    this.maxSuggestionsPerPackage = 3,
    this.scoreWeights = const ScoreWeights(),
    this.ignorePackages = const [],
    this.trustedPublishers = const [],
  });

  /// Factory depuis YAML
  factory CuraConfig.fromYaml(YamlMap yaml) {
    return CuraConfig(
      theme: yaml['theme'] as String? ?? 'dark',
      useEmojis: yaml['use_emojis'] as bool? ?? true,
      useColors: yaml['use_colors'] as bool? ?? true,
      cacheMaxAge: yaml['cache_max_age'] as int? ?? 24,
      autoUpdate: yaml['auto_update'] as bool? ?? true,
      minScore: yaml['min_score'] as int? ?? 70,
      githubToken: yaml['github_token'] as String?,
      timeoutSeconds: yaml['timeout_seconds'] as int? ?? 10,
      maxRetries: yaml['max_retries'] as int? ?? 3,
      showSuggestions: yaml['show_suggestions'] as bool? ?? true,
      maxSuggestionsPerPackage: yaml['max_suggestions_per_package'] as int? ?? 3,
      scoreWeights: yaml.containsKey('score_weights')
          ? ScoreWeights.fromYaml(yaml['score_weights'] as YamlMap)
          : const ScoreWeights(),
      ignorePackages: (yaml['ignore_packages'] as YamlList?)?.cast<String>() ?? [],
      trustedPublishers: (yaml['trusted_publishers'] as YamlList?)?.cast<String>() ?? [],
    );
  }

  /// Config par défaut
  factory CuraConfig.defaultConfig() => const CuraConfig();

  /// Convertir en YAML string
  String toYamlString() {
    return '''
# Cura Configuration File
# See https://cura.dev/docs/config for details

# ============================================================================
# APPEARANCE
# ============================================================================
theme: $theme                    # dark, light, minimal, dracula
use_emojis: $useEmojis           # Show emojis in output
use_colors: $useColors           # Enable colored output

# ============================================================================
# CACHE
# ============================================================================
cache_max_age: $cacheMaxAge      # Cache expiration in hours
auto_update: $autoUpdate         # Auto-update cache in background

# ============================================================================
# SCORING
# ============================================================================
min_score: $minScore             # Minimum acceptable score for CI/CD

# Custom score weights (total must equal 100)
score_weights:
  vitality: ${scoreWeights.vitality}              # Freshness of updates (0-40)
  technical_health: ${scoreWeights.technicalHealth}   # Pana score, null safety (0-30)
  trust: ${scoreWeights.trust}                # Popularity, likes (0-20)
  maintenance: ${scoreWeights.maintenance}          # Publisher, Flutter Favorite (0-10)

# ============================================================================
# API CONFIGURATION
# ============================================================================
timeout_seconds: $timeoutSeconds # HTTP request timeout
max_retries: $maxRetries         # Max retry attempts for failed requests

# GitHub Personal Access Token (for higher rate limits)
# Get one at: https://github.com/settings/tokens
${githubToken != null ? 'github_token: $githubToken' : '# github_token: ghp_your_token_here'}

# ============================================================================
# SUGGESTIONS
# ============================================================================
show_suggestions: $showSuggestions           # Show alternative packages
max_suggestions_per_package: $maxSuggestionsPerPackage  # Max alternatives to show

# ============================================================================
# EXCLUSIONS
# ============================================================================
# Packages to ignore during analysis
ignore_packages:
${ignorePackages.isEmpty ? '  # - example_package' : ignorePackages.map((p) => '  - $p').join('\n')}

# Trusted publishers (auto-approve their packages)
trusted_publishers:
${trustedPublishers.isEmpty ? '  # - dart.dev\n  # - flutter.dev' : trustedPublishers.map((p) => '  - $p').join('\n')}
''';
  }

  /// Merge avec overrides
  CuraConfig merge({
    String? theme,
    bool? useEmojis,
    bool? useColors,
    int? cacheMaxAge,
    bool? autoUpdate,
    int? minScore,
    String? githubToken,
    int? timeoutSeconds,
    int? maxRetries,
    bool? showSuggestions,
    int? maxSuggestionsPerPackage,
  }) {
    return CuraConfig(
      theme: theme ?? this.theme,
      useEmojis: useEmojis ?? this.useEmojis,
      useColors: useColors ?? this.useColors,
      cacheMaxAge: cacheMaxAge ?? this.cacheMaxAge,
      autoUpdate: autoUpdate ?? this.autoUpdate,
      minScore: minScore ?? this.minScore,
      githubToken: githubToken ?? this.githubToken,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      maxRetries: maxRetries ?? this.maxRetries,
      showSuggestions: showSuggestions ?? this.showSuggestions,
      maxSuggestionsPerPackage: maxSuggestionsPerPackage ?? this.maxSuggestionsPerPackage,
      scoreWeights: scoreWeights,
      ignorePackages: ignorePackages,
      trustedPublishers: trustedPublishers,
    );
  }
}
