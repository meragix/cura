import 'package:dio/dio.dart';

/// Interceptor : Retry automatique avec backoff exponentiel
class RetryInterceptor extends Interceptor {
  final Dio _dio;
  final int _maxRetries;
  final List<Duration> _retryDelays;

  RetryInterceptor({
    required Dio dio,
    int maxRetries = 3,
    List<Duration>? retryDelays,
  })  : _dio = dio,
        _maxRetries = maxRetries,
        _retryDelays = retryDelays ??
            [
              Duration(milliseconds: 500),
              Duration(seconds: 1),
              Duration(seconds: 2),
            ];

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Retry seulement pour erreurs réseau temporaires
    if (!_shouldRetry(err)) {
      return handler.next(err);
    }

    final attempt = err.requestOptions.extra['retry_attempt'] as int? ?? 0;

    if (attempt >= _maxRetries) {
      return handler.next(err);
    }

    // Attendre avant retry
    final delay = _retryDelays[attempt.clamp(0, _retryDelays.length - 1)];
    await Future.delayed(delay);

    // Retry la requête
    try {
      final options = err.requestOptions;
      options.extra['retry_attempt'] = attempt + 1;

      final response = await _dio.fetch(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  bool _shouldRetry(DioException error) {
    // Retry pour :
    // - Timeout
    // - Connection errors
    // - 5xx server errors
    // - 429 rate limit (avec backoff)

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return true;
    }

    if (error.type == DioExceptionType.connectionError) {
      return true;
    }

    final statusCode = error.response?.statusCode;
    if (statusCode != null) {
      // Server errors (5xx)
      if (statusCode >= 500 && statusCode < 600) {
        return true;
      }

      // Rate limit (429)
      if (statusCode == 429) {
        return true;
      }
    }

    return false;
  }
}
