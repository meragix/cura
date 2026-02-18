import 'package:cura/src/domain/entities/package_info.dart';
import 'package:cura/src/domain/value_objects/exception.dart';
import 'package:cura/src/shared/constants/api_constants.dart';
import 'package:dio/dio.dart';

/// HTTP client for pub.dev API
/// 
/// Doc : https://github.com/dart-lang/pub-dev/blob/master/doc/api.md
class PubDevApiClient {
  final Dio _dio;

  PubDevApiClient(this._dio);

  /// Fetch package info from pub.dev
  /// 
  /// Endpoint : GET `/api/packages/{package}` and GET  `/api/packages/{package}/score`
  Future<PackageInfo> getPackageInfo(String packageName) async {
    final baseUrl = '${ApiConstants.pubDevApiUrl}/packages';

    try {
      // Business Rule: Both endpoints are needed for a complete score
      final (infoJson, scoreJson) = await (
        _dio.fetchJson('$baseUrl/$packageName', packageName: packageName),
        _dio.fetchJson('$baseUrl/$packageName/score', packageName: packageName),
      ).wait;

      try {
        final packageInfo = PackageInfo.fromPubDevJson(
          infoJson: infoJson,
          scoreJson: scoreJson,
        );

        return packageInfo;
      } catch (e) {
        throw ParseException(
          'Invalid JSON response',
          field: 'body',
          originalError: e,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException(
          'Request timeout after 10 seconds',
          url: 'https://pub.dev/api/packages/$packageName',
        );
      }
      throw NetworkException(
        'HTTP ${e.message}',
        url: 'https://pub.dev/api/packages/$packageName',
      );
    }
  }
}

extension PubDevClientX on Dio {
  Future<Map<String, dynamic>> fetchJson(
    String url, {
    required String packageName,
  }) async {
    final response = await get(url);

    if (response.statusCode == 404) {
      throw PackageNotFoundException(packageName);
    }

    if (response.statusCode == 429) {
      final retryAfter = _parseRetryAfter(response.headers);
      throw RateLimitException('pub.dev', retryAfter: retryAfter);
    }

    if (response.statusCode != 200) {
      throw NetworkException(
        'HTTP ${response.statusCode}',
        url: 'https://pub.dev/api/packages/$packageName',
        statusCode: response.statusCode,
      );
    }

    return response.data as Map<String, dynamic>;
  }

  Duration _parseRetryAfter(Headers headers) {
    final retryAfter = headers.value('retry-after');
    if (retryAfter != null) {
      final seconds = int.tryParse(retryAfter);
      if (seconds != null) return Duration(seconds: seconds);
    }
    return const Duration(minutes: 1);
  }
}
