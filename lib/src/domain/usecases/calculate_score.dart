import 'package:cura/src/domain/entities/github_metrics.dart';
import 'package:cura/src/domain/entities/package_info.dart';
import 'package:cura/src/domain/entities/score.dart';
import 'package:cura/src/domain/entities/vulnerability.dart';
import 'package:cura/src/infrastructure/config/models/score_weights.dart';

/// Use case: compute a composite health [Score] (0–100) for a pub.dev package.
///
/// ## Scoring dimensions
///
/// | Dimension        | Default weight | Signal sources                                   |
/// |------------------|----------------|--------------------------------------------------|
/// | Vitality         | 40 pts         | Release recency, GitHub commit activity          |
/// | Technical Health | 30 pts         | Pana score, null safety, Dart 3, platform count  |
/// | Trust            | 20 pts         | Community likes, download popularity, GH stars   |
/// | Maintenance      | 10 pts         | Verified publisher, Flutter Favorite badge       |
///
/// Dimension bonuses (e.g. GitHub activity, stability) can push individual
/// dimension scores above their base weight; the final total is clamped to
/// `[0, 100]` after penalties are applied.
///
/// ## Penalties — applied after dimension scores
///
/// | Condition                                     | Deduction |
/// |-----------------------------------------------|-----------|
/// | No source-code repository linked              | −30 pts   |
/// | Experimental `0.0.x` version stalled > 1 year | −20 pts   |
///
/// ## Zero-score overrides
///
/// The score is forced to **0** (grade F, [HealthStatus.critical]) when:
/// - The package is marked *discontinued* on pub.dev.
/// - At least one *critical* CVE has no known patch.
///
/// ## Trusted-publisher fast path
///
/// Packages published by a trusted publisher (e.g. `dart.dev`, `flutter.dev`,
/// see [PackageInfo.isTrustedPublisher]) always receive a perfect score of
/// **100** and are exempt from all penalties and red-flag checks.
///
/// ## Configurability
///
/// Dimension weights are injected via [ScoreWeights] and must sum to 100.
/// Weights are validated in the constructor — an invalid configuration throws
/// an [ArgumentError] at wiring time, not at call time.
class CalculateScore {
  final ScoreWeights _weights;

  CalculateScore({
    ScoreWeights weights = const ScoreWeights(),
  }) : _weights = weights {
    if (!_weights.isValid) {
      throw ArgumentError(
        'Score weights must sum to 100 (got ${_weights.total})',
      );
    }
  }

  /// Computes the composite [Score] for [packageInfo].
  ///
  /// Optionally enriched with [githubMetrics] (stars, commit activity) and
  /// [vulnerabilities] (CVE data from OSV.dev).
  Score execute(
    PackageInfo packageInfo, {
    GitHubMetrics? githubMetrics,
    List<Vulnerability> vulnerabilities = const [],
  }) {
    // Trusted publisher fast path: always perfect score, no checks.
    if (packageInfo.isTrustedPublisher) {
      return _trustedPublisherScore(packageInfo);
    }

    // Zero-score overrides.
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

    // Four weighted dimensions.
    final vitality = _calculateVitality(packageInfo, githubMetrics);
    final technicalHealth = _calculateTechnicalHealth(packageInfo);
    final trust = _calculateTrust(packageInfo, githubMetrics);
    final maintenance = _calculateMaintenance(packageInfo);

    // Penalties applied after dimension scores.
    final penalty = _calculatePenalty(packageInfo);
    final total =
        (vitality + technicalHealth + trust + maintenance + penalty).clamp(
      0,
      100,
    );

    // Qualitative signals (independent of the numeric score).
    final redFlags = _detectRedFlags(packageInfo, githubMetrics);
    final recommendations =
        _generateRecommendations(packageInfo, total, redFlags);

    return Score(
      total: total,
      vitality: vitality,
      technicalHealth: technicalHealth,
      trust: trust,
      maintenance: maintenance,
      penalty: penalty,
      grade: _calculateGrade(total),
      breakdown: ScoreBreakdown(
        vitalityDetails: _getVitalityDetails(packageInfo),
        technicalHealthDetails: _getTechnicalHealthDetails(packageInfo),
        trustDetails: _getTrustDetails(packageInfo),
        maintenanceDetails: _getMaintenanceDetails(packageInfo),
      ),
      redFlags: redFlags,
      recommendations: recommendations,
    );
  }

