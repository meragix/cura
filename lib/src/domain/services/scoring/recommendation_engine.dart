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
  /// When the score is healthy (≥ 80) and no flags remain, a positive verdict
  /// is returned. A [MultipleRisksFlag] triggers an early-exit AVOID pair.
  /// Otherwise recommendations are accumulated in severity order.
  ///
  /// Flag coverage:
  /// | Flag                      | Handled |
  /// |---------------------------|---------|
  /// | MultipleRisksFlag         | ✓ early exit  |
  /// | MissingLicenseFlag        | ✓ critical    |
  /// | MissingRepositoryFlag     | ✓ critical    |
  /// | NoNullSafetyFlag          | ✓ critical    |
  /// | StalePackageFlag          | ✓ warning     |
  /// | NotDart3CompatibleFlag    | ✓ warning     |
  /// | ExperimentalVersionFlag   | ✓ warning     |
  /// | UnverifiedPublisherFlag   | ✓ action      |
  /// | NewPackageFlag            | ✓ advisory    |
  /// | NotWasmReadyFlag          | ✓ advisory    |
  /// | LimitedPlatformSupportFlag| ✓ advisory    |
  /// | SuboptimalPanaScoreFlag   | – (numeric, reflected in score) |
  List<Recommendation> generate(
    ScoringInput input,
    int total,
    List<RedFlag> flags,
  ) {
    // Healthy package with no significant flags → positive verdict.
    if (total >= _healthyScoreThreshold) {
      return const [
        Recommendation(
          level: RecommendationLevel.advisory,
          message: 'Package health is verified. Suitable for production use.',
        ),
      ];
    }

    // Suspicious package — highest priority, return immediately.
    if (flags.any((f) => f is MultipleRisksFlag)) {
      return const [
        Recommendation(
          level: RecommendationLevel.critical,
          message: 'Do not use. Multiple critical risk factors detected on an unverified publisher.',
        ),
        Recommendation(
          level: RecommendationLevel.action,
          message: 'Find a maintained alternative published by a verified publisher.',
        ),
      ];
    }

    final recs = <Recommendation>[];
    final pkg = input.package;

    // ── Critical risks ──────────────────────────────────────────────────────

    // Missing license — legal risk, always surfaced first.
    if (flags.any((f) => f is MissingLicenseFlag)) {
      recs.add(const Recommendation(
        level: RecommendationLevel.critical,
        message: 'No license detected. Legal review is mandatory before any commercial use.',
      ));
    }

    // No source repository — cannot audit the code.
    if (flags.any((f) => f is MissingRepositoryFlag)) {
      recs.add(const Recommendation(
        level: RecommendationLevel.critical,
        message: 'No source repository. Code cannot be audited. Avoid in professional projects.',
      ));
    }

    // Sound null safety disabled — runtime risk.
    if (flags.any((f) => f is NoNullSafetyFlag)) {
      recs.add(const Recommendation(
        level: RecommendationLevel.critical,
        message: 'Sound null safety is disabled. Production use carries null-related crash risk.',
      ));
    }

    // ── Warnings ─────────────────────────────────────────────────────────────

    // Stale package on a non-stable project.
    if (flags.any((f) => f is StalePackageFlag) && !isConsideredStable(pkg)) {
      recs.add(const Recommendation(
        level: RecommendationLevel.warning,
        message: 'No maintenance activity detected. Migrate to an actively maintained alternative.',
      ));
    }

    // Not Dart 3 compatible — SDK upgrade blocker.
    if (flags.any((f) => f is NotDart3CompatibleFlag)) {
      recs.add(const Recommendation(
        level: RecommendationLevel.warning,
        message: 'Not Dart 3 compatible. Replace this dependency before any SDK upgrade.',
      ));
    }

    // Experimental version (0.0.x).
    if (flags.any((f) => f is ExperimentalVersionFlag)) {
      recs.add(const Recommendation(
        level: RecommendationLevel.warning,
        message: 'Version is pre-stable. Do not ship in production before 1.0.0 is released.',
      ));
    }

    // ── Actions ──────────────────────────────────────────────────────────────

    // Unverified publisher.
    if (flags.any((f) => f is UnverifiedPublisherFlag)) {
      recs.add(const Recommendation(
        level: RecommendationLevel.action,
        message: 'Publisher is unverified. Audit author reputation and GitHub activity before adopting.',
      ));
    }

    // ── Advisory ─────────────────────────────────────────────────────────────

    // New package — insufficient track record.
    if (flags.any((f) => f is NewPackageFlag)) {
      recs.add(const Recommendation(
        level: RecommendationLevel.advisory,
        message: 'Package is recently published. Monitor for API breaking changes.',
      ));
      if (total < _earlyStageScoreThreshold) {
        recs.add(const Recommendation(
          level: RecommendationLevel.warning,
          message: 'Low score on an early-stage package. Restrict to non-critical, low-risk features.',
        ));
      }
    }

    // Limited platform support.
    if (flags.any((f) => f is LimitedPlatformSupportFlag)) {
      recs.add(const Recommendation(
        level: RecommendationLevel.advisory,
        message: 'Platform support is limited. Verify compatibility with all target platforms.',
      ));
    }

    // WASM readiness for web-targeting packages.
    if (flags.any((f) => f is NotWasmReadyFlag)) {
      recs.add(const Recommendation(
        level: RecommendationLevel.advisory,
        message: 'Not WASM ready. Bundle will fall back to CanvasKit or HTML renderer, increasing size.',
      ));
    }

    if (recs.isEmpty) {
      recs.add(const Recommendation(
        level: RecommendationLevel.advisory,
        message: 'Score is below healthy threshold. Conduct manual evaluation before production adoption.',
      ));
    }

    return recs;
  }
}
