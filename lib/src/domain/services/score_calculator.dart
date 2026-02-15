import 'package:cura/src/core/constants.dart';
import 'package:cura/src/domain/models/cura_score.dart';
import 'package:cura/src/domain/models/package_info.dart';

class ScoreCalculator {
  static CuraScore calculate(PackageInfo pkg) {
    // Malus automatique
    if (pkg.isDiscontinued) {
      return CuraScore(
          total: 0,
          maintenance: 0,
          trust: 0,
          penalty: 0,
          status: HealthStatus.critical,
          grade: 'F',
          redFlags: [],
          recommendations: ['Package discontinued']);
    }

    final maintenance = _calculateMaintenanceScore(pkg);
    final trust = _calculateTrustScore(pkg);
    final popularity = _calculatePopularityScore(pkg);
    final penalties = _calculatePenalties(pkg);
    final redFlags = _detectRedFlags(pkg);

    final total = (maintenance + trust + popularity + penalties).clamp(0, 100);
    final status = _determineStatus(total);
    final grade = _calculateGrade(total);
    final recommendations = _generateRecommendations(pkg, total, redFlags);

    return CuraScore(
      total: total,
      maintenance: maintenance,
      trust: trust,
      penalty: penalties,
      status: status,
      grade: grade,
      redFlags: redFlags,
      recommendations: recommendations,
    );
  }

  static _calculateMaintenanceScore(PackageInfo pkg) {
    final days = pkg.daysSinceLastRelease;

    // RÈGLE NOUVELLE : Si paquet officiel ou très stable, ne pas pénaliser
    if (_isStablePackage(pkg)) {
      return CuraConstants.maintenanceMaxScore;
    }

    // Scoring normal pour les autres paquets
    if (days < CuraConstants.recentMaintenanceThreshold) {
      return CuraConstants.maintenanceMaxScore;
    }
    if (days < CuraConstants.acceptableMaintenanceThreshold) {
      return 20;
    }
    return 0;
  }

  static _isStablePackage(PackageInfo pkg) {
    // Un paquet est considéré stable si :
    // 1. Il a un publisher de confiance OU
    // 2. Il a un excellent score technique (130+) ET une bonne popularité
    if (pkg.isTrustedPublisher) {
      return true;
    }

    return pkg.panaScore >= CuraConstants.stablePackageMinScore &&
        pkg.popularity > 0.7;
  }

  static _calculateTrustScore(PackageInfo pkg) {
    int score = 0;

    // BONUS WHITELIST : Publishers officiels
    if (pkg.isTrustedPublisher) {
      return CuraConstants.trustMaxScore; // 30 points d'office
    }

    // Sinon, scoring normal
    if (pkg.hasVerifiedPublisher) score += 20;
    if (pkg.isFlutterFavorite) score += 10;

    return score;
  }

  static _calculatePopularityScore(PackageInfo pkg) {
    // Ratio santé technique / popularité
    // Un paquet populaire mais avec peu de points techniques = suspect
    final healthRatio = pkg.healthRatio;
    final popularityWeight = pkg.popularity;

    // Si paquet officiel, donner le score max
    if (pkg.isTrustedPublisher) {
      return CuraConstants.popularityMaxScore;
    }

    final balanceScore = (healthRatio * popularityWeight * 20).round();
    return balanceScore.clamp(0, CuraConstants.popularityMaxScore);
  }

  static _calculatePenalties(PackageInfo pkg) {
    int penalty = 0;

    // RÈGLE : Ne pas pénaliser les paquets officiels
    if (pkg.isTrustedPublisher) {
      return 0;
    }

    // Documentation insuffisante ET publisher inconnu = VIBE CODE
    // final hasMinimalDoc = (pkg.description?.length ?? 0) < CuraConstants.minDescriptionLength;
    // final isUnknownPublisher = !pkg.hasVerifiedPublisher;

    // if (hasMinimalDoc && isUnknownPublisher) {
    //   penalty -= 30; // Pénalité lourde pour vibe code probable
    // } else if (hasMinimalDoc) {
    //   penalty -= 15; // Pénalité modérée
    // }

    // Version 0.0.x depuis plus d'un an = paquet de test
    if (pkg.version.startsWith('0.0.') && pkg.daysSinceLastRelease > 365) {
      penalty -= 20;
    }

    // Pas de repository = impossible à auditer
    if (!pkg.hasRepository) {
      penalty -= 30;
    }

    return penalty.clamp(-CuraConstants.penaltyMaxDeduction, 0);
  }

