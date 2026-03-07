import 'package:cura/src/domain/entities/github_metrics.dart';
import 'package:cura/src/domain/entities/package_info.dart';
import 'package:cura/src/domain/entities/score.dart';
import 'package:cura/src/domain/entities/vulnerability.dart';
import 'package:cura/src/domain/ports/score_calculator.dart';
import 'package:cura/src/domain/services/scoring/maintenance_dimension.dart';
import 'package:cura/src/domain/services/scoring/penalty_evaluator.dart';
import 'package:cura/src/domain/services/scoring/recommendation_engine.dart';
import 'package:cura/src/domain/services/scoring/red_flag_detector.dart';
import 'package:cura/src/domain/services/scoring/technical_health_dimension.dart';
import 'package:cura/src/domain/services/scoring/trust_dimension.dart';
import 'package:cura/src/domain/services/scoring/vitality_dimension.dart';
import 'package:cura/src/domain/value_objects/grade.dart';
import 'package:cura/src/domain/value_objects/score_weights.dart';

/// Use case: compute a composite health [Score] (0–100) for a pub.dev package.
///
/// Implements [ScoreCalculator] and orchestrates four independent
/// [ScoringDimension] strategies, a [PenaltyEvaluator], a [RedFlagDetector],
/// and a [RecommendationEngine].
///
/// ## Scoring dimensions
///
/// | Dimension        | Default weight | Signal sources                                   |
/// |------------------|----------------|--------------------------------------------------|
/// | Vitality         | 40 pts         | Release recency, GitHub commit activity          |
/// | Technical Health | 30 pts         | Pana score, null safety, Dart 3, platform count  |
/// | Trust            | 20 pts         | Community likes, download popularity, GH stars   |
/// | Maintenance      | 10 pts         | Verified publisher, Flutter Favorite badge       |
///
/// ## Zero-score overrides (applied before all other logic)
///
/// The score is forced to **0** (grade F) when:
/// - The package is marked *discontinued* on pub.dev.
/// - At least one *critical* CVE has no known patch.
///
/// ## Trusted-publisher floor
///
/// Packages from trusted publishers (e.g. `dart.dev`, `flutter.dev`) receive a
/// score floor of **70** — they cannot score below it — but are NOT exempt from
/// penalties, red-flag detection, or the zero-score overrides above.
///
/// This means a stale or unlicensed Google package will still be flagged and
/// may have recommendations generated, while its numeric score remains capped
/// at a minimum of 70 to reflect the baseline trust in the publisher.
///
/// ## Configurability
///
/// Dimension weights are injected via [ScoreWeights] and must sum to 100.
/// Invalid configuration throws [ArgumentError] at construction time, not at
/// call time.
///
/// ## Extensibility
///
/// New scoring dimensions can be added by:
/// 1. Implementing [ScoringDimension].
/// 2. Injecting the new dimension via [CalculateScore.withDimensions].
/// No modification to this orchestrator is required (OCP).
class CalculateScore implements ScoreCalculator {
  final VitalityDimension _vitality;
  final TechnicalHealthDimension _technicalHealth;
  final TrustDimension _trust;
  final MaintenanceDimension _maintenance;
  final PenaltyEvaluator _penalties;
  final RedFlagDetector _flagDetector;
  final RecommendationEngine _recommendations;

  /// Trusted-publisher score floor: packages from verified first-party
  /// publishers always score at least this value.
  static const int _trustedPublisherFloor = 70;

  /// Creates a [CalculateScore] with standard dimension weights.
  ///
  /// [weights] must sum to 100; an invalid configuration throws [ArgumentError]
  /// at construction time — not at scoring time.
  CalculateScore({ScoreWeights weights = const ScoreWeights()}) : this._(
          vitality: VitalityDimension(weight: weights.vitality),
          technicalHealth:
              TechnicalHealthDimension(weight: weights.technicalHealth),
          trust: TrustDimension(weight: weights.trust),
          maintenance: MaintenanceDimension(weight: weights.maintenance),
          penalties: const PenaltyEvaluator(),
          flagDetector: const RedFlagDetector(),
          recommendations: const RecommendationEngine(),
          weights: weights,
        );

