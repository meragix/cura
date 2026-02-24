import 'dart:io';

import 'package:dio/dio.dart';

/// Factory and utility class for building configured [Dio] HTTP clients.
///
/// All Cura API integrations (pub.dev, GitHub, OSV) obtain their [Dio]
/// instance from [buildClient] so timeouts, the User-Agent header, retry
/// logic, and optional verbose logging are applied consistently.
///
/// The class is uninstantiable; use the static members directly.
class HttpHelper {
  const HttpHelper._();

  /// Creates a fully configured [Dio] client.
  ///
  /// The returned client has:
  /// - Standard connect / receive / send timeouts (defaults: 10 s / 30 s / 30 s).
  /// - A `User-Agent: Cura/<version>` header on every request.
  /// - A [RetryInterceptor] that retries transient failures up to 3 times with
  ///   exponential back-off (500 ms → 1 s → 2 s).
  /// - An optional [LoggingInterceptor] when [enableLogging] is `true`.
  ///
  /// Extra [headers] are merged with (and may override) the defaults.
  static Dio buildClient({
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    Map<String, String>? headers,
    bool enableLogging = false,
  }) {
    final dio = Dio(
      BaseOptions(
        connectTimeout: connectTimeout ?? const Duration(seconds: 10),
        receiveTimeout: receiveTimeout ?? const Duration(seconds: 30),
        sendTimeout: sendTimeout ?? const Duration(seconds: 30),
        headers: {
          'User-Agent': 'Cura/${_appVersion()}',
          ...?headers,
        },
      ),
    );

    // Logging is added first so retried requests also appear in the log.
    if (enableLogging) {
      dio.interceptors.add(LoggingInterceptor());
    }

    // Retry is added after logging so every attempt is logged.
    dio.interceptors.add(RetryInterceptor(dio: dio));

    return dio;
  }

  /// Returns `true` when [response] signals rate-limiting (HTTP 429).
  static bool isRateLimited(Response response) => response.statusCode == 429;

  /// Parses standard `x-ratelimit-*` response headers into a [RateLimitInfo].
  ///
  /// Returns `null` when any of the three required headers
  /// (`x-ratelimit-remaining`, `x-ratelimit-limit`, `x-ratelimit-reset`) is
  /// absent.
  static RateLimitInfo? parseRateLimitHeaders(Headers headers) {
    final remaining = headers.value('x-ratelimit-remaining');
    final limit = headers.value('x-ratelimit-limit');
    final reset = headers.value('x-ratelimit-reset');

    if (remaining == null || limit == null || reset == null) return null;

    return RateLimitInfo(
      remaining: int.parse(remaining),
      limit: int.parse(limit),
      // x-ratelimit-reset is Unix epoch in seconds.
      resetAt: DateTime.fromMillisecondsSinceEpoch(int.parse(reset) * 1000),
    );
  }

  /// Extracts the `Retry-After` wait duration from a rate-limit response.
  ///
  /// Supports both integer (seconds) and HTTP-date header formats as defined
  /// in RFC 7231 §7.1.3. Returns `null` when the header is absent or cannot
  /// be parsed.
  static Duration? getRetryAfter(Response response) {
    final value = response.headers.value('retry-after');
    if (value == null) return null;

    final seconds = int.tryParse(value);
    if (seconds != null) return Duration(seconds: seconds);

    try {
      return HttpDate.parse(value).difference(DateTime.now());
    } catch (_) {
      return null;
    }
  }

  /// Resolves the application version embedded at compile time via
  /// `--dart-define=APP_VERSION=x.y.z`. Falls back to `1.0.0` when not set.
  static String _appVersion() =>
      const String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
}

// =============================================================================
// Interceptors
// =============================================================================

