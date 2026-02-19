import 'package:cura/src/domain/entities/github_metrics.dart';
import 'package:cura/src/domain/entities/package_info.dart';
import 'package:cura/src/domain/entities/vulnerability.dart';

/// Entity : Données agrégées depuis pub.dev + GitHub + OSV
class AggregatedPackageData {
  /// Données pub.dev (REQUIRED)
  final PackageInfo packageInfo;

  /// Métriques GitHub (OPTIONAL - null si pas de repo)
  final GitHubMetrics? githubMetrics;

  /// Vulnérabilités OSV (OPTIONAL - [] si aucune ou API fail)
  final List<Vulnerability> vulnerabilities;

  const AggregatedPackageData({
    required this.packageInfo,
    this.githubMetrics,
    required this.vulnerabilities,
  });

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

  /// Helpers
  bool get hasGitHub => githubMetrics != null;
  bool get hasVulnerabilities => vulnerabilities.isNotEmpty;
  bool get hasCriticalVulns => vulnerabilities.any(
        (v) => v.severity == VulnerabilitySeverity.critical,
      );

  String get name => packageInfo.name;
  String get version => packageInfo.version;
}
