import 'package:cura/src/domain/entities/github_metrics.dart';
import 'package:cura/src/domain/entities/package_info.dart';
import 'package:cura/src/domain/entities/score.dart';
import 'package:cura/src/domain/entities/vulnerability.dart';

/// Port (abstract contract) for the scoring use case.
///
/// Defines the interface that the domain and application layers depend on,
/// decoupling callers from the concrete [CalculateScore] implementation.
/// Enables easy mocking in unit tests:
///
/// ```dart
/// class MockScoreCalculator extends Mock implements ScoreCalculator {}
/// ```
abstract interface class ScoreCalculator {
  /// Computes the composite [Score] for [packageInfo].
  Score execute(
    PackageInfo packageInfo, {
    GitHubMetrics? githubMetrics,
    List<Vulnerability> vulnerabilities,
  });
}
