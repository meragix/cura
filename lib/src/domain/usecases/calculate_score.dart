import 'package:cura/src/domain/entities/github_metrics.dart';
import 'package:cura/src/domain/entities/package_info.dart';
import 'package:cura/src/domain/entities/score.dart';
import 'package:cura/src/domain/entities/vulnerability.dart';
import 'package:cura/src/infrastructure/config/models/score_weights.dart';

/// Use Case : Calculer le score de santé d'un package
///
/// Algorithme :
/// - Vitality (40 pts) : Fréquence des mises à jour
/// - Technical Health (30 pts) : Pana score + null safety + platforms
/// - Trust (20 pts) : Likes + popularité
/// - Maintenance (10 pts) : Publisher vérifié + Flutter Favorite
///
/// Pénalités automatiques (score = 0) :
/// - Package discontinued
/// - Vulnérabilité critique non patchée
class CalculateScore {
  final ScoreWeights _weights;

  CalculateScore({
    ScoreWeights weights = const ScoreWeights(),
  }) : _weights = weights {
    // Validation des poids
    if (!_weights.isValid) {
      throw ArgumentError(
        'Score weights must sum to 100 (got ${_weights.total})',
      );
    }
  }

  /// Execute le calcul de score
  Score execute(
    PackageInfo packageInfo, {
    GitHubMetrics? githubMetrics,
    List<Vulnerability> vulnerabilities = const [],
  }) {
    // Pénalités automatiques (score = 0)
    if (packageInfo.isDiscontinued) {
      return Score.discontinued(packageInfo.name);
    }

    final hasCriticalVuln = vulnerabilities.any(
      (v) => v.severity == VulnerabilitySeverity.critical,
    );

    if (hasCriticalVuln) {
      return Score.vulnerable(
        packageInfo.name,
        vulnerabilities: vulnerabilities,
      );
    }

    // Calcul normal
    final vitality = _calculateVitality(packageInfo, githubMetrics);
    final technicalHealth = _calculateTechnicalHealth(packageInfo);
    final trust = _calculateTrust(packageInfo, githubMetrics);
    final maintenance = _calculateMaintenance(packageInfo, githubMetrics);

    final total = vitality + technicalHealth + trust + maintenance;

    return Score(
      total: total,
      vitality: vitality,
      technicalHealth: technicalHealth,
      trust: trust,
      maintenance: maintenance,
      grade: _calculateGrade(total),
      breakdown: ScoreBreakdown(
        vitalityDetails: _getVitalityDetails(packageInfo),
        technicalHealthDetails: _getTechnicalHealthDetails(packageInfo),
        trustDetails: _getTrustDetails(packageInfo),
        maintenanceDetails: _getMaintenanceDetails(packageInfo),
      ),
    );
  }

  // ==========================================================================
  // VITALITY (40 points) : Fréquence de maintenance
  // ==========================================================================

  int _calculateVitality(PackageInfo packageInfo, GitHubMetrics? github) {
    final daysSinceUpdate =
        DateTime.now().difference(packageInfo.lastPublished).inDays;

    // Base score selon ancienneté
    int baseScore;
    if (daysSinceUpdate <= 30) {
      baseScore = 40; // Updated this month
    } else if (daysSinceUpdate <= 90) {
      baseScore = 35; // Updated this quarter
    } else if (daysSinceUpdate <= 180) {
      baseScore = 28; // Updated this semester
    } else if (daysSinceUpdate <= 365) {
      baseScore = 20; // Updated this year
    } else if (daysSinceUpdate <= 730) {
      baseScore = 10; // Updated in last 2 years
    } else {
      baseScore = 0; // Abandoned (>2 years)
    }

    // Bonus pour packages stables (>v2.0, Pana >130, Popularity >90%)
    final isStable = packageInfo.version.startsWith('2.') &&
        packageInfo.panaScore > 130 &&
        packageInfo.popularity > 90;

    if (isStable && daysSinceUpdate > 180) {
      baseScore += 5; // Bonus stabilité
    }

    // Bonus : Commits récents sur GitHub (max +5 points)
    if (github != null && github.commitCountLast90Days > 10) {
      baseScore += 5;
    }

    return (baseScore * _weights.vitality / 40).round();
  }

