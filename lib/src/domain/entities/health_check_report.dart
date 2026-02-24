/// Aggregated audit summary for a full `cura check` run.
///
/// Produced by `CheckPackagesUsecase` after auditing all packages listed in
/// `pubspec.yaml`. The report is used by:
/// - The `CheckPresenter` to render the final summary table.
/// - The CLI runner to derive the process exit code for CI/CD integration.
///
/// [hasFailed] is `true` when at least one package is below the configured
/// minimum score threshold, is vulnerable, or is discontinued — depending on
/// the active configuration flags (`--fail-on-vulnerable`,
/// `--fail-on-discontinued`, `--min-score`).
class HealthCheckReport {
  /// Total number of packages that were audited.
  final int totalPackages;

  /// Mean score across all audited packages (0–100).
  final int averageScore;

  /// Number of packages whose score is below the configured minimum threshold.
  final int belowThreshold;

  /// Number of packages with at least one critical vulnerability.
  final int vulnerablePackages;

  /// Number of packages marked as discontinued on pub.dev.
  final int discontinuedPackages;

  /// Whether the overall check should be treated as a failure.
  ///
  /// Drives the CLI exit code: `0` on success, non-zero on failure.
  final bool hasFailed;

  /// Creates a [HealthCheckReport] from the aggregated audit counters.
  const HealthCheckReport({
    required this.totalPackages,
    required this.averageScore,
    required this.belowThreshold,
    required this.vulnerablePackages,
    required this.discontinuedPackages,
    required this.hasFailed,
  });
}
