import 'package:cura/src/domain/entities/vulnerability.dart';

/// Semantic health tier derived from a package's [Score.total].
///
/// | Status     | Condition        |
/// |------------|-----------------|
/// | healthy    | total ≥ 80       |
/// | warning    | 50 ≤ total < 80  |
/// | critical   | total < 50       |
enum HealthStatus {
  /// Score ≥ 80. Package is in good shape.
  healthy,

  /// Score in the range 50–79. Attention recommended.
  warning,

  /// Score < 50. Immediate action required.
  critical,
}

/// Composite health score (0–100) for a pub.dev package.
///
/// The total is the sum of four weighted dimension scores plus any [penalty]:
///
/// | Dimension         | Max pts | Source                                    |
/// |-------------------|---------|-------------------------------------------|
/// | [vitality]        | 40      | Release frequency, last update, commits   |
/// | [technicalHealth] | 30      | Pana score, null safety, platform support |
/// | [trust]           | 20      | Community likes, download popularity      |
/// | [maintenance]     | 10      | Verified publisher, Flutter Favourite     |
///
/// Special factories [Score.discontinued] and [Score.vulnerable] produce an
/// automatic **0** regardless of dimension scores, as required by the scoring
/// algorithm defined in the project specification.
class Score {
  /// Composite score in the range 0–100.
  final int total;

  /// Vitality dimension score (0–40).
  final int vitality;

  /// Technical health dimension score (0–30).
  final int technicalHealth;

  /// Trust dimension score (0–20).
  final int trust;

  /// Maintenance dimension score (0–10).
  final int maintenance;

  /// Negative point adjustment applied after dimension scores are summed.
  ///
  /// Penalties are deducted for signals such as missing source repository.
  /// Defaults to `0` when no penalty applies.
  final int penalty;

  /// Letter grade derived from [total] (e.g. `A+`, `B`, `F`).
  final String grade;

  /// Per-dimension narrative strings rendered in verbose output.
  final ScoreBreakdown breakdown;

  /// Qualitative risk signals detected during scoring (e.g. "No repository").
  final List<String> redFlags;

  /// Actionable guidance derived from the score and red flags.
  final List<String> recommendations;

  /// Creates a [Score] with all dimension values.
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

  /// Returns a zero score for a discontinued package.
  ///
  /// Per the scoring specification, a discontinued package always receives
  /// a total of 0 and grade F, regardless of its other metadata.
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

  /// Returns a zero score for a package with unpatched critical CVEs.
  ///
  /// Per the scoring specification, any critical vulnerability yields a total
  /// of 0 and grade F. [vulnerabilities] is used only for the count displayed
  /// in the breakdown and red-flags list.
  factory Score.vulnerable(
    String packageName, {
    required List<Vulnerability> vulnerabilities,
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

  bool get isHealthy => status == HealthStatus.healthy;
  bool get isCritical => status == HealthStatus.critical;

  /// Whether the package achieved an excellent score (total ≥ 90).
  bool get isExcellent => total >= 90;

  @override
  String toString() => 'Score($total/100, grade: $grade)';
}

/// Per-dimension narrative strings attached to a [Score].
///
/// Each field contains a human-readable explanation of how that dimension's
/// points were calculated. Rendered in verbose CLI output and detailed views.
class ScoreBreakdown {
  /// Explanation of the [Score.vitality] points awarded.
  final String vitalityDetails;

  /// Explanation of the [Score.technicalHealth] points awarded.
  final String technicalHealthDetails;

  /// Explanation of the [Score.trust] points awarded.
  final String trustDetails;

  /// Explanation of the [Score.maintenance] points awarded.
  final String maintenanceDetails;

  /// Creates a [ScoreBreakdown] with the provided dimension narratives.
  const ScoreBreakdown({
    required this.vitalityDetails,
    required this.technicalHealthDetails,
    required this.trustDetails,
    required this.maintenanceDetails,
  });
}
