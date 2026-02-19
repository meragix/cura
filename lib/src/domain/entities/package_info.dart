import 'package:cura/src/infrastructure/config/models/config_defaults.dart';

class PackageInfo {
  final String name;
  final String version;
  final String description;
  final DateTime lastPublished;

  // Metrics
  final int panaScore;
  final int likes;
  final int popularity;
  final int grantedPoints;
  final int maxPoints;

  // Flags
  final bool isNullSafe;
  final bool isDart3Compatible;
  final bool isDiscontinued;
  final bool isFlutterFavorite;
  final bool isNew;
  final bool isWasmReady;

  // Publisher
  final String? publisherId;

  // Platforms
  final List<String> supportedPlatforms;

  // Repository
  final String? repositoryUrl;
  final String? homepageUrl;

  // License
  final String? license;

  const PackageInfo({
    required this.name,
    required this.version,
    required this.description,
    required this.lastPublished,
    required this.panaScore,
    required this.likes,
    required this.popularity,
    required this.grantedPoints,
    required this.maxPoints,
    required this.isNullSafe,
    required this.isDart3Compatible,
    required this.isDiscontinued,
    required this.isFlutterFavorite,
    required this.isNew,
    required this.isWasmReady,
    this.publisherId,
    required this.supportedPlatforms,
    this.repositoryUrl,
    this.homepageUrl,
    this.license,
  });

  /// Helpers
  bool get hasVerifiedPublisher => publisherId != null && publisherId!.isNotEmpty;
  bool get hasRepository => repositoryUrl != null && repositoryUrl!.isNotEmpty;

  bool get isTrustedPublisher {
    if (publisherId == null) return false;
    return ConfigDefaults.defaultTrustedPublishers.contains(publisherId);
  }

  int get daysSinceLastUpdate => DateTime.now().difference(lastPublished).inDays;

  double get scorePercentage => maxPoints > 0 ? (grantedPoints / maxPoints * 100) : 0;

  bool get isPopular => likes > 1000 || popularity > 90;
  bool get isStable => version.startsWith('1.') || version.startsWith('2.');
  bool get isWeb =>  supportedPlatforms.contains('platform:web'); // show WasmMessage later

  // Todo: perform it later
  factory PackageInfo.fromPubDevJson({
    required Map<String, dynamic> infoJson,
    required Map<String, dynamic> scoreJson,
  }) {
    final latest = infoJson['latest'] as Map<String, dynamic>;
    final pubspec = latest['pubspec'] as Map<String, dynamic>;

    // Extraire les tags du score endpoint
    final tags = (scoreJson['tags'] as List<dynamic>?)?.cast<String>() ?? [];

    // Extraire downloads
    final downloads30Days = scoreJson['downloadCount30Days'] as int? ?? 0;

    return PackageInfo(
      name: infoJson['name'] as String,
      version: latest['version'] as String,
      description: pubspec['description'] as String,
      lastPublished: DateTime.parse(latest['published'] as String),
      panaScore: scoreJson['grantedPoints'] as int? ?? 0,
      likes: scoreJson['likeCount'] as int,
      popularity: _calculatePopularityFromDownloads(downloads30Days),
      grantedPoints: scoreJson['grantedPoints'] as int,
      maxPoints: scoreJson['maxPoints'] as int,
      isNullSafe: tags.contains('is:null-safe'),
      isDart3Compatible: tags.contains('is:dart3-compatible'),
      isDiscontinued: tags.contains('is:discontinued'),
      isFlutterFavorite: tags.contains('is:flutter-favorite'),
      isNew: tags.contains('is:recent'),
      isWasmReady: tags.contains('is:wasm-ready'),
      publisherId: _extractPublisher(tags),
      supportedPlatforms: _extractPlatformsFromTags(tags),
      repositoryUrl: pubspec['repository'] as String?,
      homepageUrl: pubspec['homepage'] as String?,
      license: _extractLicense(tags),
    );
  }

  /// Extrait les plateformes depuis les tags
  static List<String> _extractPlatformsFromTags(List<String> tags) {
    final platforms =
        tags.where((tag) => tag.startsWith('platform:')).map((tag) => tag.replaceFirst('platform:', '')).toList();

    // Si aucune plateforme et pas Flutter, c'est un package Dart pur
    if (platforms.isEmpty && !tags.contains('sdk:flutter')) {
      return ['dart'];
    }

    return platforms;
  }

  /// Calculates popularity based on downloads (logarithmic scale)
  static int _calculatePopularityFromDownloads(int downloads30Days) {
    if (downloads30Days >= 500000) return 100;
    if (downloads30Days >= 250000) return 95;
    if (downloads30Days >= 100000) return 85;
    if (downloads30Days >= 50000) return 75;
    if (downloads30Days >= 25000) return 65;
    if (downloads30Days >= 10000) return 55;
    if (downloads30Days >= 5000) return 45;
    if (downloads30Days >= 1000) return 35;
    if (downloads30Days >= 500) return 25;
    if (downloads30Days >= 100) return 15;
    return 5;
  }

  /// Extrait le publisher depuis les tags
  static String? _extractPublisher(List<String> tags) {
    final publisherTag = tags.firstWhere(
      (tag) => tag.startsWith('publisher:'),
      orElse: () => '',
    );

    return publisherTag.isEmpty ? null : publisherTag.replaceFirst('publisher:', '');
  }

  static String? _extractLicense(List<String> tags) {
    final licenseTag = tags.firstWhere(
      (tag) => tag.startsWith('license:') && !tag.contains('fsf') && !tag.contains('osi'),
      orElse: () => '',
    );
    return licenseTag.isEmpty ? null : licenseTag.replaceFirst('license:', '');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackageInfo && runtimeType == other.runtimeType && name == other.name && version == other.version;

  @override
  int get hashCode => name.hashCode ^ version.hashCode;

  @override
  String toString() => 'PackageInfo($name@$version)';
}
