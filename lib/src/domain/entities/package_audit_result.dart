import 'package:cura/src/domain/entities/github_metrics.dart';
import 'package:cura/src/domain/entities/package_info.dart';
import 'package:cura/src/domain/entities/score.dart';
import 'package:cura/src/domain/entities/vulnerability.dart';

/// The fully scored output of a single package audit.
///
/// Produced by the `CheckPackagesUsecase` and `ViewPackageDetails` use cases
/// after aggregating pub.dev, GitHub, and OSV data and running the scoring
/// algorithm. This is the primary entity consumed by presenters and the JSON
/// output mode.
///
/// Identity is defined by [name] + [version] so that the same package at
/// different versions is treated as a distinct result.
class PackageAuditResult {
  /// Pub.dev package name (e.g. `dio`).
  final String name;

  /// Package version that was audited (e.g. `5.4.3+1`).
  final String version;

  /// Raw pub.dev metadata used as the primary data source.
  final PackageInfo packageInfo;

  /// GitHub repository metrics, or `null` when no repository URL is available
  /// or the GitHub request failed.
  final GitHubMetrics? githubMetrics;

  /// Composite health score computed by the scoring algorithm.
  final Score score;

  /// Whether this result was served from the local SQLite cache.
  final bool fromCache;

  /// Known CVEs / OSV advisories affecting this package version.
  ///
  /// An empty list means either no vulnerabilities were found or the OSV
  /// request failed gracefully.
  final List<Vulnerability> vulnerabilities;

  /// Structured issues detected during the audit (e.g. low score, stale).
  final List<AuditIssue> issues;

  /// Human-readable improvement suggestions derived from the score and issues.
  final List<String> suggestions;

  /// Creates a [PackageAuditResult] with all required fields.
  const PackageAuditResult({
    required this.name,
    required this.version,
    required this.packageInfo,
    this.githubMetrics,
    required this.score,
    required this.fromCache,
    required this.vulnerabilities,
    required this.issues,
    required this.suggestions,
  });

  // ---------------------------------------------------------------------------
  // Derived properties
  // ---------------------------------------------------------------------------

  /// Whether any vulnerabilities were found.
  bool get hasVulnerabilities => vulnerabilities.isNotEmpty;

  /// Whether any vulnerability is classified as [VulnerabilitySeverity.critical].
  bool get hasCriticalVulnerabilities =>
      vulnerabilities.any((v) => v.severity == VulnerabilitySeverity.critical);

  /// Whether the audit produced any structured [AuditIssue]s.
  bool get hasIssues => issues.isNotEmpty;

  /// Whether the package passes the general health bar (score ≥ 70) and has
  /// no critical vulnerabilities.
  bool get isHealthy => score.total >= 70 && !hasCriticalVulnerabilities;

  /// Whether the package has been marked as discontinued on pub.dev.
  bool get isDiscontinued => packageInfo.isDiscontinued;

  /// High-level audit status used to drive UI colouring and CI exit codes.
  AuditStatus get status {
    if (isDiscontinued) return AuditStatus.discontinued;
    if (hasCriticalVulnerabilities) return AuditStatus.critical;
    if (score.total >= 90) return AuditStatus.excellent;
    if (score.total >= 70) return AuditStatus.good;
    if (score.total >= 50) return AuditStatus.warning;
    return AuditStatus.critical;
  }

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Serialises the audit result to a JSON-compatible map.
  ///
  /// Used by the `--format json` output mode. Enum values are serialised as
  /// their lowercase [Enum.name] so consumers do not need to parse Dart
  /// `toString()` output.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'version': version,
      'score': {
        'total': score.total,
        'grade': score.grade,
        'vitality': score.vitality,
        'technical_health': score.technicalHealth,
        'trust': score.trust,
        'maintenance': score.maintenance,
      },
      'status': status.name,
      'issues': issues.map((i) => i.toJson()).toList(),
      'vulnerabilities': vulnerabilities.map((v) => v.toJson()).toList(),
      'suggestions': suggestions,
      'from_cache': fromCache,
    };
  }

  // ---------------------------------------------------------------------------
  // Object identity
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackageAuditResult &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          version == other.version;

  @override
  int get hashCode => name.hashCode ^ version.hashCode;

  @override
  String toString() => 'PackageAuditResult($name@$version, score: ${score.total})';
}

