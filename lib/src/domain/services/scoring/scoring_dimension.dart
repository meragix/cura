import 'package:cura/src/domain/services/scoring/scoring_input.dart';

/// Contract for an independent scoring dimension (Strategy pattern).
///
/// Each implementation encapsulates the scoring logic and thresholds for one
/// domain concern. Dimensions can be:
/// - Unit-tested in isolation without constructing a full [CalculateScore].
/// - Swapped or composed without modifying the orchestrator.
/// - Extended (new dimensions) without touching existing code (OCP).
///
/// ### Normalisation contract
///
/// [calculate] must return a value in `[0, weight]`. The implementation is
/// responsible for normalising its raw score against [baseMax]:
///
/// ```dart
/// return (rawScore * weight / baseMax).round();
/// ```
///
/// [baseMax] and the corresponding default [ScoreWeights] entry **must agree**.
/// Named constants (e.g. [ScoreWeights.defaultVitality]) are used in each
/// dimension to enforce this at the source level.
abstract interface class ScoringDimension {
  /// Unique key identifying this dimension (e.g. `'vitality'`).
  String get name;

  /// Maximum achievable raw score before weight normalisation.
  ///
  /// Must match the corresponding [ScoreWeights] default constant.
  int get baseMax;

  /// Computes the weighted dimension score for [input].
  ///
  /// Result is in `[0, weight]`.
  int calculate(ScoringInput input);

  /// Returns a human-readable explanation of the score awarded.
  ///
  /// Consumed by [ScoreBreakdown] in verbose CLI output.
  String describe(ScoringInput input);
}
