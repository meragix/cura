import 'package:cura/src/domain/services/scoring/scoring_input.dart';
import 'package:cura/src/domain/value_objects/recommendation.dart';
import 'package:cura/src/domain/value_objects/red_flag.dart';

/// Generates typed [Recommendation]s from scored signals and [RedFlag]s.
///
/// Recommendations are derived from typed flag matching — not string parsing —
/// ensuring refactoring flag messages never silently breaks the logic here.
final class RecommendationEngine {
  const RecommendationEngine();

  static const int _healthyScoreThreshold = 80;
  static const int _earlyStageScoreThreshold = 50;

  /// Returns a prioritised list of [Recommendation]s for [input].
  ///
  /// When the score is healthy (≥ 80), a single positive verdict is returned.
  /// A [MultipleRisksFlag] triggers an early-exit AVOID recommendation.
  /// Otherwise recommendations are accumulated in order of severity.
  List<Recommendation> generate(
    ScoringInput input,
    int total,
    List<RedFlag> flags,
  ) {
    if (total >= _healthyScoreThreshold) {
      return const [
        Recommendation(
          level: RecommendationLevel.advisory,
          message: 'Verified health — suitable for production use',
        ),
      ];
    }

    // Suspicious package — highest priority, return immediately.
    if (flags.any((f) => f is MultipleRisksFlag)) {
      return const [
        Recommendation(
          level: RecommendationLevel.critical,
          message:
              'AVOID: Multiple risk factors detected on an unverified package',
        ),
        Recommendation(
          level: RecommendationLevel.action,
          message:
              'Search for a maintained alternative from a verified publisher',
        ),
      ];
    }

    final recs = <Recommendation>[];
    final pkg = input.package;

    // Missing license — legal risk is always surfaced first.
    if (flags.any((f) => f is MissingLicenseFlag)) {
      recs.add(const Recommendation(
        level: RecommendationLevel.critical,
        message:
            'No license detected — legal review required before commercial use',
      ));
    }

    // Stale package on a non-stable project.
    if (flags.any((f) => f is StalePackageFlag) && !isConsideredStable(pkg)) {
      recs.add(const Recommendation(
        level: RecommendationLevel.warning,
        message:
            'WARNING: Active maintenance not detected — seek modern alternatives',
      ));
    }

    // Unverified publisher.
    if (flags.any((f) => f is UnverifiedPublisherFlag)) {
      recs.add(const Recommendation(
        level: RecommendationLevel.action,
        message:
            'ACTION: Verify author reputation and repository activity on GitHub',
      ));
    }

    // Missing source repository.
    if (flags.any((f) => f is MissingRepositoryFlag)) {
      recs.add(const Recommendation(
        level: RecommendationLevel.critical,
        message:
            'CRITICAL: Cannot audit source code — avoid in professional projects',
      ));
    }

    // Experimental version.
    if (flags.any((f) => f is ExperimentalVersionFlag)) {
      recs.add(const Recommendation(
        level: RecommendationLevel.warning,
        message: 'WARNING: Unstable version — wait for a 1.0.0 release',
      ));
    }

    // New package.
    if (flags.any((f) => f is NewPackageFlag)) {
      recs.add(const Recommendation(
        level: RecommendationLevel.advisory,
        message: 'NEW: Recently published — monitor for API breaking changes',
      ));
      if (total < _earlyStageScoreThreshold) {
        recs.add(const Recommendation(
          level: RecommendationLevel.warning,
          message:
              'ADVISORY: Early-stage package — use only for non-critical features',
        ));
      }
    }

    // WASM readiness.
    if (flags.any((f) => f is NotWasmReadyFlag)) {
      recs.add(const Recommendation(
        level: RecommendationLevel.advisory,
        message:
            'Not WASM ready — will fall back to CanvasKit/HTML, increasing bundle size',
      ));
    }

    if (recs.isEmpty) {
      recs.add(const Recommendation(
        level: RecommendationLevel.advisory,
        message: 'CAUTION: Moderate score — manual evaluation recommended',
      ));
    }

    return recs;
  }
}