// =============================================================================
// Supporting types
// =============================================================================

/// High-level audit outcome used for UI rendering and CI exit-code logic.
///
/// | Value        | Condition                                  |
/// |--------------|---------------------------------------------|
/// | excellent    | score 90–100                               |
/// | good         | score 70–89                                |
/// | warning      | score 50–69                                |
/// | critical     | score < 50 or critical vulnerabilities      |
/// | discontinued | package marked discontinued on pub.dev      |
enum AuditStatus {
  /// Score 90–100. Package is in excellent health.
  excellent,

  /// Score 70–89. Package is in good health.
  good,

  /// Score 50–69. Package has issues worth addressing.
  warning,

  /// Score < 50 or critical vulnerability detected.
  critical,

  /// Package has been discontinued on pub.dev.
  discontinued,
}

/// A single structured issue detected during a package audit.
///
/// Issues are distinct from [Score.redFlags] in that they carry a typed
/// [AuditIssueType] and structured [severity], making them suitable for
/// programmatic processing (e.g. CI gates, JSON reports).
class AuditIssue {
  /// The category of issue detected.
  final AuditIssueType type;

  /// Human-readable description of the issue.
  final String message;

  /// How severe the issue is relative to package health.
  final AuditIssueSeverity severity;

  /// Creates an [AuditIssue] with the provided type, message, and severity.
  const AuditIssue({
    required this.type,
    required this.message,
    required this.severity,
  });

  /// Creates an issue for a package that has been discontinued.
  factory AuditIssue.discontinued(String packageName) {
    return AuditIssue(
      type: AuditIssueType.discontinued,
      message: 'Package $packageName is discontinued',
      severity: AuditIssueSeverity.critical,
    );
  }

  /// Creates an issue for a package with one or more critical CVEs.
  ///
  /// [count] is the total number of critical vulnerabilities and [cveIds]
  /// lists their identifiers for display.
  factory AuditIssue.criticalVulnerabilities({
    required int count,
    required List<String> cveIds,
  }) {
    return AuditIssue(
      type: AuditIssueType.vulnerability,
      message: '$count critical vulnerabilities found: ${cveIds.join(", ")}',
      severity: AuditIssueSeverity.critical,
    );
  }

  /// Creates an issue for a package whose score is below the configured
  /// minimum threshold.
  factory AuditIssue.lowScore({
    required int score,
    required int threshold,
  }) {
    return AuditIssue(
      type: AuditIssueType.lowScore,
      message: 'Score $score is below threshold $threshold',
      severity: AuditIssueSeverity.warning,
    );
  }

  /// Creates an issue for a package that has not been updated recently.
  factory AuditIssue.stale({required int daysSinceUpdate}) {
    return AuditIssue(
      type: AuditIssueType.stale,
      message: 'No updates for $daysSinceUpdate days',
      severity: AuditIssueSeverity.warning,
    );
  }

  /// Serialises this issue to a JSON-compatible map.
  ///
  /// Enum values are serialised as their lowercase [Enum.name] so JSON
  /// consumers do not need to parse Dart `toString()` output.
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'message': message,
      'severity': severity.name,
    };
  }
}

/// Category of an [AuditIssue].
enum AuditIssueType {
  /// The package has been discontinued on pub.dev.
  discontinued,

  /// A security vulnerability was detected.
  vulnerability,

  /// The package score is below the configured minimum.
  lowScore,

  /// The package has not received updates within the expected window.
  stale,
}

/// Severity of an [AuditIssue], independent of [VulnerabilitySeverity].
enum AuditIssueSeverity {
  /// Informational; no action strictly required.
  info,

  /// Attention recommended but not blocking.
  warning,

  /// Blocking issue; triggers CI failure when configured.
  critical,
}
