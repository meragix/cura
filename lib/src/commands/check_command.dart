import 'package:cura/src/commands/base_command.dart';
import 'package:cura/src/domain/models/package_health.dart';
import 'package:cura/src/domain/services/score_calculator.dart';

class CheckCommand extends BaseCommand {
  @override
  String get name => 'check';

  @override
  String get description => 'Analyse le pubspec.yaml local';

  CheckCommand({
    required super.repository,
    required super.logger,
  }) {
    argParser.addOption('path', abbr: 'p', defaultsTo: './pubspec.yaml');
  }

  @override
  Future<void> run() async {
    final path = argResults!['path'] as String;

    logger.info('📦 Analyse de $path...');

    final packages = await repository.getPackagesFromPubspec(path);
    final results = <PackageHealth>[];

    for (final pkg in packages) {
      final score = ScoreCalculator.calculate(pkg);
      results.add(PackageHealth(info: pkg, score: score));
    }

    _displayResults(results);
  }

  void _displayResults(List<PackageHealth> results) {
    // Utiliser TableFormatter
  }
}
