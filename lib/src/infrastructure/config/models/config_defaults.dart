import 'package:cura/src/infrastructure/config/models/cura_config.dart';
import 'package:cura/src/infrastructure/config/models/score_weights.dart';

/// Default configuration (immutable)
class ConfigDefaults {
  const ConfigDefaults._();

  /// Config par défaut (conservative settings)
  static CuraConfig defaultConfig = CuraConfig(
    // Appearance
    theme: 'dark',
    useColors: true,
    useEmojis: true,

    // Cache (24h TTL)
    cacheMaxAgeHours: 24,
    enableCache: true,

    // Performance (conservative)
    maxConcurrency: 5,
    timeoutSeconds: 10,
    maxRetries: 3,
    autoUpdate: false,

    // Scoring
    minScore: 70,
    scoreWeights: ScoreWeights(),

    // Behavior
    showSuggestions: true,
    maxSuggestionsPerPackage: 3,
    failOnVulnerable: true,
    failOnDiscontinued: true,

    // Exclusions (empty)
    ignoredPackages: [],
    trustedPublishers: [],

    // Logging
    verboseLogging: false,
    quiet: false,

    // API (no token by default)
    githubToken: null,
  );

  /// Publishers de confiance pré-configurés
  static const List<String> defaultTrustedPublishers = [
    'dart.dev',
    'tools.dart.dev',
    'flutter.dev',
    'fluttercommunity.dev',
    'google.dev',
    'firebase.google.com',
  ];

  /// Packages systèmes à ignorer par défaut
  static const List<String> systemPackages = [
    'flutter',
    'flutter_test',
    'flutter_web_plugins',
    'dart',
  ];
}