  /// Creates a [CalculateScore] with fully custom dimension instances.
  ///
  /// Useful for testing or advanced configuration scenarios where individual
  /// dimensions need to be replaced or extended.
  CalculateScore.withDimensions({
    required VitalityDimension vitality,
    required TechnicalHealthDimension technicalHealth,
    required TrustDimension trust,
    required MaintenanceDimension maintenance,
    PenaltyEvaluator penalties = const PenaltyEvaluator(),
    RedFlagDetector flagDetector = const RedFlagDetector(),
    RecommendationEngine recommendations = const RecommendationEngine(),
    ScoreWeights weights = const ScoreWeights(),
  }) : this._(
          vitality: vitality,
          technicalHealth: technicalHealth,
          trust: trust,
          maintenance: maintenance,
          penalties: penalties,
          flagDetector: flagDetector,
          recommendations: recommendations,
          weights: weights,
        );

  CalculateScore._({
    required VitalityDimension vitality,
    required TechnicalHealthDimension technicalHealth,
    required TrustDimension trust,
    required MaintenanceDimension maintenance,
    required PenaltyEvaluator penalties,
    required RedFlagDetector flagDetector,
    required RecommendationEngine recommendations,
    required ScoreWeights weights,
  })  : _vitality = vitality,
        _technicalHealth = technicalHealth,
        _trust = trust,
        _maintenance = maintenance,
        _penalties = penalties,
        _flagDetector = flagDetector,
        _recommendations = recommendations {
    if (!weights.isValid) {
      throw ArgumentError(
        'Score weights must sum to 100 (got ${weights.total})',
      );
    }
  }

  /// Computes the composite [Score] for [packageInfo].
  ///
  /// Optionally enriched with [githubMetrics] (stars, commit activity) and
  /// [vulnerabilities] (CVE data from OSV.dev).
  @override
  Score execute(
    PackageInfo packageInfo, {
    GitHubMetrics? githubMetrics,
    List<Vulnerability> vulnerabilities = const [],
  }) {
    // Zero-score overrides — applied before everything, including trusted check.
    if (packageInfo.isDiscontinued) {
      return Score.discontinued(packageInfo.name);
    }

    final hasCriticalVuln = vulnerabilities.any(
      (v) => v.severity == VulnerabilitySeverity.critical,
    );
    if (hasCriticalVuln) {
      return Score.vulnerable(
        packageInfo.name,
        vulnerabilities: vulnerabilities,
      );
    }

    final input = (
      package: packageInfo,
      github: githubMetrics,
      vulnerabilities: vulnerabilities,
    );

    // Dimension scores.
    final vitalityScore = _vitality.calculate(input);
    final technicalHealthScore = _technicalHealth.calculate(input);
    final trustScore = _trust.calculate(input);
    final maintenanceScore = _maintenance.calculate(input);

    // Penalties applied after dimension totals.
    final penalty = _penalties.calculate(input);
    final rawTotal =
        vitalityScore + technicalHealthScore + trustScore + maintenanceScore + penalty;

    // Trusted publisher floor: guaranteed minimum, not an automatic perfect score.
    final total = packageInfo.isTrustedPublisher
        ? rawTotal.clamp(_trustedPublisherFloor, 100)
        : rawTotal.clamp(0, 100);

    // Qualitative signals — always evaluated, even for trusted publishers.
    final redFlags = _flagDetector.detect(input);
    final recommendations = _recommendations.generate(input, total, redFlags);

    return Score(
      total: total,
      vitality: vitalityScore,
      technicalHealth: technicalHealthScore,
      trust: trustScore,
      maintenance: maintenanceScore,
      penalty: penalty,
      grade: Grade.fromScore(total),
      breakdown: ScoreBreakdown(
        vitalityDetails: _vitality.describe(input),
        technicalHealthDetails: _technicalHealth.describe(input),
        trustDetails: _trust.describe(input),
        maintenanceDetails: _maintenance.describe(input),
      ),
      redFlags: redFlags,
      recommendations: recommendations,
    );
  }

}
