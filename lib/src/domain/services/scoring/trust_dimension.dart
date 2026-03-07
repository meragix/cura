import 'package:cura/src/domain/services/scoring/scoring_dimension.dart';
import 'package:cura/src/domain/services/scoring/scoring_input.dart';
import 'package:cura/src/domain/value_objects/score_weights.dart';

/// Trust dimension — community adoption and popularity signals.
///
/// Default weight: [ScoreWeights.defaultTrust] (20 pts).
///
/// | Signal           | Points |
/// |------------------|--------|
/// | Pub.dev likes    | 0–10   |
/// | Popularity %     | 0–10   |
/// | GitHub stars     | +3     |
final class TrustDimension implements ScoringDimension {
  const TrustDimension({required this.weight});

  final int weight;

  static const int _likesForMax = 1000;
  static const int _likesWeight = 10;
  static const int _popularityWeight = 10;
  static const int _highStarThreshold = 1000;
  static const int _starsBonus = 3;

  @override
  String get name => 'trust';

  @override
  int get baseMax => ScoreWeights.defaultTrust;

  @override
  int calculate(ScoringInput input) {
    final pkg = input.package;
    var score = 0;

    score += (pkg.likes / _likesForMax * _likesWeight)
        .round()
        .clamp(0, _likesWeight);
    score += (pkg.popularity / 100 * _popularityWeight)
        .round()
        .clamp(0, _popularityWeight);

    if (input.github != null && input.github!.stars > _highStarThreshold) {
      score += _starsBonus;
    }

    return (score * weight / baseMax).round();
  }

  @override
  String describe(ScoringInput input) {
    final pkg = input.package;
    return 'Likes: ${pkg.likes}, Popularity: ${pkg.popularity}%';
  }
}
