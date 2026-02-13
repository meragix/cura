class CuraConstants {
  static const String cacheFileName = '.cura_cache.json';
  static const Duration cacheValidityDuration = Duration(hours: 24);
  static const int maxConcurrentRequests = 5;
  static const String pubDevApiBase = 'https://pub.dev/api';

  // Seuils de scoring
  static const int maintenanceMaxScore = 40;
  static const int trustMaxScore = 30;
  static const int popularityMaxScore = 20;
  static const int penaltyMaxDeduction = 65;

  // Seuils temporels (en jours)
  static const int recentMaintenanceThreshold = 180; // 6 mois
  static const int acceptableMaintenanceThreshold = 365; // 12 mois
  static const int legacyThreshold = 540; // 18 mois

  // Seuils de qualité
  static const int minDescriptionLength = 300;
  static const int stablePackageMinScore = 130; // Score pana minimum

  // Publishers de confiance
  static const List<String> trustedPublishers = [
    'dart.dev',
    'tools.dart.dev',
    'flutter.dev',
    'fluttercommunity.dev'
    'google.dev',
    'firebase.google.com',
  ];
}
