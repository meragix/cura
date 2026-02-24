import 'package:cura/src/domain/entities/github_metrics.dart';
import 'package:cura/src/domain/entities/package_info.dart';
import 'package:cura/src/domain/entities/score.dart';
import 'package:cura/src/domain/entities/vulnerability.dart';

class PackageAuditResult {
  final String name;
  final String version;
  final PackageInfo packageInfo;
  final GitHubMetrics? githubMetrics;
  final Score score;
  final bool fromCache;
  final List<Vulnerability> vulnerabilities;
  final List<AuditIssue> issues;
  final List<String> suggestions;

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

  /// Helpers pour classification
  bool get hasVulnerabilities => vulnerabilities.isNotEmpty;
  bool get hasCriticalVulnerabilities => vulnerabilities.any(
        (v) => v.severity == VulnerabilitySeverity.critical,
      );
  bool get hasIssues => issues.isNotEmpty;
  bool get isHealthy => score.total >= 70 && !hasCriticalVulnerabilities;
  bool get isDiscontinued => packageInfo.isDiscontinued;

  /// Status global (pour UI)
  AuditStatus get status {
    if (isDiscontinued) return AuditStatus.discontinued;
    if (hasCriticalVulnerabilities) return AuditStatus.critical;
    if (score.total >= 90) return AuditStatus.excellent;
    if (score.total >= 70) return AuditStatus.good;
    if (score.total >= 50) return AuditStatus.warning;
    return AuditStatus.critical;
  }

  /// Serialize to JSON
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
      'status': status.toString().split('.').last,
      'issues': issues.map((i) => i.toJson()).toList(),
      'vulnerabilities': vulnerabilities.map((v) => v.toJson()).toList(),
      'suggestions': suggestions,
      'from_cache': fromCache,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackageAuditResult && runtimeType == other.runtimeType && name == other.name && version == other.version;

  @override
  int get hashCode => name.hashCode ^ version.hashCode;

  @override
  String toString() => 'PackageAuditResult($name@$version, score: ${score.total})';
}

/// Status d'audit (enum simple)
enum AuditStatus {
  excellent, // 90-100
  good, // 70-89
  warning, // 50-69
  critical, // 0-49 ou vulnerabilities
  discontinued,
}

/// Issue identifiée lors de l'audit
class AuditIssue {
  final AuditIssueType type;
  final String message;
  final AuditIssueSeverity severity;

  const AuditIssue({
    required this.type,
    required this.message,
    required this.severity,
  });

  // Factory constructors pour lisibilité
  factory AuditIssue.discontinued(String packageName) {
    return AuditIssue(
      type: AuditIssueType.discontinued,
      message: 'Package $packageName is discontinued',
      severity: AuditIssueSeverity.critical,
    );
  }

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

  factory AuditIssue.stale({required int daysSinceUpdate}) {
    return AuditIssue(
      type: AuditIssueType.stale,
      message: 'No updates for $daysSinceUpdate days',
      severity: AuditIssueSeverity.warning,
    );
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {'type': type, 'message': message, 'severity': severity};
  }
}

enum AuditIssueType {
  discontinued,
  vulnerability,
  lowScore,
  stale,
}

enum AuditIssueSeverity {
  info,
  warning,
  critical,
}
