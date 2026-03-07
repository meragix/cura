import 'package:cura/src/domain/services/scoring/scoring_input.dart';

/// Computes penalty points subtracted from the raw dimension total.
///
/// Penalties are applied after all dimension scores are summed. The resulting
/// total is then clamped to `[0, 100]` by [CalculateScore].
///
/// | Condition                                        | Deduction |
/// |--------------------------------------------------|-----------|
/// | No source-code repository linked                 | −30 pts   |
/// | Experimental `0.0.x` version stalled > 1 year   | −20 pts   |
final class PenaltyEvaluator {
  const PenaltyEvaluator();

  static const int _missingRepoPenalty = -30;
  static const int _experimentalStalePenalty = -20;
  static const int _experimentalStaleThresholdDays = 365;

  /// Returns the total penalty (≤ 0) for [input].
  int calculate(ScoringInput input) {
    final pkg = input.package;
    var penalty = 0;

    // No source repository: code cannot be independently audited.
    if (!pkg.hasRepository) penalty += _missingRepoPenalty;

    // Experimental versioning (0.0.x) stalled for over a year.
    if (pkg.version.startsWith('0.0.') &&
        pkg.daysSinceLastUpdate > _experimentalStaleThresholdDays) {
      penalty += _experimentalStalePenalty;
    }

    return penalty;
  }
}
