import 'package:cura/src/infrastructure/config/models/config_defaults.dart';

/// Pub.dev package metadata fetched from the packages and score endpoints.
///
/// This is the primary domain entity. It holds every field required by the
/// scoring algorithm, the presentation layer, and the SQLite cache.
///
/// ### JSON round-trip
/// [toJson] / [fromJson] target the **internal cache format** (camelCase
/// field names). The separate [fromPubDevJson] factory parses the raw
/// pub.dev API response (which uses a different shape).
///
/// ### Architectural note
/// [isTrustedPublisher] currently references `ConfigDefaults` from the
/// infrastructure layer. This is a known violation of the hexagonal
/// architecture boundary that will be resolved by moving trusted-publisher
/// resolution into a dedicated domain service.
class PackageInfo {
  /// Pub.dev package identifier (e.g. `dio`).
  final String name;

  /// Latest published version string (e.g. `5.4.3+1`).
  final String version;

  /// Short description from the package's `pubspec.yaml`.
  final String description;

  /// UTC timestamp of the most recent pub.dev publication.
  final DateTime lastPublished;

  // -------------------------------------------------------------------------
  // Pub.dev score metrics
  // -------------------------------------------------------------------------

  /// Pana-granted points (equals [grantedPoints] on pub.dev).
  final int panaScore;

  /// Number of pub.dev likes.
  final int likes;

  /// Derived popularity score in the range 0–100 mapped from 30-day download
  /// counts using a stepped scale (see [_calculatePopularityFromDownloads]).
  final int popularity;

  /// Points granted by the pana static analysis tool.
  final int grantedPoints;

  /// Maximum points achievable by the pana analysis for this package.
  final int maxPoints;

  // -------------------------------------------------------------------------
  // Capability flags
  // -------------------------------------------------------------------------

  /// Whether the package opts in to Dart null safety.
  final bool isNullSafe;

  /// Whether the package is compatible with Dart 3.
  final bool isDart3Compatible;

  /// Whether the package has been marked discontinued on pub.dev.
  final bool isDiscontinued;

  /// Whether the package holds the Flutter Favourite badge.
  final bool isFlutterFavorite;

  /// Whether the package was published recently (pub.dev `is:recent` tag).
  final bool isNew;

  /// Whether the package supports WebAssembly compilation.
  final bool isWasmReady;

  // -------------------------------------------------------------------------
  // Publisher & repository
  // -------------------------------------------------------------------------

  /// Verified publisher identifier (e.g. `dart.dev`), or `null` when the
  /// package is published by an unverified account.
  final String? publisherId;

  /// Platform identifiers extracted from pub.dev tags
  /// (e.g. `['android', 'ios', 'web']`). Pure Dart packages without explicit
  /// platform tags are represented as `['dart']`.
  final List<String> supportedPlatforms;

  /// Source repository URL from `pubspec.yaml`, or `null` when absent.
  final String? repositoryUrl;

  /// Homepage URL from `pubspec.yaml`, or `null` when absent.
  final String? homepageUrl;

  /// SPDX license identifier extracted from pub.dev tags, or `null`.
  final String? license;

  /// Creates a [PackageInfo] with all required fields.
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

  // ---------------------------------------------------------------------------
  // Derived properties
  // ---------------------------------------------------------------------------

  /// Whether the package has a non-empty verified publisher.
  bool get hasVerifiedPublisher =>
      publisherId != null && publisherId!.isNotEmpty;

  /// Whether the package has a non-empty source repository URL.
  bool get hasRepository => repositoryUrl != null && repositoryUrl!.isNotEmpty;

  /// Whether [publisherId] is on the hard-coded list of first-party publishers
  /// (e.g. `dart.dev`, `flutter.dev`).
  bool get isTrustedPublisher {
    if (publisherId == null) return false;
    return ConfigDefaults.defaultTrustedPublishers.contains(publisherId);
  }

  /// Number of days since the last pub.dev publication.
  int get daysSinceLastUpdate =>
      DateTime.now().difference(lastPublished).inDays;

  /// Pana score as a percentage of [maxPoints] (0–100).
  double get scorePercentage =>
      maxPoints > 0 ? (grantedPoints / maxPoints * 100) : 0;

  /// Whether the package is widely used (more than 1 000 likes OR
  /// popularity ≥ 90).
  bool get isPopular => likes > 1000 || popularity > 90;

  /// Whether the package explicitly targets the web platform.
  bool get isWeb => supportedPlatforms.contains('platform:web');

