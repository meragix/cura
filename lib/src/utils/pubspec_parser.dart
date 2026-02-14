import 'package:yaml/yaml.dart';

/// Parser de pubspec.yaml
class PubspecParser {
  /// Parse un pubspec.yaml en string
  Pubspec parse(String content) {
    final yaml = loadYaml(content) as YamlMap;

    return Pubspec(
      name: yaml['name'] as String,
      version: yaml['version'] as String?,
      dependencies: _parseDependencies(yaml['dependencies']),
      devDependencies: _parseDependencies(yaml['dev_dependencies']),
    );
  }

  Map<String, String> _parseDependencies(dynamic deps) {
    if (deps == null) return {};
    if (deps is! YamlMap) return {};

    final result = <String, String>{};

    deps.forEach((key, value) {
      if (value is String) {
        result[key.toString()] = value;
      } else if (value is YamlMap) {
        // Hosted dependency
        final version = value['version'] as String?;
        result[key.toString()] = version ?? 'any';
      }
    });

    return result;
  }
}

/// Model simple de pubspec
class Pubspec {
  final String name;
  final String? version;
  final Map<String, String> dependencies;
  final Map<String, String> devDependencies;

  const Pubspec({
    required this.name,
    this.version,
    required this.dependencies,
    required this.devDependencies,
  });
}
