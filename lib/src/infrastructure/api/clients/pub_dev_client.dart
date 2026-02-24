import 'package:cura/src/domain/entities/package_info.dart';
import 'package:cura/src/domain/value_objects/exception.dart';
import 'package:cura/src/shared/constants/api_constants.dart';
import 'package:dio/dio.dart';

/// HTTP client for the pub.dev package registry API.
///
/// API reference: https://github.com/dart-lang/pub-dev/blob/master/doc/api.md
///
/// ### Endpoints used
/// | Method | Path                              | Purpose                          |
/// |--------|-----------------------------------|----------------------------------|
/// | GET    | `/api/packages/{name}`            | Version, pubspec, publisher tags |
/// | GET    | `/api/packages/{name}/score`      | Pana points, likes, tags         |
///
/// Both endpoints are fetched in parallel for every package because the
/// score endpoint is required to build a complete [PackageInfo]. A failure on
/// either endpoint propagates as a [CuraException] subtype.
///
/// ### Exception mapping
/// | HTTP status | Exception thrown            |
/// |-------------|-----------------------------|
/// | 404         | [PackageNotFoundException]  |
/// | 429         | [RateLimitException]        |
/// | other 4xx/5xx | [NetworkException]        |
/// | Timeout     | [NetworkException]          |
/// | Parse error | [ParseException]            |
class PubDevApiClient {
  final Dio _dio;

  /// Creates a [PubDevApiClient] backed by [dio].
  PubDevApiClient(this._dio);

  /// Fetches and parses complete pub.dev metadata for [packageName].
  ///
  /// Sends the packages and score requests concurrently, then combines their
  /// responses via [PackageInfo.fromPubDevJson].
  ///
  /// Throws:
  /// - [PackageNotFoundException] when the package does not exist (HTTP 404).
  /// - [RateLimitException] when pub.dev enforces a rate limit (HTTP 429).
  /// - [NetworkException] for any other HTTP or connectivity error.
  /// - [ParseException] when the response body cannot be decoded.
  Future<PackageInfo> getPackageInfo(String packageName) async {
    final baseUrl = '${ApiConstants.pubDevApiUrl}/packages';

    try {
      final (infoJson, scoreJson) = await (
        _dio.fetchJson('$baseUrl/$packageName', packageName: packageName),
        _dio.fetchJson(
          '$baseUrl/$packageName/score',
          packageName: packageName,
        ),
      ).wait;

      try {
        return PackageInfo.fromPubDevJson(
          infoJson: infoJson,
          scoreJson: scoreJson,
        );
      } catch (e) {
        throw ParseException(
          'Invalid JSON response from pub.dev for "$packageName"',
          field: 'body',
          originalError: e,
        );
      }
    } on DioException catch (e) {
      final url = '$baseUrl/$packageName';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw NetworkException(
          'Request to pub.dev timed out',
          url: url,
        );
      }
      throw NetworkException(
        'pub.dev request failed: ${e.message}',
        url: url,
        originalError: e,
      );
    }
  }
}

/// Private Dio extension that centralises response-status handling for all
/// pub.dev GET requests made by [PubDevApiClient].
///
/// [fetchJson] issues the GET request, maps HTTP status codes to the
/// appropriate [CuraException] subtype, and returns the decoded JSON body
/// on success.
extension PubDevClientX on Dio {
  /// Sends `GET [url]` and returns the decoded JSON body.
  ///
  /// [packageName] is used to populate error messages so callers do not
  /// need to reconstruct it from the URL.
  ///
  /// Throws:
  /// - [PackageNotFoundException] on HTTP 404.
  /// - [RateLimitException] on HTTP 429, with [_parseRetryAfter] applied to
  ///   the `Retry-After` header.
  /// - [NetworkException] on any other non-200 status.
  Future<Map<String, dynamic>> fetchJson(
    String url, {
    required String packageName,
  }) async {
    final response = await get(url);

    if (response.statusCode == 404) {
      throw PackageNotFoundException(packageName);
    }

    if (response.statusCode == 429) {
      throw RateLimitException(
        'pub.dev',
        retryAfter: _parseRetryAfter(response.headers),
      );
    }

    if (response.statusCode != 200) {
      throw NetworkException(
        'pub.dev returned HTTP ${response.statusCode}',
        url: url,
        statusCode: response.statusCode,
      );
    }

    return response.data as Map<String, dynamic>;
  }

  /// Parses the `Retry-After` response header as a [Duration].
  ///
  /// Accepts integer seconds only (the format pub.dev uses). Falls back to
  /// one minute when the header is absent or unparseable.
  Duration _parseRetryAfter(Headers headers) {
    final value = headers.value('retry-after');
    if (value != null) {
      final seconds = int.tryParse(value);
      if (seconds != null) return Duration(seconds: seconds);
    }
    return const Duration(minutes: 1);
  }
}
