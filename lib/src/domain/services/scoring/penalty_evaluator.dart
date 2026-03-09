import 'package:cura/src/domain/entities/score.dart';
import 'package:cura/src/domain/services/scoring/scoring_input.dart';

/// Result of [PenaltyEvaluator.calculate]: the summed [total] and the
/// individual [items] that compose it.
typedef PenaltyResult = ({int total, List<PenaltyItem> items});

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

  /// Returns the penalty [total] and the individual [items] for [input].
  PenaltyResult calculate(ScoringInput input) {
    final pkg = input.package;
    final items = <PenaltyItem>[];

    // No source repository: code cannot be independently audited.
    if (!pkg.hasRepository) {
      items.add((label: 'No source repository', points: _missingRepoPenalty));
    }

    // Experimental versioning (0.0.x) stalled for over a year.
    if (pkg.version.startsWith('0.0.') &&
        pkg.daysSinceLastUpdate > _experimentalStaleThresholdDays) {
      items.add((
        label: 'v${pkg.version} (${pkg.daysSinceLastUpdate}d stalled)',
        points: _experimentalStalePenalty,
      ));
    }

    final total = items.fold(0, (sum, item) => sum + item.points);
    return (total: total, items: items);
  }
}
