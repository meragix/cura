/// Semantic health tier derived from a package's composite score.
enum HealthStatus {
  healthy, // total >= 80
  warning, // total >= 50
  critical, // total < 50
}

/// Composite health score (0–100) for a pub.dev package.
class Score {
  final int total;
  final int vitality;
  final int technicalHealth;
  final int trust;
  final int maintenance;

  /// Negative adjustments applied after dimension scores (e.g. missing repo).
  final int penalty;

  final String grade;
  final ScoreBreakdown breakdown;

  /// Qualitative risk signals detected during scoring.
  final List<String> redFlags;

  /// Actionable guidance derived from the score and red flags.
  final List<String> recommendations;

  const Score({
    required this.total,
    required this.vitality,
    required this.technicalHealth,
    required this.trust,
    required this.maintenance,
    this.penalty = 0,
    required this.grade,
    required this.breakdown,
    this.redFlags = const [],
    this.recommendations = const [],
  });

  /// Factory: package discontinued (score = 0).
  factory Score.discontinued(String packageName) {
    return Score(
      total: 0,
      vitality: 0,
      technicalHealth: 0,
      trust: 0,
      maintenance: 0,
      grade: 'F',
      breakdown: ScoreBreakdown(
        vitalityDetails: 'Package discontinued',
        technicalHealthDetails: '',
        trustDetails: '',
        maintenanceDetails: '',
      ),
      redFlags: ['Package discontinued'],
      recommendations: ['Find an actively maintained alternative'],
    );
  }

  /// Factory: package has critical unpatched CVEs (score = 0).
  factory Score.vulnerable(
    String packageName, {
    required List<dynamic> vulnerabilities,
  }) {
    return Score(
      total: 0,
      vitality: 0,
      technicalHealth: 0,
      trust: 0,
      maintenance: 0,
      grade: 'F',
      breakdown: ScoreBreakdown(
        vitalityDetails: 'Critical vulnerabilities found',
        technicalHealthDetails: '${vulnerabilities.length} CVE(s)',
        trustDetails: '',
        maintenanceDetails: '',
      ),
      redFlags: ['${vulnerabilities.length} critical CVE(s) detected'],
      recommendations: ['Update to a patched version immediately'],
    );
  }

  /// Semantic health tier derived from [total].
  HealthStatus get status {
    if (total >= 80) return HealthStatus.healthy;
    if (total >= 50) return HealthStatus.warning;
    return HealthStatus.critical;
  }

  /// Helpers
  bool get isHealthy => total >= 70;
  bool get isExcellent => total >= 90;
  bool get isCritical => total < 50;

  @override
  String toString() => 'Score($total/100, grade: $grade)';
}

/// Dimension-level detail strings rendered in verbose mode.
class ScoreBreakdown {
  final String vitalityDetails;
  final String technicalHealthDetails;
  final String trustDetails;
  final String maintenanceDetails;

  const ScoreBreakdown({
    required this.vitalityDetails,
    required this.technicalHealthDetails,
    required this.trustDetails,
    required this.maintenanceDetails,
  });
}
