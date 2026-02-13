/// Basic exception for Cura
abstract class CuraException implements Exception {
  final String message;
  final String? code;
  final String? context;
  final dynamic originalError;
  final StackTrace? stackTrace;

  CuraException(
    this.message, {
    this.code,
    this.context,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => message;
}

/// Package not found on pub.dev
class PackageNotFoundException extends CuraException {
  final String packageName;

  PackageNotFoundException(
    this.packageName, {
    String? context,
  }) : super(
          'Package "$packageName" not found on pub.dev',
          code: 'PACKAGE_NOT_FOUND',
          context: context,
        );
}

/// Erreur réseau (timeout, connexion, etc.)
class NetworkException extends CuraException {
  final String url;
  final int? statusCode;

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

/// Rate limiting error
class RateLimitException extends CuraException {
  final String apiName;
  final DateTime? retryAfter;

  RateLimitException(
    this.apiName, {
    this.retryAfter,
  }) : super(
          'Rate limit exceeded for $apiName API',
          code: 'RATE_LIMIT',
          context: retryAfter != null ? 'Retry after ${retryAfter.difference(DateTime.now()).inSeconds}s' : null,
        );
}

/// JSON parsing error
class ParseException extends CuraException {
  final String field;

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

/// Validation error
class ValidationException extends CuraException {
  final List<String> validationErrors;

  ValidationException(
    this.validationErrors,
  ) : super(
          'Validation failed',
          code: 'VALIDATION_ERROR',
        );
}

/// Cache error
class CacheException extends CuraException {
  CacheException(
    String message, {
    dynamic originalError,
  }) : super(
          message,
          code: 'CACHE_ERROR',
          originalError: originalError,
        );
}

/// Config error
class ConfigException extends CuraException {
  ConfigException(
    String message, {
    dynamic originalError,
  }) : super(
          message,
          code: 'CONFIG_ERROR',
          originalError: originalError,
        );
}
