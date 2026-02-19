import 'package:yaml/yaml.dart';

/// Customizable weights for scoring
class ScoreWeights {
  final int vitality;
  final int technicalHealth;
  final int trust;
  final int maintenance;

  const ScoreWeights({
    this.vitality = 40,
    this.technicalHealth = 30,
    this.trust = 20,
    this.maintenance = 10,
  });

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

  factory ScoreWeights.fromJson(Map<String, dynamic> json) {
    return ScoreWeights(
      vitality: json['vitality'] ?? 40,
      technicalHealth: json['technicalHealth'] ?? 30,
      trust: json['trust'] ?? 20,
      maintenance: json['maintenance'] ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vitality': vitality,
      'technicalHealth': technicalHealth,
      'trust': trust,
      'maintenance': maintenance,
    };
  }

  /// Valide que le total fait 100
  bool get isValid => vitality + technicalHealth + trust + maintenance == 100;

  int get total => vitality + technicalHealth + trust + maintenance;
}
