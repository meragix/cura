import 'package:cura/src/domain/value_objects/errors.dart';

sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(PackageProviderError error) = Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get valueOrNull => switch (this) {
        Success(:final value) => value,
        _ => null,
      };

  PackageProviderError? get errorOrNull => switch (this) {
        Failure(:final error) => error,
        _ => null,
      };
}

final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

final class Failure<T> extends Result<T> {
  final PackageProviderError error;
  const Failure(this.error);
}

extension ResultExtensions<T> on Result<T> {
  /// Asynchronous transformation helper
  Future<Result<R>> mapAsync<R>(
    Future<Result<R>> Function(T value) mapper,
  ) async {
    return switch (this) {
      Success(:final value) => await mapper(value),
      Failure(:final error) => Result.failure(error),
    };
  }

  /// Synchronous map (preserves the Result wrapper)
  Result<R> mapValue<R>(R Function(T value) mapper) {
    return switch (this) {
      Success(:final value) => Result.success(mapper(value)),
      Failure(:final error) => Result.failure(error),
    };
  }
}

/// Helper for nested Results (Monadic Flatten)
extension ResultFlatten<T> on Result<Result<T>> {
  Result<T> flatten() {
    return switch (this) {
      Success(:final value) => value,
      Failure(:final error) => Result.failure(error),
    };
  }
}