  // ===========================================================================
  // TRUSTED PUBLISHER FAST PATH
  // ===========================================================================

  Score _trustedPublisherScore(PackageInfo packageInfo) {
    return Score(
      total: 100,
      vitality: _weights.vitality,
      technicalHealth: _weights.technicalHealth,
      trust: _weights.trust,
      maintenance: _weights.maintenance,
      penalty: 0,
      grade: 'A+',
      breakdown: ScoreBreakdown(
        vitalityDetails: 'Trusted publisher: ${packageInfo.publisherId}',
        technicalHealthDetails: 'Official package',
        trustDetails: 'Verified by ${packageInfo.publisherId}',
        maintenanceDetails: 'Officially maintained',
      ),
      redFlags: const [],
      recommendations: [
        'Official ${packageInfo.publisherId} package — highly recommended',
      ],
    );
  }

  // ===========================================================================
  // VITALITY (40 pts) — release recency + GitHub commit activity
  // ===========================================================================

  int _calculateVitality(PackageInfo packageInfo, GitHubMetrics? github) {
    final daysSinceUpdate = packageInfo.daysSinceLastUpdate;

    // Base score by release recency.
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
      baseScore = 0; // Abandoned (> 2 years)
    }

    // Stability bonus: mature, high-quality packages update infrequently by
    // design — don't penalise them for responsible release cadence.
    if (_isStablePackage(packageInfo) && daysSinceUpdate > 180) {
      baseScore += 5;
    }

    // GitHub activity bonus: recent commit history signals active development.
    if (github != null && github.commitCountLast90Days > 10) {
      baseScore += 5;
    }

