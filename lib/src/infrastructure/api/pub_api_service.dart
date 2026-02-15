import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cura/src/core/cache_service.dart';
import 'package:cura/src/core/constants.dart';
import 'package:cura/src/core/error/exception.dart';
import 'package:cura/src/domain/models/package_info.dart';
import 'package:cura/src/utils/helpers/pubspec_parser.dart';
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
          // Business Rule: On a besoin des deux endpoints pour un score complet
          final (infoJson, scoreJson) = await (
            _client.fetchJson('${CuraConstants.pubDevApiBase}/packages/$packageName', packageName: packageName),
            _client.fetchJson('${CuraConstants.pubDevApiBase}/packages/$packageName/score', packageName: packageName),
          ).wait;

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

  // todo: replace this with pool connection
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

  void dispose() => _client.close();
}

extension PubDevClientX on http.Client {
  Future<Map<String, dynamic>> fetchJson(
    String url, {
    required String packageName,
  }) async {
    final response = await get(Uri.parse(url)).timeout(
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

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

// Future<Result<PackageInfo>> getPackageInfo(String packageName) async {
//   final baseUrl = CuraConstants.pubDevApiBase;

//   return _connectionPool.withResource(() async {
//     try {
//       // Dart 3 Parallelism : On lance les deux en même temps
//       // Les Records (.wait) attendent que les deux soient finis
//       final (infoJson, scoreJson) = await (
//         _client.fetchJson('$baseUrl/packages/$packageName'),
//         _client.fetchJson('$baseUrl/packages/$packageName/score'),
//       ).wait;

//       final packageInfo = PackageInfo.fromPubDevJson(
//         infoJson: infoJson,
//         scoreJson: scoreJson,
//       );

//       return Success(packageInfo);
//     } catch (e) {
//       return Failure('Network error for $packageName: $e');
//     }
//   });
// }
