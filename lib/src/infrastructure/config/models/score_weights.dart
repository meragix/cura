/// Dimension weights used by [CalculateScore] to compute a package's final
/// health score (0–100).
///
/// The four dimensions must **sum to exactly 100**; validate with [isValid]
/// before passing weights to the scoring algorithm.
///
/// ## Default weights
///
/// | Dimension        | Default | Description                              |
/// |------------------|---------|------------------------------------------|
/// | vitality         | 40      | Release frequency and recency            |
/// | technicalHealth  | 30      | Pana score, null safety, Dart 3 compat   |
/// | trust            | 20      | Community likes and download popularity  |
/// | maintenance      | 10      | Verified publisher, Flutter Favorite     |
///
/// ## YAML representation
///
/// In config files the keys use `snake_case`:
/// ```yaml
/// score_weights:
///   vitality: 40
///   technical_health: 30
///   trust: 20
///   maintenance: 10
/// ```
///
/// ## JSON representation (cache / inter-process)
///
/// JSON keys use `camelCase` to match Dart field names:
/// ```json
/// { "vitality": 40, "technicalHealth": 30, "trust": 20, "maintenance": 10 }
/// ```
class ScoreWeights {
  /// Weight for the vitality dimension (release recency & frequency).
  final int vitality;

  /// Weight for the technical-health dimension (Pana, null-safety, Dart 3).
  final int technicalHealth;

  /// Weight for the trust dimension (likes, download popularity).
  final int trust;

  /// Weight for the maintenance dimension (verified publisher, Flutter Fav).
  final int maintenance;

  /// Creates score weights with the given distribution.
  ///
  /// Defaults reproduce the standard 40/30/20/10 split. Call [isValid] after
  /// construction to assert that the values sum to 100.
  const ScoreWeights({
    this.vitality = 40,
    this.technicalHealth = 30,
    this.trust = 20,
    this.maintenance = 10,
  });

  /// Returns a copy with the provided fields replaced.
  ScoreWeights copyWith({
    int? vitality,
    int? technicalHealth,
    int? trust,
    int? maintenance,
  }) {
    return ScoreWeights(
      vitality: vitality ?? this.vitality,
      technicalHealth: technicalHealth ?? this.technicalHealth,
      trust: trust ?? this.trust,
      maintenance: maintenance ?? this.maintenance,
    );
  }

  /// Deserialises from a JSON map (camelCase keys).
  ///
  /// Missing keys fall back to the standard defaults.
  factory ScoreWeights.fromJson(Map<String, dynamic> json) {
    return ScoreWeights(
      vitality: json['vitality'] as int? ?? 40,
      technicalHealth: json['technicalHealth'] as int? ?? 30,
      trust: json['trust'] as int? ?? 20,
      maintenance: json['maintenance'] as int? ?? 10,
    );
  }

  /// Serialises to a JSON map (camelCase keys).
  Map<String, dynamic> toJson() {
    return {
      'vitality': vitality,
      'technicalHealth': technicalHealth,
      'trust': trust,
      'maintenance': maintenance,
    };
  }

  /// `true` when the four weights sum to exactly 100.
  bool get isValid => total == 100;

  /// Sum of all four dimension weights.
  int get total => vitality + technicalHealth + trust + maintenance;

  @override
  String toString() =>
      'ScoreWeights(vitality: $vitality, technicalHealth: $technicalHealth, '
      'trust: $trust, maintenance: $maintenance)';
}
