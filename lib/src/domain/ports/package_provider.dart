import 'package:cura/src/domain/value_objects/package_result.dart';

/// Port: Package Provider (fetching abstraction)
///
/// The infrastructure implements this port to fetch from:
/// - pub.dev API (via HTTP)
/// - Local cache (via SQLite)
/// - Mock (for testing)
abstract class PackageProvider {
  /// Fetch multiple packages in streaming (reactive)
  ///
  /// Guarantees:
  /// - Results yielded as soon as available (FIFO completion)
  /// - Stream closes automatically
  /// - Concurrency managed internally (Pool)
  Stream<PackageResult> fetchPackages(List<String> packageNames);

  /// Fetch a single package (for `cura view`)
  Future<PackageResult> fetchPackage(String packageName);

  /// Cleanup of resources (Pool, HTTP client)
  Future<void> dispose();
}