/// Dio interceptor that transparently retries transient HTTP failures with
/// exponential back-off.
///
/// ### Retryable conditions
/// | Category        | Criterion                           |
/// |-----------------|-------------------------------------|
/// | Timeouts        | Connection / send / receive timeout  |
/// | Connectivity    | `DioExceptionType.connectionError`   |
/// | Server errors   | HTTP 5xx                             |
/// | Rate limiting   | HTTP 429                             |
///
/// ### Retry mechanics
/// 1. The attempt counter is stored in [RequestOptions.extra] under
///    `retry_attempt` so it survives re-queuing through the interceptor stack.
/// 2. The **original** [Dio] instance is reused for retries (`_dio.fetch`) so
///    every interceptor (auth headers, logging) participates in each attempt.
/// 3. After [maxRetries] exhausted attempts the original error is forwarded
///    to the next handler unchanged.
class RetryInterceptor extends Interceptor {
  final Dio _dio;
  final int _maxRetries;
  final List<Duration> _retryDelays;

  static const _kAttemptKey = 'retry_attempt';

  /// Default back-off schedule: 500 ms → 1 s → 2 s.
  static const List<Duration> defaultDelays = [
    Duration(milliseconds: 500),
    Duration(seconds: 1),
    Duration(seconds: 2),
  ];

  /// Creates a [RetryInterceptor].
  ///
  /// [dio] **must** be the same [Dio] instance this interceptor is attached
  /// to. Passing a different instance would bypass auth and logging
  /// interceptors on retry.
  ///
  /// [maxRetries] defaults to 3. [retryDelays] defaults to [defaultDelays];
  /// the last entry is reused when the attempt index exceeds the list length.
  RetryInterceptor({
    required Dio dio,
    int maxRetries = 3,
    List<Duration>? retryDelays,
  })  : _dio = dio,
        _maxRetries = maxRetries,
        _retryDelays = retryDelays ?? defaultDelays;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRetry(err)) return handler.next(err);

    final attempt = err.requestOptions.extra[_kAttemptKey] as int? ?? 0;
    if (attempt >= _maxRetries) return handler.next(err);

    final delay = _retryDelays[attempt.clamp(0, _retryDelays.length - 1)];
    await Future.delayed(delay);

    try {
      final options = err.requestOptions;
      options.extra[_kAttemptKey] = attempt + 1;
      final response = await _dio.fetch(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  static bool _shouldRetry(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }

    final code = error.response?.statusCode;
    return code != null && (code == 429 || (code >= 500 && code < 600));
  }
}

/// Dio interceptor that prints HTTP traffic to stdout for debugging.
///
/// Attach this interceptor only in verbose mode (see [HttpHelper.buildClient]'s
/// `enableLogging` flag) to avoid cluttering normal CLI output.
///
/// Output format:
/// - **Request**: `→ METHOD URI` and optionally `  Body: <data>`.
/// - **Response**: `← STATUS URI`.
/// - **Error**: `✗ METHOD URI` followed by `  Error: <message>`.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('→ ${options.method} ${options.uri}');
    if (options.data != null) print('  Body: ${options.data}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('✗ ${err.requestOptions.method} ${err.requestOptions.uri}');
    print('  Error: ${err.message}');
    handler.next(err);
  }
}

// =============================================================================
// Value objects
// =============================================================================

/// Parsed representation of the standard `x-ratelimit-*` response headers.
class RateLimitInfo {
  /// Number of requests remaining in the current window.
  final int remaining;

  /// Total request quota for the current window.
  final int limit;

  /// The UTC instant at which the quota resets.
  final DateTime resetAt;

  /// Creates a [RateLimitInfo] from parsed header values.
  const RateLimitInfo({
    required this.remaining,
    required this.limit,
    required this.resetAt,
  });

  /// Whether the remaining quota has been exhausted.
  bool get isLimited => remaining <= 0;

  /// Time remaining until the quota resets.
  ///
  /// May return a negative [Duration] if [resetAt] is in the past.
  Duration get timeUntilReset => resetAt.difference(DateTime.now());

  /// Percentage of the total quota already consumed (0–100).
  double get usagePercentage => (limit - remaining) / limit * 100;
}
