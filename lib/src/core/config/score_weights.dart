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

  factory ScoreWeights.fromYaml(YamlMap yaml) {
    return ScoreWeights(
      vitality: yaml['vitality'] as int? ?? 40,
      technicalHealth: yaml['technical_health'] as int? ?? 30,
      trust: yaml['trust'] as int? ?? 20,
      maintenance: yaml['maintenance'] as int? ?? 10,
    );
  }

  /// Valide que le total fait 100
  bool get isValid => vitality + technicalHealth + trust + maintenance == 100;
}
