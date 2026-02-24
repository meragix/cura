import 'package:cura/src/domain/value_objects/package_result.dart';

/// Port (output port) for fetching and aggregating package health data from
/// multiple external sources into a single [PackageResult].
///
/// Implementations coordinate three upstream APIs:
///
/// | Source   | Role        | Failure behaviour                         |
/// |----------|-------------|-------------------------------------------|
/// | pub.dev  | Mandatory   | Propagated as [PackageResult.failure]      |
/// | GitHub   | Optional    | Degrades to `null` metrics on failure      |
/// | OSV.dev  | Optional    | Degrades to an empty vulnerability list    |
///
/// ### Known implementations
/// - `MultiApiAggregator` — live HTTP fetches with concurrency pooling.
/// - `CachedAggregator` — SQLite-backed decorator that wraps any aggregator.
///
/// ### Lifecycle
/// Implementations may hold resources (database connections, HTTP clients,
/// concurrency pools). Call [dispose] when the aggregator is no longer needed
/// to release those resources deterministically.
abstract class PackageDataAggregator {
  /// Fetches and aggregates all available data for [packageName].
  ///
  /// Returns [PackageResult.success] with an [AggregatedPackageData] payload
  /// on success. Returns [PackageResult.failure] when pub.dev is unreachable,
  /// the package does not exist, a timeout occurs, or the API rate-limits the
  /// caller.
  ///
  /// GitHub and OSV failures are absorbed silently; their absence is reflected
  /// in the [AggregatedPackageData] fields rather than in a failure result.
  Future<PackageResult> fetchAll(String packageName);

  /// Streams aggregated results for each name in [packageNames].
  ///
  /// The stream completes after all packages have been processed.
  /// Implementations may emit results out of order (e.g. [MultiApiAggregator]
  /// emits as each fetch completes) or in order (e.g. [CachedAggregator]
  /// processes sequentially). Callers must not assume ordering.
  ///
  /// An empty [packageNames] list immediately completes the stream without
  /// emitting any events.
  Stream<PackageResult> fetchMany(List<String> packageNames);

  /// Releases all resources held by this aggregator.
  ///
  /// After this call the aggregator must not be used. Typically invoked in
  /// the `finally` block of the application entry point to ensure cleanup
  /// runs even when the command throws.
  Future<void> dispose();
}
