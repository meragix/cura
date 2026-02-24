import 'package:cura/src/domain/value_objects/errors.dart';

/// A generic discriminated union representing either a successful value of
/// type [T] or a [PackageProviderError].
///
/// `Result` is the standard return type for domain use-case outputs. It
/// forces callers to handle both the success and failure paths exhaustively
/// through Dart's `sealed` class pattern.
///
/// ### Design note — fixed error type
/// The error branch is typed as [PackageProviderError] rather than a generic
/// `E` parameter. This is an intentional constraint: Cura's domain has a
/// single, well-defined set of provider errors, and a second type parameter
/// would add complexity without benefit for this codebase.
///
/// ### Construction
/// ```dart
/// // Success
/// final r = Result.success(someValue);
///
/// // Failure
/// final r = Result.failure(PackageProviderError.notFound('dio'));
/// ```
///
/// ### Consumption
/// Prefer exhaustive `switch` expressions over [isSuccess] / [isFailure]
/// to guarantee all branches are handled at compile time:
/// ```dart
/// final output = switch (result) {
///   Success(:final value) => process(value),
///   Failure(:final error) => handleError(error),
/// };
/// ```
sealed class Result<T> {
  const Result();

  /// Creates a successful result wrapping [value].
  const factory Result.success(T value) = Success<T>;

  /// Creates a failed result wrapping [error].
  const factory Result.failure(PackageProviderError error) = Failure<T>;

  /// Whether this result holds a value.
  bool get isSuccess => this is Success<T>;

  /// Whether this result holds an error.
  bool get isFailure => this is Failure<T>;

  /// Returns the wrapped value, or `null` when this is a [Failure].
  T? get valueOrNull => switch (this) {
        Success(:final value) => value,
        _ => null,
      };

  /// Returns the wrapped error, or `null` when this is a [Success].
  PackageProviderError? get errorOrNull => switch (this) {
        Failure(:final error) => error,
        _ => null,
      };
}

/// The success variant of [Result], carrying a value of type [T].
final class Success<T> extends Result<T> {
  /// The successful output value.
  final T value;

  /// Creates a [Success] wrapping [value].
  const Success(this.value);
}

/// The failure variant of [Result], carrying a [PackageProviderError].
final class Failure<T> extends Result<T> {
  /// The error that caused the operation to fail.
  final PackageProviderError error;

  /// Creates a [Failure] wrapping [error].
  const Failure(this.error);
}

/// Transformation helpers for [Result].
extension ResultExtensions<T> on Result<T> {
  /// Asynchronously transforms a [Success] value into a new [Result].
  ///
  /// When `this` is a [Failure] the error is forwarded unchanged and [mapper]
  /// is never called. Useful for chaining async operations that themselves
  /// return a [Result]:
  ///
  /// ```dart
  /// final scored = await fetched.mapAsync(
  ///   (data, _) => scoreCalculator.run(data),
  /// );
  /// ```
  Future<Result<R>> mapAsync<R>(
    Future<Result<R>> Function(T value) mapper,
  ) async {
    return switch (this) {
      Success(:final value) => await mapper(value),
      Failure(:final error) => Result.failure(error),
    };
  }

  /// Synchronously transforms a [Success] value, keeping the [Result] wrapper.
  ///
  /// When `this` is a [Failure] the error is forwarded unchanged and [mapper]
  /// is never called.
  Result<R> mapValue<R>(R Function(T value) mapper) {
    return switch (this) {
      Success(:final value) => Result.success(mapper(value)),
      Failure(:final error) => Result.failure(error),
    };
  }
}

/// Flattening helper for nested [Result] types.
///
/// When an operation returns `Result<Result<T>>` (e.g. after [mapValue] with
/// a function that itself returns a [Result]), [flatten] collapses the outer
/// layer:
///
/// ```dart
/// final nested = Result.success(Result.success(42)); // Result<Result<int>>
/// final flat   = nested.flatten();                   // Result<int> = Success(42)
/// ```
extension ResultFlatten<T> on Result<Result<T>> {
  /// Unwraps one level of [Result] nesting.
  ///
  /// - `Success(Success(v))` → `Success(v)`
  /// - `Success(Failure(e))` → `Failure(e)`
  /// - `Failure(e)`          → `Failure(e)`
  Result<T> flatten() {
    return switch (this) {
      Success(:final value) => value,
      Failure(:final error) => Result.failure(error),
    };
  }
}
