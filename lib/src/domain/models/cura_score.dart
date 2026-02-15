class CuraScore {
  final int total;
  final int maintenance;
  final int trust;
  final int penalty;
  final HealthStatus status;
  final String grade;
  final List<String> redFlags;
  final List<String> recommendations;

  CuraScore({
    required this.total,
    required this.maintenance,
    required this.trust,
    required this.penalty,
    required this.status,
    required this.grade,
    required this.redFlags,
    required this.recommendations,
  });

  String get emoji {
    switch (status) {
      case HealthStatus.healthy:
        return '✅';
      case HealthStatus.warning:
        return '⚠️';
      case HealthStatus.critical:
        return '❌';
    }
  }
}

enum HealthStatus {
  healthy, // 80-100
  warning, // 50-79
  critical, // 0-49
}

// class HealthScore {
//   int maintenance;    // Activité du repo
//   int stability;      // Fréquence de breaking changes
//   int responsiveness; // Temps de réponse aux issues
//   int security;       // CVEs + dépendances risquées

//   // Score final = weighted average
//   int get overall => (
//     maintenance * 0.3 +
//     stability * 0.2 +
//     responsiveness * 0.3 +
//     security * 0.2
//   ).round();
// }

