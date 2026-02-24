import 'dart:io';

import 'package:dio/dio.dart';

/// HTTP Helpers : Utilities pour requêtes HTTP
class HttpHelper {
  const HttpHelper._();

  /// Build Dio client with standard configuration
  static Dio buildClient({
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    Map<String, String>? headers,
    bool enableLogging = false,
  }) {
    final dio = Dio(
      BaseOptions(
        connectTimeout: connectTimeout ?? Duration(seconds: 10),
        receiveTimeout: receiveTimeout ?? Duration(seconds: 30),
        sendTimeout: sendTimeout ?? Duration(seconds: 30),
        headers: {
          'User-Agent': 'Cura/${_getVersion()}',
          ...?headers,
        },
      ),
    );

    // Add interceptors
    if (enableLogging) {
      dio.interceptors.add(_buildLoggingInterceptor());
    }

    dio.interceptors.add(_buildRetryInterceptor());

    return dio;
  }

  /// Build retry interceptor
  static Interceptor _buildRetryInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        if (_shouldRetry(error)) {
          final retryCount = error.requestOptions.extra['retry_count'] as int? ?? 0;

          if (retryCount < 3) {
            // Wait before retry (exponential backoff)
            final delay = Duration(
              milliseconds: 500 * (1 << retryCount), // 500ms, 1s, 2s
            );
            await Future.delayed(delay);

            // Retry request
            error.requestOptions.extra['retry_count'] = retryCount + 1;

            try {
              final response = await Dio().fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
        }

        return handler.next(error);
      },
    );
  }

  /// Build logging interceptor
  static Interceptor _buildLoggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        print('→ ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('← ${response.statusCode} ${response.requestOptions.uri}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('✗ ${error.requestOptions.method} ${error.requestOptions.uri}');
        print('  Error: ${error.message}');
        return handler.next(error);
      },
    );
  }

  /// Check if error should trigger retry
  static bool _shouldRetry(DioException error) {
    // Retry on timeout
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return true;
    }

    // Retry on connection errors
    if (error.type == DioExceptionType.connectionError) {
      return true;
    }

    // Retry on 5xx server errors
    final statusCode = error.response?.statusCode;
    if (statusCode != null && statusCode >= 500 && statusCode < 600) {
      return true;
    }

    // Retry on 429 (rate limit)
    if (statusCode == 429) {
      return true;
    }

    return false;
  }

  /// Parse rate limit headers
  static RateLimitInfo? parseRateLimitHeaders(Headers headers) {
    final remaining = headers.value('x-ratelimit-remaining');
    final limit = headers.value('x-ratelimit-limit');
    final reset = headers.value('x-ratelimit-reset');

    if (remaining == null || limit == null || reset == null) {
      return null;
    }

    return RateLimitInfo(
      remaining: int.parse(remaining),
      limit: int.parse(limit),
      resetAt: DateTime.fromMillisecondsSinceEpoch(
        int.parse(reset) * 1000,
      ),
    );
  }

  /// Check if response indicates rate limiting
  static bool isRateLimited(Response response) {
    return response.statusCode == 429;
  }

  /// Extract retry-after duration
  static Duration? getRetryAfter(Response response) {
    final retryAfter = response.headers.value('retry-after');
    if (retryAfter == null) return null;

    // Try parsing as seconds
    final seconds = int.tryParse(retryAfter);
    if (seconds != null) {
      return Duration(seconds: seconds);
    }

    // Try parsing as HTTP date
    try {
      final date = HttpDate.parse(retryAfter);
      return date.difference(DateTime.now());
    } catch (e) {
      return null;
    }
  }

  /// Get app version (for User-Agent)
  static String _getVersion() {
    return const String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
  }
}

/// Rate limit information
class RateLimitInfo {
  final int remaining;
  final int limit;
  final DateTime resetAt;

  const RateLimitInfo({
    required this.remaining,
    required this.limit,
    required this.resetAt,
  });

  /// Check if rate limited
  bool get isLimited => remaining <= 0;

  /// Time until reset
  Duration get timeUntilReset => resetAt.difference(DateTime.now());

  /// Usage percentage
  double get usagePercentage => ((limit - remaining) / limit * 100);
}
