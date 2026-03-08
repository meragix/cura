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

  /// Creates a successful result carrying [data], its cache provenance, and
  /// the number of HTTP requests issued to external APIs.
  const factory PackageResult.success({
    required AggregatedPackageData data,
    required bool fromCache,
    int requestCount,
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

  /// Number of HTTP requests issued to external APIs for this package.
  ///
  /// `0` when [fromCache] is `true`. When fetched live, reflects the sum of
  /// pub.dev, GitHub (if a repository URL is present), and OSV.dev calls
  /// that were attempted. Computed by [MultiApiAggregator], the only layer
  /// with knowledge of the per-package request topology.
  final int requestCount;

  /// Creates a [PackageSuccess] with the provided fields.
  const PackageSuccess({
    required this.data,
    required this.fromCache,
    this.requestCount = 0,
  });
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
    Future<Result<R>> Function(
            AggregatedPackageData data, bool fromCache, int requestCount)
        mapper,
  ) async {
    return switch (this) {
      PackageSuccess(:final data, :final fromCache, :final requestCount) =>
        await mapper(data, fromCache, requestCount),
      PackageFailure(:final error) => Result.failure(error),
    };
  }

  /// Synchronously transforms a [PackageSuccess] value, keeping the
  /// [Result] wrapper.
  ///
  /// When `this` is a [PackageFailure] the error is forwarded and [mapper]
  /// is never called.
  Result<R> mapValue<R>(
    R Function(AggregatedPackageData data, bool fromCache, int requestCount)
        mapper,
  ) {
    return switch (this) {
      PackageSuccess(:final data, :final fromCache, :final requestCount) =>
        Result.success(mapper(data, fromCache, requestCount)),
      PackageFailure(:final error) => Result.failure(error),
    };
  }
}
