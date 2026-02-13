import 'dart:async';
import 'dart:convert';
import 'package:cura/src/core/cache_service.dart';
import 'package:cura/src/core/constants.dart';
import 'package:cura/src/core/error/exception.dart';
import 'package:cura/src/domain/models/package_info.dart';
import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';

class PubApiService {
  final http.Client _client;
  final CacheService _cache;
  final int _maxConcurrentRequests;

  // Semaphore pour contrôler la concurrence
  int _activeRequests = 0;
  final List<Completer<void>> _requestQueue = [];

  PubApiService({
    http.Client? client,
    CacheService? cache,
    int? maxConcurrentRequests,
  })  : _client = client ?? http.Client(),
        _cache = cache ?? CacheService(),
        _maxConcurrentRequests = maxConcurrentRequests ?? CuraConstants.maxConcurrentRequests;

  Future<PackageInfo> getPackageInfo(String packageName) async {
    // Vérifier le cache d'abord
    final cached = _cache.get(packageName);
    if (cached != null) {
      return cached;
    }

    // Attendre qu'un slot soit disponible
    await _acquireSlot();

    try {
      return retry(
        () async {
          final results = await Future.wait([
            _fetchJson('${CuraConstants.pubDevApiBase}/packages/$packageName', packageName: packageName),
            _fetchJson('${CuraConstants.pubDevApiBase}/packages/$packageName/score', packageName: packageName),
          ]);

          final infoJson = results[0] as Map<String, dynamic>;
          final scoreJson = results[1] as Map<String, dynamic>;

          try {
            final packageInfo = PackageInfo.fromPubDevJson(
              infoJson: infoJson,
              scoreJson: scoreJson,
            );

            // Sauvegarder dans le cache
            _cache.set(packageName, packageInfo);

            return packageInfo;
          } catch (e) {
            throw ParseException(
              'Invalid JSON response',
              field: 'body',
              originalError: e,
            );
          }
        },
        maxAttempts: 3,
        retryIf: (e) => e is NetworkException || e is TimeoutException,
        delayFactor: const Duration(seconds: 2),
      );
    } finally {
      _releaseSlot();
    }
  }

  Future<List<PackageInfo>> getMultiplePackages(
    List<String> packageNames,
  ) async {
    final results = await Future.wait(
      packageNames.map((name) => getPackageInfo(name)),
    );
    return results;
  }

  Future<void> _acquireSlot() async {
    if (_activeRequests < _maxConcurrentRequests) {
      _activeRequests++;
      return;
    }

    final completer = Completer<void>();
    _requestQueue.add(completer);
    await completer.future;
  }

  void _releaseSlot() {
    if (_requestQueue.isNotEmpty) {
      final completer = _requestQueue.removeAt(0);
      completer.complete();
    } else {
      _activeRequests--;
    }
  }

  // Helpers
  Future<dynamic> _fetchJson(
    String url, {
    required String packageName,
  }) async {
    final response = await _client.get(Uri.parse(url)).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw NetworkException(
            'Request timeout after 10 seconds',
            url: 'https://pub.dev/api/packages/$packageName',
          ),
        );

    if (response.statusCode == 404) {
      throw PackageNotFoundException(packageName);
    }

    if (response.statusCode == 429) {
      throw RateLimitException('pub.dev');
    }

    if (response.statusCode != 200) {
      throw NetworkException(
        'HTTP ${response.statusCode}',
        url: 'https://pub.dev/api/packages/$packageName',
        statusCode: response.statusCode,
      );
    }

    return jsonDecode(response.body);
  }

  void dispose() => _client.close();
}
