/// Discriminated union of all errors that a [PackageDataAggregator] can
/// return as part of a [PackageResult.failure].
///
/// Each variant carries only the data needed to render a meaningful error
/// message or to drive retry logic — no stack traces, no raw exceptions.
/// Use the factory constructors to create instances and exhaustive `switch`
/// expressions to handle them:
///
/// ```dart
/// switch (error) {
///   NotFoundError(:final packageName) => ...,
///   NetworkError(:final message)      => ...,
///   RateLimitError(:final retryAfter) => ...,
///   TimeoutError(:final packageName)  => ...,
/// }
/// ```
///
/// This type lives in the domain layer and has no infrastructure dependency.
/// Infrastructure adapters (API clients, cache) catch their own exceptions and
/// translate them into the appropriate [PackageProviderError] variant before
/// returning a [PackageResult].
sealed class PackageProviderError {
  const PackageProviderError();

  /// The requested package was not found on pub.dev.
  const factory PackageProviderError.notFound(String packageName) =
      NotFoundError;

  /// A network-level failure occurred (DNS, TLS, unexpected HTTP status, etc.).
  const factory PackageProviderError.network(String message) = NetworkError;

  /// The upstream API returned HTTP 429 and the caller should back off.
  const factory PackageProviderError.rateLimit(Duration retryAfter) =
      RateLimitError;

  /// The request exceeded its configured deadline.
  const factory PackageProviderError.timeout(String packageName) = TimeoutError;
}

/// Error variant produced when a package name resolves to no pub.dev entry.
///
/// Maps to HTTP 404 from the pub.dev packages endpoint.
final class NotFoundError extends PackageProviderError {
  /// The package name that could not be found.
  final String packageName;

  /// Creates a [NotFoundError] for [packageName].
  const NotFoundError(this.packageName);
}

/// Error variant produced when a network or HTTP-level failure prevents the
/// request from completing successfully.
///
/// [message] contains a human-readable description suitable for display.
final class NetworkError extends PackageProviderError {
  /// Human-readable description of the network failure.
  final String message;

  /// Creates a [NetworkError] with the provided [message].
  const NetworkError(this.message);
}

/// Error variant produced when an upstream API enforces a rate limit.
///
/// [retryAfter] is the minimum duration the caller should wait before
/// issuing the next request. It is derived from the `Retry-After` response
/// header when present, or estimated from the HTTP 429 context otherwise.
final class RateLimitError extends PackageProviderError {
  /// Minimum wait duration before the next request may be attempted.
  final Duration retryAfter;

  /// Creates a [RateLimitError] with the required [retryAfter] duration.
  const RateLimitError(this.retryAfter);
}

/// Error variant produced when a request exceeds its configured deadline.
///
/// Distinct from [NetworkError] so the presentation layer can suggest
/// increasing the timeout setting rather than reporting a connectivity issue.
final class TimeoutError extends PackageProviderError {
  /// The package name whose fetch timed out.
  final String packageName;

  /// Creates a [TimeoutError] for [packageName].
  const TimeoutError(this.packageName);
}
