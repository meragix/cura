sealed class PackageProviderError {
  const PackageProviderError();

  const factory PackageProviderError.notFound(String packageName) =
      NotFoundError;
  const factory PackageProviderError.network(String message) = NetworkError;
  const factory PackageProviderError.rateLimit(Duration retryAfter) =
      RateLimitError;
  const factory PackageProviderError.timeout(String packageName) = TimeoutError;
}

final class NotFoundError extends PackageProviderError {
  final String packageName;
  const NotFoundError(this.packageName);
}

final class NetworkError extends PackageProviderError {
  final String message;
  const NetworkError(this.message);
}

final class RateLimitError extends PackageProviderError {
  final Duration retryAfter;
  const RateLimitError(this.retryAfter);
}

final class TimeoutError extends PackageProviderError {
  final String packageName;
  const TimeoutError(this.packageName);
}
