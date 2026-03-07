import 'package:cura/src/domain/services/scoring/scoring_dimension.dart';
import 'package:cura/src/domain/services/scoring/scoring_input.dart';
import 'package:cura/src/domain/value_objects/score_weights.dart';

/// Vitality dimension — measures release recency and GitHub commit activity.
///
/// Default weight: [ScoreWeights.defaultVitality] (40 pts).
final class VitalityDimension implements ScoringDimension {
  const VitalityDimension({required this.weight});

  /// Configured weight for this dimension (must match [ScoreWeights.vitality]).
  final int weight;

  // ---------------------------------------------------------------------------
  // Thresholds — named constants, no magic numbers
  // ---------------------------------------------------------------------------

  static const int _recentDays = 30;
  static const int _quarterDays = 90;
  static const int _semesterDays = 180;
  static const int _yearDays = 365;
  static const int _twoYearDays = 730;
  static const int _activeCommitThreshold = 10;
  static const int _stabilityBonus = 5;
  static const int _activityBonus = 5;

  @override
  String get name => 'vitality';

  @override
  int get baseMax => ScoreWeights.defaultVitality;

  @override
  int calculate(ScoringInput input) {
    final days = input.package.daysSinceLastUpdate;

    var base = switch (days) {
      <= _recentDays => 40, // Updated this month
      <= _quarterDays => 35, // Updated this quarter
      <= _semesterDays => 28, // Updated this semester
      <= _yearDays => 20, // Updated this year
      <= _twoYearDays => 10, // Updated in last 2 years
      _ => 0, // Abandoned (> 2 years)
    };

    // Stability bonus: mature packages update infrequently by design.
    if (isConsideredStable(input.package) && days > _semesterDays) {
      base += _stabilityBonus;
    }

    // GitHub activity bonus: recent commits signal active development.
    if (input.github != null &&
        input.github!.commitCountLast90Days > _activeCommitThreshold) {
      base += _activityBonus;
    }

    return (base * weight / baseMax).round();
  }

  @override
  String describe(ScoringInput input) =>
      'Last updated ${input.package.daysSinceLastUpdate} days ago';
}
