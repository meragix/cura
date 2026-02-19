import 'package:yaml/yaml.dart';

/// Représente les contraintes du SDK
class SDKEnvironment {
  final String? dart;
  final String? flutter;

  const SDKEnvironment({this.dart, this.flutter});
}

/// Types de sources de dépendances pour une analyse granulaire
sealed class DependencySource {
  final String name;
  const DependencySource(this.name);
}

class PubDevSource extends DependencySource {
  final String version;
  const PubDevSource(super.name, this.version);
}

class LocalSource extends DependencySource {
  final String path;
  const LocalSource(super.name, this.path);
}

class GitSource extends DependencySource {
  final String url;
  final String? ref;
  const GitSource(super.name, this.url, this.ref);
}

/// Modèle métier complet du Pubspec
class Pubspec {
  final String name;
  final String? version;
  final SDKEnvironment environment;
  final List<DependencySource> dependencies;
  final List<DependencySource> devDependencies;
  final List<DependencySource> overrides;

  const Pubspec({
    required this.name,
    this.version,
    required this.environment,
    required this.dependencies,
    required this.devDependencies,
    required this.overrides,
  });

  /// Helper to retrieve only the packages to audit on pub.dev
  List<PubDevSource> get auditableDeps =>
      dependencies.whereType<PubDevSource>().toList();

  List<PubDevSource> get auditableDevDeps =>
      devDependencies.whereType<PubDevSource>().toList();
}

class PubspecParser {
  static Pubspec parse(String content) {
    final yaml = loadYaml(content) as YamlMap;

    return Pubspec(
      name: yaml['name'] as String,
      version: yaml['version'] as String?,
      environment: _parseEnvironment(yaml['environment']),
      dependencies: _parseSection(yaml['dependencies']),
      devDependencies: _parseSection(yaml['dev_dependencies']),
      overrides: _parseSection(yaml['dependency_overrides']),
    );
  }

  static SDKEnvironment _parseEnvironment(dynamic env) {
    if (env is! YamlMap) return const SDKEnvironment();
    return SDKEnvironment(
      dart: env['sdk']?.toString(),
      flutter: env['flutter']?.toString(),
    );
  }

  static List<DependencySource> _parseSection(dynamic section) {
    if (section is! YamlMap) return [];

    return section.entries.map((entry) {
      final name = entry.key.toString();
      final value = entry.value;

      // Cas 1 : Version simple (ex: dio: ^5.0.0)
      if (value is String) {
        return PubDevSource(name, value);
      }

      // Cas 2 : Configuration complexe (YamlMap)
      if (value is YamlMap) {
        // Source locale (Path)
        if (value.containsKey('path')) {
          return LocalSource(name, value['path'] as String);
        }

        // Source Git
        if (value.containsKey('git')) {
          final git = value['git'];
          if (git is String) return GitSource(name, git, null);
          if (git is YamlMap) {
            return GitSource(
              name,
              git['url'] as String,
              git['ref']?.toString(),
            );
          }
        }

        // Hosted (Custom server ou version explicite)
        final version = value['version']?.toString() ?? 'any';
        return PubDevSource(name, version);
      }

      return PubDevSource(name, 'any');
    }).toList();
  }
}
