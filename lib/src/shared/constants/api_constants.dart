class ApiConstants {
  const ApiConstants._();

  // pub.dev API
  static const String pubDevBaseUrl = 'https://pub.dev';
  static const String pubDevApiUrl = 'https://pub.dev/api';
  static const Duration pubDevTimeout = Duration(seconds: 10);
  static const int pubDevMaxRetries = 3;

  // GitHub API
  static const String githubApiUrl = 'https://api.github.com';
  static const Duration githubTimeout = Duration(seconds: 10);

  // OSV.dev API
  static const String osvApiUrl = 'https://api.osv.dev';
  static const Duration osvTimeout = Duration(seconds: 10);

  // Rate Limiting
  static const int defaultMaxRequestsPerMinute = 100;
  static const Duration rateLimitWindow = Duration(minutes: 1);
}
