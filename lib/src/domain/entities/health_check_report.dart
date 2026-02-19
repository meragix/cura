/// Entity : Rapport de santé (pour CI/CD)
class HealthCheckReport {
  final int totalPackages;
  final int averageScore;
  final int belowThreshold;
  final int vulnerablePackages;
  final int discontinuedPackages;
  final bool hasFailed;

  const HealthCheckReport({
    required this.totalPackages,
    required this.averageScore,
    required this.belowThreshold,
    required this.vulnerablePackages,
    required this.discontinuedPackages,
    required this.hasFailed,
  });
}
