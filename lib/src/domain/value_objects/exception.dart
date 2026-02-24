/// Base class for all exceptions thrown within the Cura domain and
/// infrastructure layers.
///
/// Extends [Exception] so callers can catch either [CuraException] specifically
/// or the broader [Exception] type. Every subclass carries a [code] token that
/// uniquely identifies the error category and is suitable for programmatic
/// handling (e.g. in tests or error-handler switches).
///
/// ### `toString()` contract
/// [toString] returns only [message] — a clean, user-facing sentence with no
/// technical decoration. [code], [context], and [originalError] are available
/// as fields for logging or debugging but are intentionally excluded from the
/// default string representation to keep CLI output readable.
///
/// ### Propagation flow
/// Infrastructure adapters throw concrete [CuraException] subclasses.
/// The application layer (`MultiApiAggregator`) catches them and converts
/// them into [PackageProviderError] value objects for functional error
/// handling through [PackageResult] and [Result].
abstract class CuraException implements Exception {
  /// Human-readable description of the error, suitable for direct display.
  final String message;

  /// Machine-readable error category token (e.g. `PACKAGE_NOT_FOUND`).
  ///
  /// `null` when no specific code applies. Used for programmatic handling
  /// and structured logging.
  final String? code;

  /// Additional contextual information to assist debugging (e.g. the URL
  /// that was requested, or the JSON field that failed to parse).
  ///
  /// `null` when no extra context is available.
  final String? context;

  /// The underlying error or exception that caused this one, if any.
  ///
  /// Typed as `dynamic` to accept both [Error] and [Exception] subtypes
  /// without requiring an additional wrapper.
  final dynamic originalError;

  /// The stack trace captured at the throw site, or `null` when not provided.
  final StackTrace? stackTrace;

  /// Creates a [CuraException] with the required [message] and optional
  /// diagnostic fields.
  CuraException(
    this.message, {
    this.code,
    this.context,
    this.originalError,
    this.stackTrace,
  });

  /// Returns [message] only.
  ///
  /// Diagnostic fields ([code], [context], [originalError]) are omitted so
  /// that this value is safe to display directly in CLI output without leaking
  /// internal state.
  @override
  String toString() => message;
}

/// Thrown when a package name resolves to no entry on pub.dev (HTTP 404).
///
/// The [message] is pre-formatted as
/// `Package "<name>" not found on pub.dev`.
class PackageNotFoundException extends CuraException {
  /// The package name that could not be found.
  final String packageName;

  /// Creates a [PackageNotFoundException] for [packageName].
  ///
  /// An optional [context] string can provide additional debugging detail
  /// (e.g. the full request URL).
  PackageNotFoundException(
    this.packageName, {
    String? context,
  }) : super(
          'Package "$packageName" not found on pub.dev',
          code: 'PACKAGE_NOT_FOUND',
          context: context,
        );
}

/// Thrown when a network request fails due to connectivity, TLS, or an
/// unexpected HTTP status code.
///
/// [url] and [statusCode] are preserved for structured logging even though
/// they are not included in [toString].
class NetworkException extends CuraException {
  /// The URL that was being requested when the failure occurred.
  final String url;

  /// The HTTP status code returned by the server, or `null` for connection-
  /// level failures (DNS, timeout, TLS).
  final int? statusCode;

  /// Creates a [NetworkException].
  ///
  /// [url] is appended as the [context] field automatically.
  NetworkException(
    String message, {
    required this.url,
    this.statusCode,
    dynamic originalError,
  }) : super(
          message,
          code: 'NETWORK_ERROR',
          context: 'URL: $url',
          originalError: originalError,
        );
}

/// Thrown when an upstream API responds with HTTP 429 (Too Many Requests).
///
/// [retryAfter] should be respected by the caller before issuing the next
/// request. The [RetryInterceptor] in `HttpHelper` handles automatic back-off
/// for most cases; this exception is thrown only when all retry attempts are
/// exhausted.
class RateLimitException extends CuraException {
  /// The name of the API that enforced the rate limit (e.g. `GitHub`).
  final String apiName;

  /// The minimum wait duration before the next request may be issued.
  ///
  /// `null` when the upstream response did not include a `Retry-After` header.
  final Duration? retryAfter;

  /// Creates a [RateLimitException] for [apiName].
  RateLimitException(
    this.apiName, {
    this.retryAfter,
  }) : super(
          'Rate limit exceeded for $apiName API',
          code: 'RATE_LIMIT',
          context:
              retryAfter != null ? 'Retry after $retryAfter' : null,
        );
}

/// Thrown when a JSON response cannot be decoded into the expected shape.
///
/// [field] identifies the specific key or path that caused the failure,
/// making it straightforward to pinpoint API contract changes.
class ParseException extends CuraException {
  /// The JSON key or path that could not be parsed.
  final String field;

  /// Creates a [ParseException] for the problematic [field].
  ParseException(
    String message, {
    required this.field,
    dynamic originalError,
  }) : super(
          message,
          code: 'PARSE_ERROR',
          context: 'Field: $field',
          originalError: originalError,
        );
}

/// Thrown when one or more configuration or input values fail validation rules.
///
/// [validationErrors] lists every individual rule violation so callers can
/// display all failures at once rather than one at a time.
class ValidationException extends CuraException {
  /// Individual validation-rule violation messages.
  final List<String> validationErrors;

  /// Creates a [ValidationException] from a non-empty list of
  /// [validationErrors].
  ValidationException(
    this.validationErrors,
  ) : super(
          'Validation failed',
          code: 'VALIDATION_ERROR',
        );
}

/// Thrown when a cache operation fails (read, write, or IO error).
///
/// Cache failures are typically non-fatal: the caller should degrade
/// gracefully by fetching fresh data from the upstream API.
class CacheException extends CuraException {
  /// Creates a [CacheException] with the provided [message].
  CacheException(
    String message, {
    dynamic originalError,
  }) : super(
          message,
          code: 'CACHE_ERROR',
          originalError: originalError,
        );
}

/// Thrown when reading or writing the YAML configuration file fails.
class ConfigException extends CuraException {
  /// Creates a [ConfigException] with the provided [message].
  ConfigException(
    String message, {
    dynamic originalError,
  }) : super(
          message,
          code: 'CONFIG_ERROR',
          originalError: originalError,
        );
}
