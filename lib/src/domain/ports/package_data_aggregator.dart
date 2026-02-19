import 'package:cura/src/domain/value_objects/package_result.dart';

/// Port : Agrégation de données multi-API pour un package
///
/// Responsabilité : Orchestrer pub.dev + GitHub + OSV en une seule abstraction
abstract class PackageDataAggregator {
  /// Fetch toutes les données d'un package en parallèle
  ///
  /// Garanties :
  /// - pub.dev est OBLIGATOIRE (fail si indisponible)
  /// - GitHub est OPTIONNEL (null si pas de repo ou fail)
  /// - OSV est OPTIONNEL ([] si indisponible)
  Future<PackageResult> fetchAll(String packageName);

  /// Fetch multiple packages en streaming
  Stream<PackageResult> fetchMany(List<String> packageNames);

  /// Cleanup
  Future<void> dispose();
}