  /// Whether the package's version string indicates a stable release.
  ///
  /// A version is considered stable when:
  /// - The major version component is ≥ 1.
  /// - The version string contains no pre-release suffix (hyphen).
  /// - The package is not [isDiscontinued].
  bool get isStable {
    try {
      final majorStr = version.split(RegExp(r'[.-]')).first;
      final major = int.parse(majorStr);
      return major >= 1 && !version.contains('-') && !isDiscontinued;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Factories
  // ---------------------------------------------------------------------------

  /// Parses a [PackageInfo] from the combined pub.dev packages + score API
  /// responses.
  ///
  /// [infoJson] is the response body from `GET /packages/{name}`.
  /// [scoreJson] is the response body from `GET /packages/{name}/score`.
  factory PackageInfo.fromPubDevJson({
    required Map<String, dynamic> infoJson,
    required Map<String, dynamic> scoreJson,
  }) {
    final latest = infoJson['latest'] as Map<String, dynamic>;
    final pubspec = latest['pubspec'] as Map<String, dynamic>;

    final tags =
        (scoreJson['tags'] as List<dynamic>?)?.cast<String>() ?? [];
    final downloads30Days =
        scoreJson['downloadCount30Days'] as int? ?? 0;

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

  /// Deserialises a [PackageInfo] from the internal JSON cache format
  /// produced by [toJson].
  factory PackageInfo.fromJson(Map<String, dynamic> json) {
    return PackageInfo(
      name: json['name'] as String,
      version: json['version'] as String,
      description: json['description'] as String,
      lastPublished: DateTime.parse(json['lastPublished'] as String),
      panaScore: json['panaScore'] as int,
      likes: json['likes'] as int,
      popularity: json['popularity'] as int,
      grantedPoints: json['grantedPoints'] as int,
      maxPoints: json['maxPoints'] as int,
      isNullSafe: json['isNullSafe'] as bool,
      isDart3Compatible: json['isDart3Compatible'] as bool,
      isDiscontinued: json['isDiscontinued'] as bool,
      isFlutterFavorite: json['isFlutterFavorite'] as bool,
      isNew: json['isNew'] as bool,
      isWasmReady: json['isWasmReady'] as bool,
      publisherId: json['publisherId'] as String?,
      supportedPlatforms: (json['supportedPlatforms'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      repositoryUrl: json['repositoryUrl'] as String?,
      homepageUrl: json['homepageUrl'] as String?,
      license: json['license'] as String?,
    );
  }

  /// Serialises this instance to the internal JSON cache format.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'version': version,
      'description': description,
      'lastPublished': lastPublished.toIso8601String(),
      'panaScore': panaScore,
      'likes': likes,
      'popularity': popularity,
      'grantedPoints': grantedPoints,
      'maxPoints': maxPoints,
      'isNullSafe': isNullSafe,
      'isDart3Compatible': isDart3Compatible,
      'isDiscontinued': isDiscontinued,
      'isFlutterFavorite': isFlutterFavorite,
      'isNew': isNew,
      'isWasmReady': isWasmReady,
      'publisherId': publisherId,
      'supportedPlatforms': supportedPlatforms,
      'repositoryUrl': repositoryUrl,
      'homepageUrl': homepageUrl,
      'license': license,
    };
  }

  // ---------------------------------------------------------------------------
  // Private tag-parsing helpers
  // ---------------------------------------------------------------------------

  /// Maps 30-day download counts to a 0–100 popularity score using a
  /// stepped scale calibrated against pub.dev traffic distribution.
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

  /// Extracts `platform:*` tags and normalises them to bare platform names.
  ///
  /// Returns `['dart']` for packages that have no platform tags and do not
  /// target Flutter, since they are assumed to be pure Dart libraries.
  static List<String> _extractPlatformsFromTags(List<String> tags) {
    final platforms = tags
        .where((tag) => tag.startsWith('platform:'))
        .map((tag) => tag.replaceFirst('platform:', ''))
        .toList();

    if (platforms.isEmpty && !tags.contains('sdk:flutter')) {
      return ['dart'];
    }

    return platforms;
  }

  /// Extracts the `publisher:*` tag value, or returns `null` when absent.
  static String? _extractPublisher(List<String> tags) {
    final tag = tags.firstWhere(
      (t) => t.startsWith('publisher:'),
      orElse: () => '',
    );
    return tag.isEmpty ? null : tag.replaceFirst('publisher:', '');
  }

  /// Extracts the primary SPDX license identifier from the `license:*` tags.
  ///
  /// Meta-tags such as `license:fsf-approved` and `license:osi-approved` are
  /// excluded; only the concrete identifier (e.g. `license:mit`) is returned.
  static String? _extractLicense(List<String> tags) {
    final tag = tags.firstWhere(
      (t) =>
          t.startsWith('license:') &&
          !t.contains('fsf') &&
          !t.contains('osi'),
      orElse: () => '',
    );
    return tag.isEmpty ? null : tag.replaceFirst('license:', '');
  }

  // ---------------------------------------------------------------------------
  // Object identity
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackageInfo &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          version == other.version;

  @override
  int get hashCode => name.hashCode ^ version.hashCode;

  @override
  String toString() => 'PackageInfo($name@$version)';
}
