import 'package:cura/src/domain/entities/github_metrics.dart';
import 'package:cura/src/domain/entities/package_info.dart';
import 'package:cura/src/domain/entities/vulnerability.dart';

/// The raw, unscored data bundle assembled by [MultiApiAggregator] from
/// three independent sources: pub.dev, GitHub, and OSV.dev.
///
/// This entity is the input to the scoring algorithm ([CalculateScore]) and
/// is cached as a single JSON blob in the `aggregated_cache` SQLite table.
///
/// ### Source availability
/// - [packageInfo] is **mandatory**: its absence propagates as a
///   [PackageResult.failure] before this entity is ever created.
/// - [githubMetrics] is **optional**: `null` when the package has no
///   repository URL or when the GitHub request fails gracefully.
/// - [vulnerabilities] is **optional**: an empty list when the OSV request
///   fails or when no advisories exist for the package.
class AggregatedPackageData {
  /// Metadata from pub.dev. Always present.
  final PackageInfo packageInfo;

  /// Repository metrics from the GitHub API, or `null` when unavailable.
  final GitHubMetrics? githubMetrics;

  /// Known vulnerabilities from OSV.dev. Empty when none found or on failure.
  final List<Vulnerability> vulnerabilities;

  /// Creates an [AggregatedPackageData] with the provided sources.
  const AggregatedPackageData({
    required this.packageInfo,
    this.githubMetrics,
    required this.vulnerabilities,
  });

  /// Returns a copy of this instance with the given fields replaced.
  AggregatedPackageData copyWith({
    PackageInfo? packageInfo,
    GitHubMetrics? githubMetrics,
    List<Vulnerability>? vulnerabilities,
  }) {
    return AggregatedPackageData(
      packageInfo: packageInfo ?? this.packageInfo,
      githubMetrics: githubMetrics ?? this.githubMetrics,
      vulnerabilities: vulnerabilities ?? this.vulnerabilities,
    );
  }

  // ---------------------------------------------------------------------------
  // Convenience accessors
  // ---------------------------------------------------------------------------

  /// Whether GitHub metrics are available for this package.
  bool get hasGitHub => githubMetrics != null;

  /// Whether at least one vulnerability was found.
  bool get hasVulnerabilities => vulnerabilities.isNotEmpty;

  /// Whether any vulnerability is classified as [VulnerabilitySeverity.critical].
  ///
  /// A `true` result triggers an automatic score of 0 in the scoring algorithm.
  bool get hasCriticalVulns =>
      vulnerabilities.any((v) => v.severity == VulnerabilitySeverity.critical);

  /// Shortcut for [PackageInfo.name].
  String get name => packageInfo.name;

  /// Shortcut for [PackageInfo.version].
  String get version => packageInfo.version;
}
