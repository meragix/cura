class Score {
  final int total;
  final int vitality;
  final int technicalHealth;
  final int trust;
  final int maintenance;
  final String grade;
  final ScoreBreakdown breakdown;

  const Score({
    required this.total,
    required this.vitality,
    required this.technicalHealth,
    required this.trust,
    required this.maintenance,
    required this.grade,
    required this.breakdown,
  });

  /// Factory : Package discontinued (score = 0)
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
    );
  }

  /// Factory : Package vulnerable (score = 0)
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
        technicalHealthDetails: '${vulnerabilities.length} CVEs',
        trustDetails: '',
        maintenanceDetails: '',
      ),
    );
  }

  /// Helpers
  bool get isHealthy => total >= 70;
  bool get isExcellent => total >= 90;
  bool get isCritical => total < 50;

  @override
  String toString() => 'Score($total/100, grade: $grade)';
}

/// Détails du score (pour mode verbose)
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
