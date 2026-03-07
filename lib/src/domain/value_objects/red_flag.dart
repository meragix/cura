/// Risk severity attached to a [RedFlag].
enum RedFlagSeverity {
  /// Informational signal — worth monitoring.
  info,

  /// Elevated risk — review recommended before using in production.
  warning,

  /// Immediate risk — action or avoidance required.
  critical,
}

/// A typed, structured risk signal detected during package scoring.
///
/// Each concrete subtype encapsulates its own data and message so callers can
/// use exhaustive pattern matching instead of fragile string parsing:
///
/// ```dart
/// switch (flag) {
///   case MissingLicenseFlag() => handleLegalRisk();
///   case StalePackageFlag(:final months) => warn('Stale for $months months');
///   case MultipleRisksFlag(:final riskCount) => block(riskCount);
///   // ...
/// }
/// ```
sealed class RedFlag {
  const RedFlag();

  /// Severity level of this risk signal.
  RedFlagSeverity get severity;

  /// Human-readable description of the risk.
  String get message;
}

// ---------------------------------------------------------------------------
// Concrete subtypes
// ---------------------------------------------------------------------------

final class StalePackageFlag extends RedFlag {
  const StalePackageFlag({required this.months});

  final int months;

  @override
  RedFlagSeverity get severity => RedFlagSeverity.warning;

  @override
  String get message => 'No release for $months months';
}

final class LimitedPlatformSupportFlag extends RedFlag {
  const LimitedPlatformSupportFlag({required this.count});

  final int count;

  @override
  RedFlagSeverity get severity => RedFlagSeverity.info;

  @override
  String get message => 'Limited platform support ($count platform(s))';
}

final class UnverifiedPublisherFlag extends RedFlag {
  const UnverifiedPublisherFlag();

  @override
  RedFlagSeverity get severity => RedFlagSeverity.warning;

  @override
  String get message => 'Unverified publisher';
}

final class MissingRepositoryFlag extends RedFlag {
  const MissingRepositoryFlag();

  @override
  RedFlagSeverity get severity => RedFlagSeverity.critical;

  @override
  String get message => 'Source code repository missing';
}

final class SuboptimalPanaScoreFlag extends RedFlag {
  const SuboptimalPanaScoreFlag({required this.score, required this.maxScore});

  final int score;
  final int maxScore;

  @override
  RedFlagSeverity get severity => RedFlagSeverity.info;

  @override
  String get message => 'Suboptimal static analysis score ($score/$maxScore)';
}

final class ExperimentalVersionFlag extends RedFlag {
  const ExperimentalVersionFlag({required this.version});

  final String version;

  @override
  RedFlagSeverity get severity => RedFlagSeverity.warning;

  @override
  String get message => 'Experimental version ($version)';
}

final class NoNullSafetyFlag extends RedFlag {
  const NoNullSafetyFlag();

  @override
  RedFlagSeverity get severity => RedFlagSeverity.critical;

  @override
  String get message => 'Sound null safety disabled';
}

final class NewPackageFlag extends RedFlag {
  const NewPackageFlag();

  @override
  RedFlagSeverity get severity => RedFlagSeverity.info;

  @override
  String get message => 'New package — limited track record';
}

final class NotDart3CompatibleFlag extends RedFlag {
  const NotDart3CompatibleFlag();

  @override
  RedFlagSeverity get severity => RedFlagSeverity.warning;

  @override
  String get message => 'Not Dart 3 compatible';
}

final class NotWasmReadyFlag extends RedFlag {
  const NotWasmReadyFlag();

  @override
  RedFlagSeverity get severity => RedFlagSeverity.info;

  @override
  String get message =>
      'Not WASM ready — degraded performance on modern Flutter Web';
}

/// Missing or unknown license — priority legal risk flag.
///
/// Any package without a detectable SPDX license requires legal review
/// before commercial use and is flagged as [RedFlagSeverity.critical].
final class MissingLicenseFlag extends RedFlag {
  const MissingLicenseFlag();

  @override
  RedFlagSeverity get severity => RedFlagSeverity.critical;

  @override
  String get message => 'No license detected — legal risk for commercial use';
}

/// Composite suspicious-package signal: multiple risk factors on an
/// unverified publisher.
final class MultipleRisksFlag extends RedFlag {
  const MultipleRisksFlag({required this.riskCount});

  final int riskCount;

  @override
  RedFlagSeverity get severity => RedFlagSeverity.critical;

  @override
  String get message =>
      'SUSPICIOUS: $riskCount risk factors on an unverified package';
}
