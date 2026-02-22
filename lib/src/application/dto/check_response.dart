import 'package:cura/src/domain/entities/package_audit_result.dart';

class CheckResponse {
  final List<PackageAuditResult> results;
  final CheckSummary summary;
  final Duration executionTime;

  const CheckResponse({
    required this.results,
    required this.summary,
    required this.executionTime,
  });

  /// Create from audit results
  factory CheckResponse.fromResults({
    required List<PackageAuditResult> results,
    required int totalPackages,
    required int failureCount,
    required Duration executionTime,
  }) {
    final healthy = results.where((r) => r.score.total >= 70).length;
    final warning = results
        .where(
          (r) => r.score.total >= 50 && r.score.total < 70,
        )
        .length;
    final critical = results.where((r) => r.score.total < 50).length;

    final avgScore = results.isEmpty
        ? 0
        : results.map((r) => r.score.total).reduce((a, b) => a + b) ~/
            results.length;

    return CheckResponse(
      results: results,
      summary: CheckSummary(
        totalPackages: totalPackages,
        healthyCount: healthy,
        warningCount: warning,
        criticalCount: critical,
        failureCount: failureCount,
        averageScore: avgScore,
      ),
      executionTime: executionTime,
    );
  }

  /// Convert to JSON (for --json output)
  Map<String, dynamic> toJson() {
    return {
      //'results': results.map((r) => r.toJson()).toList(),
      'summary': summary.toJson(),
      'execution_time_ms': executionTime.inMilliseconds,
    };
  }
}

/// Summary statistics
class CheckSummary {
  final int totalPackages;
  final int healthyCount;
  final int warningCount;
  final int criticalCount;
  final int failureCount;
  final int averageScore;

  const CheckSummary({
    required this.totalPackages,
    required this.healthyCount,
    required this.warningCount,
    required this.criticalCount,
    required this.failureCount,
    required this.averageScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'total_packages': totalPackages,
      'healthy': healthyCount,
      'warning': warningCount,
      'critical': criticalCount,
      'failures': failureCount,
      'average_score': averageScore,
    };
  }
}
