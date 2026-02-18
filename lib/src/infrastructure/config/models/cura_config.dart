import 'package:cura/src/infrastructure/config/models/score_weights.dart';
import 'package:yaml/yaml.dart';

class CuraConfig {
  // Appearance
  final String theme;
  final bool useColors;
  final bool useEmojis;

  // Cache
  final int cacheMaxAgeHours;
  final bool enableCache;

  // Performance
  final int maxConcurrency;
  final int timeoutSeconds;

  // Scoring
  final int minScore;
  final ScoreWeights scoreWeights;

  // Behavior
  final bool showSuggestions;
  final int maxSuggestionsPerPackage;
  final bool failOnVulnerable;
  final bool failOnDiscontinued;

  // Exclusions (internally immutable)
  final List<String> ignoredPackages;
  final List<String> trustedPublishers;

  // Logging
  final bool verboseLogging;
  final bool quiet;

  // API
  final String? githubToken;

  const CuraConfig({
    this.theme = 'dark',
    this.useColors = true,
    this.useEmojis = true,
    this.cacheMaxAgeHours = 24,
    this.enableCache = true,
    this.maxConcurrency = 5,
    this.timeoutSeconds = 10,
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

  CuraConfig copyWith({
    String? theme,
    bool? useColors,
    bool? useEmojis,
    int? cacheMaxAgeHours,
    bool? enableCache,
    int? maxConcurrency,
    int? timeoutSeconds,
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
      minScore: minScore ?? this.minScore,
      scoreWeights: scoreWeights ?? this.scoreWeights,
      showSuggestions: showSuggestions ?? this.showSuggestions,
      maxSuggestionsPerPackage: maxSuggestionsPerPackage ?? this.maxSuggestionsPerPackage,
      failOnVulnerable: failOnVulnerable ?? this.failOnVulnerable,
      failOnDiscontinued: failOnDiscontinued ?? this.failOnDiscontinued,
      ignoredPackages: ignoredPackages ?? this.ignoredPackages,
      trustedPublishers: trustedPublishers ?? this.trustedPublishers,
      verboseLogging: verboseLogging ?? this.verboseLogging,
      quiet: quiet ?? this.quiet,
      githubToken: githubToken ?? this.githubToken,
    );
  }

  // -------- JSON --------

  factory CuraConfig.fromJson(Map<String, dynamic> json) {
    return CuraConfig(
      theme: json['theme'] ?? 'dark',
      useColors: json['useColors'] ?? true,
      useEmojis: json['useEmojis'] ?? true,
      cacheMaxAgeHours: json['cacheMaxAgeHours'] ?? 24,
      enableCache: json['enableCache'] ?? true,
      maxConcurrency: json['maxConcurrency'] ?? 5,
      timeoutSeconds: json['timeoutSeconds'] ?? 10,
      minScore: json['minScore'] ?? 70,
      scoreWeights: json['scoreWeights'] != null ? ScoreWeights.fromJson(json['scoreWeights']) : const ScoreWeights(),
      showSuggestions: json['showSuggestions'] ?? true,
      maxSuggestionsPerPackage: json['maxSuggestionsPerPackage'] ?? 3,
      failOnVulnerable: json['failOnVulnerable'] ?? true,
      failOnDiscontinued: json['failOnDiscontinued'] ?? true,
      ignoredPackages: (json['ignoredPackages'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      trustedPublishers: (json['trustedPublishers'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      verboseLogging: json['verboseLogging'] ?? false,
      quiet: json['quiet'] ?? false,
      githubToken: json['githubToken'],
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
}

class CuraConfig2 {
  // Apparence
  final String? theme;
  final bool? useEmojis;
  final bool? useColors;

  // Comportement
  final int? cacheMaxAge; // en heures
  final bool? autoUpdate;
  final int? minScore;

  // API
  final String? githubToken;
  final int? timeoutSeconds;
  final int? maxRetries;

  // Suggestions
  final bool? showSuggestions;
  final int? maxSuggestionsPerPackage;

  // Scoring (poids personnalisables)
  final ScoreWeights? scoreWeights;

  // Exclusions
  final List<String>? ignorePackages;
  final List<String>? trustedPublishers;

  const CuraConfig2({
    this.theme,
    this.useEmojis,
    this.useColors,
    this.cacheMaxAge,
    this.autoUpdate,
    this.minScore,
    this.githubToken,
    this.timeoutSeconds,
    this.maxRetries,
    this.showSuggestions,
    this.maxSuggestionsPerPackage,
    this.scoreWeights,
    this.ignorePackages,
    this.trustedPublishers,
  });

  /// Factory depuis YAML
  factory CuraConfig2.fromYaml(YamlMap yaml) {
    return CuraConfig2(
      theme: yaml['theme'] as String?,
      useEmojis: yaml['use_emojis'] as bool?,
      useColors: yaml['use_colors'] as bool?,
      cacheMaxAge: yaml['cache_max_age'] as int?,
      autoUpdate: yaml['auto_update'] as bool?,
      minScore: yaml['min_score'] as int? ?? 70,
      githubToken: yaml['github_token'] as String?,
      timeoutSeconds: yaml['timeout_seconds'] as int?,
      maxRetries: yaml['max_retries'] as int?,
      showSuggestions: yaml['show_suggestions'] as bool?,
      maxSuggestionsPerPackage: yaml['max_suggestions_per_package'] as int?,
      // scoreWeights: yaml.containsKey('score_weights')
      //     ? ScoreWeights.fromYaml(yaml['score_weights'] as YamlMap)
      //     : null,
      ignorePackages: (yaml['ignore_packages'] as YamlList?)?.cast<String>(),
      trustedPublishers: (yaml['trusted_publishers'] as YamlList?)?.cast<String>(),
    );
  }

  /// Convertit en YAML avec option projet
  String toYamlString({bool isProject = false}) {
    if (isProject) {
      return toProjectYamlString();
    }
    // Retourner le YAML complet (original)
    return '''
# Cura Configuration File
# Global config at: ~/.cura/config.yaml

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
  vitality: ${scoreWeights?.vitality}              # Freshness of updates (0-40)
  technical_health: ${scoreWeights?.technicalHealth}   # Pana score, null safety (0-30)
  trust: ${scoreWeights?.trust}                # Popularity, likes (0-20)
  maintenance: ${scoreWeights?.maintenance}          # Publisher, Flutter Favorite (0-10)

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
${ignorePackages!.isEmpty ? '  # - example_package' : ignorePackages?.map((p) => '  - $p').join('\n')}

# Trusted publishers (auto-approve their packages)
trusted_publishers:
${trustedPublishers!.isEmpty ? '  # - dart.dev\n  # - flutter.dev' : trustedPublishers?.map((p) => '  - $p').join('\n')}
''';
  }

  String toProjectYamlString() {
    final buffer = StringBuffer();

    buffer.writeln('# Cura Project Configuration');
    buffer.writeln('# This config overrides global settings for this project');
    buffer.writeln('# Global config: ~/.cura/config.yaml');
    buffer.writeln('');
    buffer.writeln('# ============================================================================');
    buffer.writeln('# PROJECT-SPECIFIC SETTINGS');
    buffer.writeln('# ============================================================================');
    buffer.writeln('');

    // N'écrire que les valeurs non-null (overrides)
    if (minScore != null) {
      buffer.writeln('# Override minimum score for this project');
      buffer.writeln('min_score: $minScore');
      buffer.writeln('');
    }

    if (ignorePackages != null && ignorePackages!.isNotEmpty) {
      buffer.writeln('# Packages to ignore in this project');
      buffer.writeln('ignore_packages:');
      for (final pkg in ignorePackages!) {
        buffer.writeln('  - $pkg');
      }
      buffer.writeln('');
    }

    if (trustedPublishers != null && trustedPublishers!.isNotEmpty) {
      buffer.writeln('# Additional trusted publishers for this project');
      buffer.writeln('trusted_publishers:');
      for (final pub in trustedPublishers!) {
        buffer.writeln('  - $pub');
      }
      buffer.writeln('');
    }

    buffer.writeln('# ============================================================================');
    buffer.writeln('# OPTIONAL OVERRIDES');
    buffer.writeln('# Uncomment to override global settings');
    buffer.writeln('# ============================================================================');
    buffer.writeln('');
    buffer.writeln('# theme: dark');
    buffer.writeln('# show_suggestions: true');
    buffer.writeln('# cache_max_age: 24');

    return buffer.toString();
  }

  // /// Config vide (pour projet sans config)
  // factory CuraConfig.empty() {
  //   return const CuraConfig(
  //     theme: null,
  //     useEmojis: null,
  //     useColors: null,
  //     cacheMaxAge: null,
  //     autoUpdate: null,
  //     minScore: null,
  //     githubToken: null,
  //     timeoutSeconds: null,
  //     maxRetries: null,
  //     showSuggestions: null,
  //     maxSuggestionsPerPackage: null,
  //     scoreWeights: null,
  //     ignorePackages: null,
  //     trustedPublishers: null,
  //   );
  // }

  /// Template pour config projet (uniquement les overrides courants)
  // factory CuraConfig.projectTemplate() {
  //   return const CuraConfig(
  //     // Laisser null pour hériter de global
  //     theme: null,
  //     useEmojis: null,
  //     useColors: null,
  //     cacheMaxAge: null,
  //     autoUpdate: null,

  //     // Overrides typiques de projet
  //     minScore: 75, // Peut être plus strict par projet
  //     githubToken: null,
  //     timeoutSeconds: null,
  //     maxRetries: null,
  //     showSuggestions: true,
  //     maxSuggestionsPerPackage: null,
  //     scoreWeights: null,

  //     // Exclusions spécifiques au projet
  //     ignorePackages: [],
  //     trustedPublishers: [],
  //   );
  // }

  /// Merge avec overrides
  // CuraConfig merge({
  //   String? theme,
  //   bool? useEmojis,
  //   bool? useColors,
  //   int? cacheMaxAge,
  //   bool? autoUpdate,
  //   int? minScore,
  //   String? githubToken,
  //   int? timeoutSeconds,
  //   int? maxRetries,
  //   bool? showSuggestions,
  //   int? maxSuggestionsPerPackage,
  // }) {
  //   return CuraConfig(
  //     theme: theme ?? this.theme,
  //     useEmojis: useEmojis ?? this.useEmojis,
  //     useColors: useColors ?? this.useColors,
  //     cacheMaxAge: cacheMaxAge ?? this.cacheMaxAge,
  //     autoUpdate: autoUpdate ?? this.autoUpdate,
  //     minScore: minScore ?? this.minScore,
  //     githubToken: githubToken ?? this.githubToken,
  //     timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
  //     maxRetries: maxRetries ?? this.maxRetries,
  //     showSuggestions: showSuggestions ?? this.showSuggestions,
  //     maxSuggestionsPerPackage: maxSuggestionsPerPackage ?? this.maxSuggestionsPerPackage,
  //     scoreWeights: scoreWeights,
  //     ignorePackages: ignorePackages,
  //     trustedPublishers: trustedPublishers,
  //   );
  // }

  // /// Fusionne avec une autre config (autre > this)
  // CuraConfig mergeWith(CuraConfig other) {
  //   return CuraConfig(
  //     theme: other.theme ?? theme,
  //     useEmojis: other.useEmojis ?? useEmojis,
  //     useColors: other.useColors ?? useColors,
  //     cacheMaxAge: other.cacheMaxAge ?? cacheMaxAge,
  //     autoUpdate: other.autoUpdate ?? autoUpdate,
  //     minScore: other.minScore ?? minScore,
  //     githubToken: other.githubToken ?? githubToken,
  //     timeoutSeconds: other.timeoutSeconds ?? timeoutSeconds,
  //     maxRetries: other.maxRetries ?? maxRetries,
  //     showSuggestions: other.showSuggestions ?? showSuggestions,
  //     maxSuggestionsPerPackage: other.maxSuggestionsPerPackage ?? maxSuggestionsPerPackage,
  //     scoreWeights: other.scoreWeights ?? scoreWeights,
  //     ignorePackages: other.ignorePackages ?? ignorePackages,
  //     trustedPublishers: other.trustedPublishers ?? trustedPublishers,
  //   );
  // }
}
