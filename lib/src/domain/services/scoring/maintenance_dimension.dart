import 'package:cura/src/domain/services/scoring/scoring_dimension.dart';
import 'package:cura/src/domain/services/scoring/scoring_input.dart';
import 'package:cura/src/domain/value_objects/score_weights.dart';

/// Maintenance dimension — official support and quality endorsement signals.
///
/// Default weight: [ScoreWeights.defaultMaintenance] (10 pts).
///
/// | Signal               | Points |
/// |----------------------|--------|
/// | Verified publisher   | 5      |
/// | Flutter Favorite     | 5      |
final class MaintenanceDimension implements ScoringDimension {
  const MaintenanceDimension({required this.weight});

  final int weight;

  static const int _verifiedPublisherPoints = 5;
  static const int _flutterFavoritePoints = 5;

  @override
  String get name => 'maintenance';

  @override
  int get baseMax => ScoreWeights.defaultMaintenance;

  @override
  int calculate(ScoringInput input) {
    final pkg = input.package;
    var score = 0;

    if (pkg.hasVerifiedPublisher) score += _verifiedPublisherPoints;
    if (pkg.isFlutterFavorite) score += _flutterFavoritePoints;

    return (score * weight / baseMax).round();
  }

  @override
  String describe(ScoringInput input) {
    final parts = <String>[];
    final pkg = input.package;
    if (pkg.publisherId != null) parts.add('Publisher: ${pkg.publisherId}');
    if (pkg.isFlutterFavorite) parts.add('Flutter Favorite');
    return parts.isEmpty ? 'No official support' : parts.join(', ');
  }
}
