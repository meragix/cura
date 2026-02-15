import 'dart:io';

import 'package:cura/src/commands/base/base_command.dart';
import 'package:cura/src/domain/models/package_health.dart';
import 'package:cura/src/domain/services/score_calculator.dart';
import 'package:cura/src/utils/helpers/pubspec_parser.dart';
import 'package:mason_logger/mason_logger.dart';

class ScanCommand extends BaseCommand {
  final Stopwatch _stopwatch = Stopwatch();

  @override
  String get name => 'scan';

  @override
  String get description => 'Scan the pubspec.yaml file';

  ScanCommand({
    required super.repository,
    required super.logger,
  }) {
    argParser.addOption('path', abbr: 'p', defaultsTo: './pubspec.yaml');
  }

  @override
  Future<void> run() async {
    final path = argResults!['path'] as String;
    final file = File(path);
    if (!file.existsSync()) {
      logger.err('❌ pubspec.yaml not found at $path');
      exit(1);
    }
    final results = <PackageHealth>[];
    var completed = 0;
    var cached = 0;
    var apiCalls = 0;

    _stopwatch.start();
    

    final content = await file.readAsString();
    final pubspec = PubspecParser.parse(content);
    // On extrait les noms (Business Rule: on ignore peut-être les dev_dependencies ?)
    final packages = pubspec.auditableDependencies;
    final total = packages.length;

    logger.info('Project: ${styleBold.wrap(pubspec.name)}');
    logger.info('Found $total auditable dependencies\n');

    final progress = logger.progress('Analyzing packages');

    for (final pkg in packages) {
      // operation
      final info = await repository.getPackageInfo(pkg.name);
      final score = ScoreCalculator.calculate(info);
      results.add(PackageHealth(info: info, score: score));

      completed++;

      // Mettre à jour le progress bar
      final filled = (completed / total * 20).round();
      final bar = '█' * filled + '░' * (20 - filled);
      final time = (_stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1);

      progress.update('Analyzing packages... [$bar] $completed/$total (${time}s)');
    }

    progress.complete('Analyzing packages... [${'█' * 20}] $total/$total');

    logger.info('');
    for (final pkg in results) {
      logger.info('✓ ${pkg.info.name}: ${pkg.score.total}/100');
    }
    logger.info('');
  }
}