  // ==========================================================================
  // TECHNICAL HEALTH (30 points) : Qualité technique
  // ==========================================================================

  int _calculateTechnicalHealth(PackageInfo packageInfo) {
    var score = 0;

    // 1. Pana Score (15 points max)
    final panaScore = (packageInfo.panaScore / 130 * 15).round();
    score += panaScore;

    // 2. Null Safety (10 points)
    if (packageInfo.isNullSafe) {
      score += 10;
    }

    // 3. Platform Support (5 points)
    final platformCount = packageInfo.supportedPlatforms.length.clamp(0, 5);
    score += platformCount;

    return (score * _weights.technicalHealth / 30).round();
  }

  // ==========================================================================
  // TRUST (20 points) : Confiance communautaire
  // ==========================================================================

  int _calculateTrust(PackageInfo packageInfo, GitHubMetrics? github) {
    var score = 0;

    // 1. Likes (10 points max)
    final likeScore = (packageInfo.likes / 1000 * 10).round().clamp(0, 10);
    score += likeScore;

    // 2. Popularity (10 points max)
    final popScore = (packageInfo.popularity / 100 * 10).round().clamp(0, 10);
    score += popScore;

    // Bonus : Stars GitHub élevées (max +3 points)
    if (github != null && github.stars > 1000) {
      score += 3;
    }

    return (score * _weights.trust / 20).round();
  }

  // ==========================================================================
  // MAINTENANCE (10 points) : Support officiel
  // ==========================================================================

  int _calculateMaintenance(PackageInfo packageInfo, GitHubMetrics? github) {
    var score = 0;

    // 1. Verified Publisher (5 points)
    if (packageInfo.publisherId != null &&
        packageInfo.publisherId!.isNotEmpty) {
      score += 5;
    }

    // 2. Flutter Favorite (5 points)
    if (packageInfo.isFlutterFavorite) {
      score += 5;
    }

    // Bonus : Issues gérées (ratio open/closed faible = bon signe)
    // todo: Implémenter si on fetch closed issues count

    return (score * _weights.maintenance / 10).round();
  }

  // ==========================================================================
  // GRADE CALCULATION
  // ==========================================================================

  String _calculateGrade(int total) {
    if (total >= 90) return 'A+';
    if (total >= 80) return 'A';
    if (total >= 70) return 'B';
    if (total >= 60) return 'C';
    if (total >= 50) return 'D';
    return 'F';
  }

  // ==========================================================================
  // BREAKDOWN DETAILS (pour UI verbose)
  // ==========================================================================

  String _getVitalityDetails(PackageInfo packageInfo) {
    final days = DateTime.now().difference(packageInfo.lastPublished).inDays;
    return 'Last updated $days days ago';
  }

  String _getTechnicalHealthDetails(PackageInfo packageInfo) {
    return 'Pana: ${packageInfo.panaScore}/130, '
        'Null safe: ${packageInfo.isNullSafe}, '
        'Platforms: ${packageInfo.supportedPlatforms.length}';
  }

  String _getTrustDetails(PackageInfo packageInfo) {
    return 'Likes: ${packageInfo.likes}, '
        'Popularity: ${packageInfo.popularity}%';
  }

  String _getMaintenanceDetails(PackageInfo packageInfo) {
    final parts = <String>[];
    if (packageInfo.publisherId != null) {
      parts.add('Publisher: ${packageInfo.publisherId}');
    }
    if (packageInfo.isFlutterFavorite) {
      parts.add('Flutter Favorite');
    }
    return parts.isEmpty ? 'No official support' : parts.join(', ');
  }
}
