import 'package:cura/src/infrastructure/config/models/cura_config.dart';
import 'package:cura/src/infrastructure/config/models/score_weights.dart';

/// Compile-time constants and baseline values for the Cura configuration.
///
/// This class is a pure namespace — it cannot be instantiated.
///
/// [defaultConfig] is the authoritative baseline applied whenever a config
/// file is absent or a particular key is not declared.  Every field carries a
/// conservative default that is safe for CI/CD pipelines.
abstract final class ConfigDefaults {
  /// Baseline [CuraConfig] used when no config file exists.
  ///
  /// The object is `final` to prevent accidental mutation at runtime.
  /// Override individual values with [CuraConfig.copyWith] or by writing a
  /// config file rather than modifying this constant.
  static final CuraConfig defaultConfig = CuraConfig(
    // Appearance
    theme: 'dark',
    useColors: true,
    useEmojis: true,

    // Cache (24 h TTL)
    cacheMaxAgeHours: 24,
    enableCache: true,

    // Performance (conservative settings suitable for shared CI runners)
    maxConcurrency: 5,
    timeoutSeconds: 10,
    maxRetries: 3,
    autoUpdate: false,

    // Scoring
    minScore: 70,
    scoreWeights: ScoreWeights(),

    // Behaviour
    showSuggestions: true,
    maxSuggestionsPerPackage: 3,
    failOnVulnerable: true,
    failOnDiscontinued: true,

    // Exclusions (empty — users opt in via config file)
    ignoredPackages: const [],
    trustedPublishers: const [],

    // Logging
    verboseLogging: false,
    quiet: false,

    // API (no token — users must supply their own)
    githubToken: null,
  );

  /// Well-known publishers whose packages are considered implicitly trusted.
  ///
  /// These are **not** applied automatically; they serve as a suggested
  /// starting point for users who want to populate `trusted_publishers` in
  /// their config file.
  static const List<String> defaultTrustedPublishers = [
    'dart.dev',
    'tools.dart.dev',
    'flutter.dev',
    'fluttercommunity.dev',
    'google.dev',
    'firebase.google.com',
  ];

  /// SDK-level packages that are always excluded from scoring.
  ///
  /// These packages are maintained by the Dart/Flutter team and do not appear
  /// on pub.dev in a form that can be meaningfully audited.
  static const List<String> systemPackages = [
    'flutter',
    'flutter_test',
    'flutter_web_plugins',
    'dart',
  ];
}
