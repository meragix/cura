import 'package:cura/src/domain/services/scoring/scoring_dimension.dart';
import 'package:cura/src/domain/services/scoring/scoring_input.dart';
import 'package:cura/src/domain/value_objects/score_weights.dart';

/// Technical health dimension — Pana score, null safety, Dart 3, platforms.
///
/// Default weight: [ScoreWeights.defaultTechnicalHealth] (30 pts).
///
/// | Signal              | Points |
/// |---------------------|--------|
/// | Pana score          | 0–15   |
/// | Sound null safety   | 10     |
/// | Dart 3 compatible   | 3      |
/// | Platform breadth    | 0–2    |
final class TechnicalHealthDimension implements ScoringDimension {
  const TechnicalHealthDimension({required this.weight});

  final int weight;

  static const int _panaMax = 130;
  static const int _panaWeight = 15;
  static const int _nullSafetyPoints = 10;
  static const int _dart3Points = 3;
  static const int _platformBonusMax = 2;

  @override
  String get name => 'technicalHealth';

  @override
  int get baseMax => ScoreWeights.defaultTechnicalHealth;

  @override
  int calculate(ScoringInput input) {
    final pkg = input.package;
    var score = 0;

    score +=
        (pkg.panaScore / _panaMax * _panaWeight).round().clamp(0, _panaWeight);
    if (pkg.isNullSafe) score += _nullSafetyPoints;
    if (pkg.isDart3Compatible) score += _dart3Points;
    score += (pkg.supportedPlatforms.length - 1).clamp(0, _platformBonusMax);

    return (score * weight / baseMax).round();
  }

  @override
  String describe(ScoringInput input) {
    final pkg = input.package;
    return 'Pana: ${pkg.panaScore}/$_panaMax, '
        'Null safe: ${pkg.isNullSafe}, '
        'Dart 3: ${pkg.isDart3Compatible}, '
        'Platforms: ${pkg.supportedPlatforms.length}';
  }
}
