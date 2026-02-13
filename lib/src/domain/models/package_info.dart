import 'package:cura/src/core/constants.dart';

class PackageInfo {
  final String name;
  final String version;
  final DateTime published;
  final String? publisherId;
  final bool isFlutterFavorite;
  final bool isDiscontinued;
  final int panaScore;
  final int maxPanaScore;
  final int likes;
  final int popularity;
  final int downloads30Days;
  final String? repositoryUrl;
  final List<String> platforms;
  final List<String> tags;

  PackageInfo({
    required this.name,
    required this.version,
    required this.published,
    this.publisherId,
    required this.isFlutterFavorite,
    required this.isDiscontinued,
    required this.panaScore,
    required this.maxPanaScore,
    required this.likes,
    required this.popularity,
    required this.downloads30Days,
    this.repositoryUrl,
    required this.platforms,
    required this.tags,
  });

  bool get hasVerifiedPublisher => publisherId != null;

  bool get isTrustedPublisher {
    if (publisherId == null) return false;
    return CuraConstants.trustedPublishers.contains(publisherId);
  }

  int get daysSinceLastRelease {
    return DateTime.now().difference(published).inDays;
  }

  bool get hasRepository => repositoryUrl != null && repositoryUrl!.isNotEmpty;

  double get healthRatio => panaScore / maxPanaScore;

  factory PackageInfo.fromJson(Map<String, dynamic> json) {
    return PackageInfo(
      name: json['name'] as String,
      version: json['version'] as String,
      published: DateTime.parse(json['published'] as String),
      publisherId: json['publisherId'] as String?,
      isFlutterFavorite: json['isFlutterFavorite'] as bool? ?? false,
      isDiscontinued: json['isDiscontinued'] as bool? ?? false,
      panaScore: (json['panaScore'] as num).toInt(),
      maxPanaScore: (json['maxPanaScore'] as num).toInt(),
      likes: (json['likes'] as num).toInt(),
      popularity: (json['popularity'] as num).toInt(),
      downloads30Days: (json['downloads30Days'] as num).toInt(),
      repositoryUrl: json['repositoryUrl'] as String?,
      platforms: (json['platforms'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'version': version,
        'published': published.toIso8601String(),
        'publisherId': publisherId,
        'isFlutterFavorite': isFlutterFavorite,
        'isDiscontinued': isDiscontinued,
        'panaScore': panaScore,
        'maxPanaScore': maxPanaScore,
        'likes': likes,
        'popularity': popularity,
        'downloads30Days': downloads30Days,
        'repositoryUrl': repositoryUrl,
        'platforms': platforms,
        'tags': tags,
      };

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
      published: DateTime.parse(latest['published'] as String),
      publisherId: _extractPublisher(tags),
      isFlutterFavorite: tags.contains('is:flutter-favorite'),
      isDiscontinued: tags.contains('is:discontinued'),
      panaScore: scoreJson['grantedPoints'] as int? ?? 0,
      maxPanaScore: scoreJson['maxPoints'] as int? ?? 160,
      likes: scoreJson['likeCount'] as int? ?? 0,
      popularity: _calculatePopularityFromDownloads(downloads30Days),
      downloads30Days: downloads30Days,
      repositoryUrl: pubspec['repository'] as String?,
      platforms: _extractPlatformsFromTags(tags),
      tags: tags,
    );
  }

  /// Extrait le publisher depuis les tags
  static String? _extractPublisher(List<String> tags) {
    final publisherTag = tags.firstWhere(
      (tag) => tag.startsWith('publisher:'),
      orElse: () => '',
    );

    return publisherTag.isEmpty
        ? null
        : publisherTag.replaceFirst('publisher:', '');
  }

  /// Extrait les plateformes depuis les tags
  static List<String> _extractPlatformsFromTags(List<String> tags) {
    final platforms = tags
        .where((tag) => tag.startsWith('platform:'))
        .map((tag) => tag.replaceFirst('platform:', ''))
        .toList();

    // Si aucune plateforme et pas Flutter, c'est un package Dart pur
    if (platforms.isEmpty && !tags.contains('sdk:flutter')) {
      return ['dart'];
    }

    return platforms;
  }

  /// Calcule la popularité depuis les downloads (échelle logarithmique)
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

  /// Helpers to check specific tags
  bool get isNullSafe => tags.contains('is:null-safe');
  bool get isDart3Compatible => tags.contains('is:dart3-compatible');
  bool get isPlugin => tags.contains('is:plugin');
  bool get isNew => tags.contains('is:recent');
  bool get licenseOsiApproved =>
      tags.contains('license:osi-approved') ||
      tags.contains('license:fsf-libre');

  String? get license {
    final licenseTag = tags.firstWhere(
      (tag) =>
          tag.startsWith('license:') &&
          !tag.contains('fsf') &&
          !tag.contains('osi'),
      orElse: () => '',
    );
    return licenseTag.isEmpty ? null : licenseTag.replaceFirst('license:', '');
  }
}