  static List<String> _detectRedFlags(PackageInfo pkg) {
    final flags = <String>[];

    if (pkg.isTrustedPublisher) {
      return flags;
    }

    final daysSinceRelease = DateTime.now().difference(pkg.published).inDays;

    if (pkg.daysSinceLastRelease > CuraConstants.legacyThreshold &&
        !_isStablePackage(pkg)) {
      flags.add(
          'Legacy: No release for ${(daysSinceRelease / 30).round()} months');
    }

    if (pkg.platforms.length < 3) {
      flags.add('Limited platform support');
    }

    if (!pkg.hasVerifiedPublisher) {
      flags.add('Unverified publisher');
    }

    if (!pkg.hasRepository) {
      flags.add('Source code repository missing');
    }

    if (pkg.panaScore < 100) {
      flags.add(
          'Suboptimal static analysis score (${pkg.panaScore}/${pkg.maxPanaScore})');
    }

    if (pkg.version.startsWith('0.0.')) {
      flags.add('Experimental version (${pkg.version})');
    }

    if (!pkg.isNullSafe) {
      flags.add('Sound null safety disabled');
    }

    if (pkg.isNew) {
      flags.add('New package, limited track record');
    }

    if (!pkg.isDart3Compatible) {
      flags.add('Does not exploit Dart 3 features (Class modifiers/Records)');
    }

    if (pkg.platforms.contains('web') && !pkg.tags.contains('is:wasm-ready')) {
      flags.add('Not WASM ready: Degraded performance on modern Flutter Web');
    }

    if (pkg.tags.contains('runtime:native-jit') &&
        !pkg.tags.contains('runtime:native-aot')) {
      flags.add('JIT-only: Incompatible with iOS/Android Release builds');
    }

    if (pkg.tags.any((t) => t.startsWith('topic:'))) {
      // This can be used to validate if the package is properly "focused"
      // or if it's an overly large "Swiss knife" package.
    }

    if (flags.length >= 3 && !pkg.hasVerifiedPublisher) {
      flags.insert(0, 'SUSPICIOUS: Potential shadow dependency detected');
    }

    return flags;
  }

  /// Calcule la note (A-F)
  static String _calculateGrade(int total) {
    if (total >= 90) return 'A+';
    if (total >= 80) return 'A';
    if (total >= 70) return 'B';
    if (total >= 60) return 'C';
    if (total >= 50) return 'D';
    return 'F';
  }

  static HealthStatus _determineStatus(int score) {
    if (score >= 80) return HealthStatus.healthy;
    if (score >= 50) return HealthStatus.warning;
    return HealthStatus.critical;
  }

  static List<String> _generateRecommendations(
    PackageInfo pkg,
    int score,
    List<String> flags,
  ) {
    if (pkg.isTrustedPublisher) {
      return ['Official ${pkg.publisherId} package - Highly recommended'];
    }

    if (score >= 80) {
      return ['Verified health - Suitable for production use'];
    }

    final recs = <String>[];

    if (flags.any((f) => f.contains('SUSPICIOUS'))) {
      recs.add('AVOID: Likely an experimental or test package');
      recs.add('Search for a maintained alternative from a verified publisher');
      return recs;
    }

    if (flags.any((f) => f.contains('Legacy')) && !_isStablePackage(pkg)) {
      recs.add(
          'WARNING: Active maintenance not detected. Seek modern alternatives');
    }

    if (flags.any((f) => f.contains('Unverified'))) {
      recs.add(
          'ACTION: Verify author reputation and repository activity on GitHub');
    }

    if (flags.any((f) => f.contains('Source code'))) {
      recs.add(
          'CRITICAL: Cannot audit source code. Avoid in professional projects');
    }

    if (flags.any((f) => f.contains('Experimental'))) {
      recs.add('WARNING: Unstable version - Wait for a 1.0.0 release');
    }

    if (recs.isEmpty) {
      recs.add('CAUTION: Moderate score - Manual evaluation recommended');
    }

    final isRecent = flags.any((f) => f.contains('New package'));

    if (isRecent) {
      recs.add('NEW: Recently published. Monitor for API breaking changes');
    }

    // If it's recent AND the score is low
    if (isRecent && score < 50) {
      recs.add(
          'ADVISORY: Early stage package. Use only for non-critical features');
    }

    if (flags.any((f) => f.contains('Not WASM ready'))) {
      recs.add(
          'Not WASM ready. This will fallback to canvaskit/html, increasing bundle size.');
    }

    if (!pkg.licenseOsiApproved) {
      recs.add(
          'Non-OSI approved license detected. Legal review might be required for commercial use.');
    }

    if (flags.any((f) => f.contains('JIT-only'))) {
      recs.add(
          'Incompatible with AOT compilation. App will crash in Release mode.');
    }

    return recs;
  }
}
