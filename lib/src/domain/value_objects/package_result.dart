import 'package:cura/src/domain/entities/aggregated_package_data.dart';
import 'package:cura/src/domain/value_objects/errors.dart';
import 'package:cura/src/domain/value_objects/result.dart';

/// The direct output of [PackageDataAggregator.fetchAll]: either a fully
/// assembled [AggregatedPackageData] bundle or a [PackageProviderError].
///
/// [PackageResult] is a specialised discriminated union tailored to the
/// aggregation layer. It carries one extra field on the success path —
/// [PackageSuccess.fromCache] — that a plain `Result<AggregatedPackageData>`
/// would not provide without a wrapper type.
///
/// Use [PackageResultExtensions.mapAsync] or [PackageResultExtensions.mapValue]
/// to chain scoring or audit logic without pattern-matching boilerplate:
///
/// ```dart
/// final auditResult = await packageResult.mapAsync(
///   (data, fromCache) => scoreAndAudit(data, fromCache),
/// );
/// ```
sealed class PackageResult {
  const PackageResult();

  /// Creates a successful result carrying [data] and its cache provenance.
  const factory PackageResult.success({
    required AggregatedPackageData data,
    required bool fromCache,
  }) = PackageSuccess;

  /// Creates a failed result carrying a [PackageProviderError].
  const factory PackageResult.failure(PackageProviderError error) =
      PackageFailure;
}

/// The success variant of [PackageResult].
final class PackageSuccess extends PackageResult {
  /// The aggregated pub.dev + GitHub + OSV data for the package.
  final AggregatedPackageData data;

  /// Whether this result was served from the local JSON file cache.
  ///
  /// `true` means no upstream API was called during this request.
  /// Passed through to [PackageAuditResult.fromCache] so the UI can display
  /// a cache indicator.
  final bool fromCache;

  /// Creates a [PackageSuccess] with the provided [data] and [fromCache] flag.
  const PackageSuccess({required this.data, required this.fromCache});
}

/// The failure variant of [PackageResult].
final class PackageFailure extends PackageResult {
  /// The error that prevented the aggregation from completing.
  final PackageProviderError error;

  /// Creates a [PackageFailure] wrapping [error].
  const PackageFailure(this.error);
}

/// Transformation helpers for [PackageResult].
extension PackageResultExtensions on PackageResult {
  /// Asynchronously transforms a [PackageSuccess] into a [Result].
  ///
  /// [mapper] receives both [AggregatedPackageData] and the [fromCache] flag
  /// so downstream operations (scoring, auditing) can propagate the cache
  /// provenance to their own outputs.
  ///
  /// When `this` is a [PackageFailure] the error is forwarded as
  /// `Result.failure` and [mapper] is never called.
  Future<Result<R>> mapAsync<R>(
    Future<Result<R>> Function(AggregatedPackageData data, bool fromCache)
        mapper,
  ) async {
    return switch (this) {
      PackageSuccess(:final data, :final fromCache) =>
        await mapper(data, fromCache),
      PackageFailure(:final error) => Result.failure(error),
    };
  }

  /// Synchronously transforms a [PackageSuccess] value, keeping the
  /// [Result] wrapper.
  ///
  /// When `this` is a [PackageFailure] the error is forwarded and [mapper]
  /// is never called.
  Result<R> mapValue<R>(
    R Function(AggregatedPackageData data, bool fromCache) mapper,
  ) {
    return switch (this) {
      PackageSuccess(:final data, :final fromCache) =>
        Result.success(mapper(data, fromCache)),
      PackageFailure(:final error) => Result.failure(error),
    };
  }
}
