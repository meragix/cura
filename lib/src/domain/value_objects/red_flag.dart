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
  String get message => 'Inactive for $months months. No releases detected.';
}

final class LimitedPlatformSupportFlag extends RedFlag {
  const LimitedPlatformSupportFlag({required this.count});

  final int count;

  @override
  RedFlagSeverity get severity => RedFlagSeverity.info;

  @override
  String get message => 'Supports $count platform(s) only. Coverage is insufficient.';
}

final class UnverifiedPublisherFlag extends RedFlag {
  const UnverifiedPublisherFlag();

  @override
  RedFlagSeverity get severity => RedFlagSeverity.warning;

  @override
  String get message => 'Publisher identity is unverified.';
}

final class MissingRepositoryFlag extends RedFlag {
  const MissingRepositoryFlag();

  @override
  RedFlagSeverity get severity => RedFlagSeverity.critical;

  @override
  String get message => 'No source repository linked. Code is unauditable.';
}

final class SuboptimalPanaScoreFlag extends RedFlag {
  const SuboptimalPanaScoreFlag({required this.score, required this.maxScore});

  final int score;
  final int maxScore;

  @override
  RedFlagSeverity get severity => RedFlagSeverity.info;

  @override
  String get message => 'Static analysis score is $score/$maxScore. Below the acceptable threshold.';
}

final class ExperimentalVersionFlag extends RedFlag {
  const ExperimentalVersionFlag({required this.version});

  final String version;

  @override
  RedFlagSeverity get severity => RedFlagSeverity.warning;

  @override
  String get message => 'Version $version is pre-stable. API stability is not guaranteed.';
}

final class NoNullSafetyFlag extends RedFlag {
  const NoNullSafetyFlag();

  @override
  RedFlagSeverity get severity => RedFlagSeverity.critical;

  @override
  String get message => 'Sound null safety is disabled.';
}

final class NewPackageFlag extends RedFlag {
  const NewPackageFlag();

  @override
  RedFlagSeverity get severity => RedFlagSeverity.info;

  @override
  String get message => 'Package is recently published. Track record is insufficient.';
}

final class NotDart3CompatibleFlag extends RedFlag {
  const NotDart3CompatibleFlag();

  @override
  RedFlagSeverity get severity => RedFlagSeverity.warning;

  @override
  String get message => 'Not compatible with Dart 3.';
}

final class NotWasmReadyFlag extends RedFlag {
  const NotWasmReadyFlag();

  @override
  RedFlagSeverity get severity => RedFlagSeverity.info;

  @override
  String get message => 'Not WASM ready. Performance will degrade on modern Flutter Web targets.';
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
  String get message => 'No license detected. Use in commercial projects requires legal review.';
}

/// Composite suspicious-package signal: multiple risk factors on an
/// unverified publisher.
final class MultipleRisksFlag extends RedFlag {
  const MultipleRisksFlag({required this.riskCount});

  final int riskCount;

  @override
  RedFlagSeverity get severity => RedFlagSeverity.critical;

  @override
  String get message => '$riskCount risk factors detected on an unverified publisher.';
}
