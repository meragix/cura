import 'package:cura/src/domain/services/scoring/scoring_input.dart';
import 'package:cura/src/domain/value_objects/red_flag.dart';

/// Detects qualitative risk signals for a package and returns a typed list
/// of [RedFlag]s.
///
/// Red flags are independent of the numeric score and complement it with
/// structured, actionable risk information. They are evaluated even for
/// trusted-publisher packages — a stale or unlicensed Google package must
/// still be surfaced to the user.
final class RedFlagDetector {
  const RedFlagDetector();

  static const int _staleThresholdDays = 540;
  static const int _minPlatformsThreshold = 3;
  static const int _suspiciousRiskThreshold = 3;

  /// Detects all applicable [RedFlag]s for [input].
  ///
  /// [MultipleRisksFlag] is prepended when three or more non-suspicious flags
  /// are present on an unverified package, giving the UI a single top-level
  /// signal to act on.
  List<RedFlag> detect(ScoringInput input) {
    final pkg = input.package;
    final flags = <RedFlag>[];

    // Staleness beyond 18 months on a non-stable package.
    if (pkg.daysSinceLastUpdate > _staleThresholdDays &&
        !isConsideredStable(pkg)) {
      flags.add(
        StalePackageFlag(months: (pkg.daysSinceLastUpdate / 30).round()),
      );
    }

    // Limited cross-platform support.
    if (pkg.supportedPlatforms.length < _minPlatformsThreshold) {
      flags.add(
          LimitedPlatformSupportFlag(count: pkg.supportedPlatforms.length));
    }

    // Unverified publisher.
    if (!pkg.hasVerifiedPublisher) {
      flags.add(const UnverifiedPublisherFlag());
    }

    // No source repository: cannot audit the code.
    if (!pkg.hasRepository) {
      flags.add(const MissingRepositoryFlag());
    }

    // Suboptimal static analysis score.
    if (pkg.panaScore < 100) {
      flags.add(SuboptimalPanaScoreFlag(score: pkg.panaScore, maxScore: 130));
    }

    // Experimental version (0.0.x).
    if (pkg.version.startsWith('0.0.')) {
      flags.add(ExperimentalVersionFlag(version: pkg.version));
    }

    // Sound null safety disabled.
    if (!pkg.isNullSafe) {
      flags.add(const NoNullSafetyFlag());
    }

    // New package — insufficient track record.
    if (pkg.isNew) {
      flags.add(const NewPackageFlag());
    }

    // Not Dart 3 compatible.
    if (!pkg.isDart3Compatible) {
      flags.add(const NotDart3CompatibleFlag());
    }

    // WASM readiness for web-targeting packages.
    if (pkg.isWeb && !pkg.isWasmReady) {
      flags.add(const NotWasmReadyFlag());
    }

    // Missing license — legal risk (priority flag).
    if (pkg.license == null) {
      flags.add(const MissingLicenseFlag());
    }

    // Suspicious combination: multiple risk factors on an unverified package.
    if (flags.length >= _suspiciousRiskThreshold && !pkg.hasVerifiedPublisher) {
      flags.insert(0, MultipleRisksFlag(riskCount: flags.length));
    }

    return flags;
  }
}
