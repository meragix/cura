import 'package:cura/src/domain/entities/aggregated_package_data.dart';
import 'package:cura/src/domain/value_objects/errors.dart';
import 'package:cura/src/domain/value_objects/result.dart';

sealed class PackageResult {
  const PackageResult();

  const factory PackageResult.success({
    required AggregatedPackageData data,
    required bool fromCache,
  }) = PackageSuccess;

  const factory PackageResult.failure(PackageProviderError error) = PackageFailure;
}

final class PackageSuccess extends PackageResult {
  final AggregatedPackageData data;
  final bool fromCache;

  const PackageSuccess({required this.data, required this.fromCache});
}

final class PackageFailure extends PackageResult {
  final PackageProviderError error;

  const PackageFailure(this.error);
}

extension PackageResultExtensions on PackageResult {
  /// Asynchronous transformation: PackageSuccess -> Result<R>
  ///
  /// Useful to chain an audit or a score calculation after fetching.
  Future<Result<R>> mapAsync<R>(
    Future<Result<R>> Function(AggregatedPackageData data, bool fromCache) mapper,
  ) async {
    return switch (this) {
      PackageSuccess(:final data, :final fromCache) => await mapper(data, fromCache),
      PackageFailure(:final error) => Result.failure(error),
    };
  }

  /// Synchronous transformation: PackageSuccess -> Result<R>
  Result<R> mapValue<R>(
    R Function(AggregatedPackageData data, bool fromCache) mapper,
  ) {
    return switch (this) {
      PackageSuccess(:final data, :final fromCache) => Result.success(mapper(data, fromCache)),
      PackageFailure(:final error) => Result.failure(error),
    };
  }
}
