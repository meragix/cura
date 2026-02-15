import 'dart:io';

import 'package:cura/src/commands/base/base_command.dart';
import 'package:cura/src/domain/models/cura_score.dart';
import 'package:cura/src/domain/models/package_health.dart';
import 'package:cura/src/domain/services/score_calculator.dart';
import 'package:cura/src/presentation/loggers/specialized/scan_logger.dart';
import 'package:cura/src/presentation/renderers/table_renderer.dart';
import 'package:cura/src/utils/helpers/pubspec_parser.dart';
import 'package:mason_logger/mason_logger.dart';

class ScanCommand extends BaseCommand {
  final ScanLogger scanLogger;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  String get name => 'scan';

  @override
  String get description => 'Scan the pubspec.yaml file';

  ScanCommand({
    required super.repository,
    required super.logger,
    required this.scanLogger,
  }) {
    argParser
      ..addOption('path',
          abbr: 'p',
          defaultsTo: './pubspec.yaml',
          help: 'Project directory (default: current directory)')
      ..addOption('min-score', help: 'Fail if average score below threshold')
      ..addOption('json', help: 'Output results as JSON')
      ..addOption('no-github',
          help: 'Skip GitHub metrics (faster, offline mode)')
      ..addOption('theme',
          help: 'Override theme (dark, light, minimal, dracula)');
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
    final criticalPackages = <PackageHealth>[];
    var completed = 0;
    // var cached = 0;
    // var apiCalls = 0;

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
      if (score.status == HealthStatus.critical) {
        criticalPackages.add(PackageHealth(info: info, score: score));
      }
      results.add(PackageHealth(info: info, score: score));

      completed++;

      // Mettre à jour le progress bar
      final filled = (completed / total * 20).round();
      final bar = '█' * filled + '░' * (20 - filled);
      final time = (_stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1);

      progress
          .update('Analyzing packages... [$bar] $completed/$total (${time}s)');
    }

    progress.complete('Analyzing packages... [${'█' * 20}] $total/$total');

    logger.info('');

    // 3. Afficher le tableau
    scanLogger.printTable(results);

    // 4. Afficher le résumé
    final summary = _calculateSummary(results);
    _printSummary(summary);

    // 5. Afficher les problèmes critiques
    scanLogger.printCriticalIssues(criticalPackages);

    // 6. Footer
    _stopwatch.stop();
    _printFooter(summary);
  }

  void _printSummary(AnalysisSummary summary) {
    final separator = '━' * 56;
    logger.info(separator);
    logger.info(styleBold.wrap('SUMMARY'));
    logger.info(
        '  ${green.wrap('✓ Healthy: ')} ${summary.healthy.toString().padLeft(2)} packages (${summary.healthyPercent}%)');
    logger.info(
        '  ${yellow.wrap('! Warning: ')} ${summary.warning.toString().padLeft(2)} packages (${summary.warningPercent}%)');
    logger.info(
        '  ${red.wrap('✗ Critical:')} ${summary.critical.toString().padLeft(2)} packages (${summary.criticalPercent}%)');
    logger.info('');

    // Score global avec couleur
    final scoreColor = _getScoreColor(summary.overallScore);
    final scoreEmoji = summary.overallScore >= 80
        ? '✅'
        : summary.overallScore >= 60
            ? '⚠️'
            : '❌';
    logger.info(
        '  Overall health: ${scoreColor.wrap('${summary.overallScore}/100')} $scoreEmoji');
  }

  void _printFooter(AnalysisSummary summary) {
    final elapsed = _stopwatch.elapsedMilliseconds / 1000;
    final cached = summary.total - summary.apiCalls;

    logger.info('');
    logger.info(
      darkGray.wrap('⏱️  Total time: ${elapsed.toStringAsFixed(1)}s '
          '(${cached} cached, ${summary.apiCalls} API calls)'),
    );

    logger.info(
      darkGray.wrap("💡 Run 'cura view <package>' for detailed analysis"),
    );
    logger.info('');
  }

  AnalysisSummary _calculateSummary(List<PackageHealth> results) {
    final healthy =
        results.where((p) => p.score.status == HealthStatus.healthy).length;
    final warning =
        results.where((p) => p.score.status == HealthStatus.warning).length;
    final critical =
        results.where((p) => p.score.status == HealthStatus.critical).length;
    final total = results.length;
    //final apiCalls = results.where((r) => !r.cached).length;

    final avgScore =
        results.map((p) => p.score.total).reduce((a, b) => a + b) ~/ total;

    return AnalysisSummary(
      healthy: healthy,
      warning: warning,
      critical: critical,
      total: total,
      healthyPercent: (healthy / total * 100).round(),
      warningPercent: (warning / total * 100).round(),
      criticalPercent: (critical / total * 100).round(),
      overallScore: avgScore,
      apiCalls: results.length, // todo: replace this with real implementation
    );
  }

  AnsiCode _getScoreColor(int score) {
    if (score >= 80) return green;
    if (score >= 60) return yellow;
    return red;
  }
}

// todo: merge this with summaryLogger
class AnalysisSummary {
  final int healthy;
  final int warning;
  final int critical;
  final int total;
  final int healthyPercent;
  final int warningPercent;
  final int criticalPercent;
  final int overallScore;
  final int apiCalls;

  AnalysisSummary({
    required this.healthy,
    required this.warning,
    required this.critical,
    required this.total,
    required this.healthyPercent,
    required this.warningPercent,
    required this.criticalPercent,
    required this.overallScore,
    required this.apiCalls,
  });
}
