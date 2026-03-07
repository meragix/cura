import 'package:cura/src/domain/entities/github_metrics.dart';
import 'package:cura/src/domain/entities/package_info.dart';
import 'package:cura/src/domain/entities/vulnerability.dart';

/// Immutable snapshot of all data required by a scoring pass.
///
/// Using a Dart record ensures every [ScoringDimension] receives the same
/// consistent view of the data, enabling isolated, side-effect-free
/// calculations — and making unit tests trivial to write:
///
/// ```dart
/// final input = (
///   package: mockPackage,
///   github: null,
///   vulnerabilities: [],
/// );
/// expect(VitalityDimension(weight: 40).calculate(input), 28);
/// ```
typedef ScoringInput = ({
  PackageInfo package,
  GitHubMetrics? github,
  List<Vulnerability> vulnerabilities,
});

/// Returns `true` when [pkg] is mature enough to relax staleness penalties.
///
/// A package qualifies as stable when it is published by a trusted publisher
/// **or** when it has a stable 1.x+ release with near-perfect Pana score and
/// broad adoption (popularity > 70 %).
bool isConsideredStable(PackageInfo pkg) {
  if (pkg.isTrustedPublisher) return true;
  return pkg.isStable && pkg.panaScore >= 130 && pkg.popularity > 70;
}
