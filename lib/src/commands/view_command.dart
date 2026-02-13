import 'package:cura/src/commands/base_command.dart';
import 'package:cura/src/domain/models/package_health.dart';
import 'package:cura/src/domain/services/score_calculator.dart';
import 'package:cura/src/presentation/formatters/table_formatter.dart';
import 'package:mason_logger/mason_logger.dart';

class ViewCommand extends BaseCommand<int> {
  @override
  String get name => 'view';

  @override
  String get description => 'Displays the health of a specific package';

  ViewCommand({
    required super.repository,
    required super.logger,
  }) {
    argParser
      ..addFlag(
        'json',
        negatable: false,
        help: 'Output as JSON',
      );
  }

  @override
  Future<int> run() async {
    final packageName = argResults!.rest.firstOrNull;
    final outputJson = argResults!['json'] as bool;

    if (packageName == null) {
      logger.err('❌ Package name required');
      logger.info('Usage: cura view <package_name>');
      return 1;
    }

    if (!outputJson) {
      logger.info('\n🔍 Fetching data for ${cyan.wrap(packageName)}...\n');
    }

    final progress = logger.progress('Analyzing');

    final info = await repository.getPackageInfo(packageName);
    final score = ScoreCalculator.calculate(info);
    final health = PackageHealth(info: info, score: score);

    progress.complete();

    TableFormatter.displayDetailed(health, logger);
    return 0;
  }
}