    return (baseScore * _weights.vitality / 40).round();
  }

  // ===========================================================================
  // TECHNICAL HEALTH (30 pts) — static analysis + safety + platform breadth
  // ===========================================================================

  int _calculateTechnicalHealth(PackageInfo packageInfo) {
    var score = 0;

    // Pana score (15 pts max): pub.dev static analysis quality metric.
    score += (packageInfo.panaScore / 130 * 15).round().clamp(0, 15);

    // Sound null safety (10 pts): required for type-safe guarantees.
    if (packageInfo.isNullSafe) score += 10;

    // Dart 3 compatibility (3 pts): adoption of language evolution.
    if (packageInfo.isDart3Compatible) score += 3;

    // Platform breadth (2 pts max): each platform beyond the first signals
    // broader cross-platform support.
    score += (packageInfo.supportedPlatforms.length - 1).clamp(0, 2);

    return (score * _weights.technicalHealth / 30).round();
  }

  // ===========================================================================
  // TRUST (20 pts) — community adoption + popularity
  // ===========================================================================

  int _calculateTrust(PackageInfo packageInfo, GitHubMetrics? github) {
    var score = 0;

    // Community likes (10 pts max): 1 000 likes ≈ max.
    score += (packageInfo.likes / 1000 * 10).round().clamp(0, 10);

    // Download popularity (10 pts max): pub.dev popularity percentage.
    score += (packageInfo.popularity / 100 * 10).round().clamp(0, 10);

    // GitHub stars bonus (+3 pts): high star count signals community trust.
    if (github != null && github.stars > 1000) score += 3;

    return (score * _weights.trust / 20).round();
  }

  // ===========================================================================
  // MAINTENANCE (10 pts) — official support signals
  // ===========================================================================

  int _calculateMaintenance(PackageInfo packageInfo) {
    var score = 0;

    // Verified publisher (5 pts): identity verified by pub.dev.
    if (packageInfo.hasVerifiedPublisher) score += 5;

    // Flutter Favorite badge (5 pts): Flutter team quality endorsement.
    if (packageInfo.isFlutterFavorite) score += 5;

    return (score * _weights.maintenance / 10).round();
  }

  // ===========================================================================
  // PENALTIES — subtracted from total, result clamped to [0, 100]
  // ===========================================================================

  int _calculatePenalty(PackageInfo packageInfo) {
    var penalty = 0;

    // No source repository: code cannot be independently audited.
    if (!packageInfo.hasRepository) penalty -= 30;

    // Experimental versioning (0.0.x) stalled for over a year.
    if (packageInfo.version.startsWith('0.0.') &&
        packageInfo.daysSinceLastUpdate > 365) {
      penalty -= 20;
    }

    return penalty;
  }

  // ===========================================================================
  // RED FLAGS — qualitative risk signals (complement the numeric score)
  // ===========================================================================

  List<String> _detectRedFlags(
    PackageInfo packageInfo,
    GitHubMetrics? github,
  ) {
    final flags = <String>[];

    // Staleness beyond 18 months on a non-stable package.
    if (packageInfo.daysSinceLastUpdate > 540 &&
        !_isStablePackage(packageInfo)) {
      final months = (packageInfo.daysSinceLastUpdate / 30).round();
      flags.add('No release for $months months');
    }

    // Limited cross-platform support.
    if (packageInfo.supportedPlatforms.length < 3) {
      flags.add(
        'Limited platform support '
        '(${packageInfo.supportedPlatforms.length} platform(s))',
      );
    }

    // Unverified publisher.
    if (!packageInfo.hasVerifiedPublisher) {
      flags.add('Unverified publisher');
    }

    // No source repository: cannot audit the code.
    if (!packageInfo.hasRepository) {
      flags.add('Source code repository missing');
    }

    // Suboptimal static analysis score.
    if (packageInfo.panaScore < 100) {
      flags.add(
          'Suboptimal static analysis score (${packageInfo.panaScore}/130)');
    }

    // Experimental version (0.0.x).
    if (packageInfo.version.startsWith('0.0.')) {
      flags.add('Experimental version (${packageInfo.version})');
    }

    // Sound null safety disabled.
    if (!packageInfo.isNullSafe) {
      flags.add('Sound null safety disabled');
    }

    // New package — insufficient track record.
    if (packageInfo.isNew) {
      flags.add('New package — limited track record');
    }

    // Not Dart 3 compatible.
    if (!packageInfo.isDart3Compatible) {
      flags.add('Not Dart 3 compatible');
    }

    // WASM readiness check for web-targeting packages.
    if (packageInfo.isWeb && !packageInfo.isWasmReady) {
      flags.add('Not WASM ready — degraded performance on modern Flutter Web');
    }

    // Suspicious combination: multiple risk factors on an unverified package.
    if (flags.length >= 3 && !packageInfo.hasVerifiedPublisher) {
      flags.insert(
        0,
        'SUSPICIOUS: Multiple risk factors on an unverified package',
      );
    }

    return flags;
  }

  // ===========================================================================
  // RECOMMENDATIONS — actionable guidance derived from score and red flags
  // ===========================================================================

  List<String> _generateRecommendations(
    PackageInfo packageInfo,
    int total,
    List<String> flags,
  ) {
    if (total >= 80) {
      return ['Verified health — suitable for production use'];
    }

    final recs = <String>[];

    if (flags.any((f) => f.startsWith('SUSPICIOUS'))) {
      recs.add(
          'AVOID: Multiple risk factors detected on an unverified package');
      recs.add('Search for a maintained alternative from a verified publisher');
      return recs;
    }

    if (flags.any((f) => f.contains('No release')) &&
        !_isStablePackage(packageInfo)) {
      recs.add(
        'WARNING: Active maintenance not detected — seek modern alternatives',
      );
    }

    if (flags.any((f) => f.contains('Unverified'))) {
      recs.add(
        'ACTION: Verify author reputation and repository activity on GitHub',
      );
    }

    if (flags.any((f) => f.contains('repository missing'))) {
      recs.add(
        'CRITICAL: Cannot audit source code — avoid in professional projects',
      );
    }

    if (flags.any((f) => f.contains('Experimental version'))) {
      recs.add('WARNING: Unstable version — wait for a 1.0.0 release');
    }

    if (flags.any((f) => f.contains('New package'))) {
      recs.add('NEW: Recently published — monitor for API breaking changes');
      if (total < 50) {
        recs.add(
          'ADVISORY: Early-stage package — use only for non-critical features',
        );
      }
    }

    if (flags.any((f) => f.contains('Not WASM ready'))) {
      recs.add(
        'Not WASM ready — will fall back to CanvasKit/HTML, increasing bundle size',
      );
    }

    if (packageInfo.license == null) {
      recs.add(
        'No license detected — legal review required before commercial use',
      );
    }

    if (recs.isEmpty) {
      recs.add('CAUTION: Moderate score — manual evaluation recommended');
    }

    return recs;
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  /// Returns `true` if the package is considered stable for the purpose of
  /// relaxing maintenance-staleness penalties.
  ///
  /// A package qualifies as stable when it is published by a
  /// [trusted publisher][PackageInfo.isTrustedPublisher] **or** when it has
  /// reached a stable 1.x+ release with a near-perfect Pana score and broad
  /// adoption (popularity > 70 %).
  bool _isStablePackage(PackageInfo packageInfo) {
    if (packageInfo.isTrustedPublisher) return true;
    return packageInfo.isStable &&
        packageInfo.panaScore >= 130 &&
        packageInfo.popularity > 70;
  }

  String _calculateGrade(int total) {
    if (total >= 90) return 'A+';
    if (total >= 80) return 'A';
    if (total >= 70) return 'B';
    if (total >= 60) return 'C';
    if (total >= 50) return 'D';
    return 'F';
  }

  // ===========================================================================
  // BREAKDOWN DETAILS (verbose UI)
  // ===========================================================================

  String _getVitalityDetails(PackageInfo packageInfo) {
    return 'Last updated ${packageInfo.daysSinceLastUpdate} days ago';
  }

  String _getTechnicalHealthDetails(PackageInfo packageInfo) {
    return 'Pana: ${packageInfo.panaScore}/130, '
        'Null safe: ${packageInfo.isNullSafe}, '
        'Dart 3: ${packageInfo.isDart3Compatible}, '
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

// Agis en tant que Senior Software Architect. Je souhaite refactoriser ma classe CalculateScore pour la rendre plus scalable, testable et robuste.

// Problèmes identifiés :

// Fragilité sémantique : Les Red Flags et Recommandations sont basés sur du 'String matching', ce qui est sujet aux régressions.

// Couplage : La logique de calcul est monolithique.

// Extensibilité : Difficile d'ajouter de nouvelles dimensions de score sans surcharger la classe.

// Travail demandé :

// Strong Typing : Remplace les listes de String (flags/recs) par des objets typés (ex: Sealed Classes ou Enums avec métadonnées) pour gérer des niveaux de sévérité (INFO, WARNING, CRITICAL).

// Pattern Strategy / Visitor : Propose une structure où chaque dimension (Vitality, Trust, etc.) est un composant indépendant injecté dans le moteur.

// Gestion des Trusted Publishers : Affine la logique pour que le statut 'Trusted' ne soit plus un 'pass' total mais un bonus/plancher (un package Google obsolète ou vulnérable doit quand même être signalé).

// Validation de Licence : Intègre la vérification de licence comme un Red Flag prioritaire (Risque juridique).

// Testabilité : Structure le code pour faciliter le TDD, en isolant les calculs mathématiques des objets PackageInfo complexes.

// Contraintes :

// Utilise les fonctionnalités modernes de Dart (Patterns, Records, Sealed classes).

// Garde une approche 'Fail-safe'.

// Ne réécris pas toute la logique de points, concentre-toi sur la structure et la sécurité du typage