import 'package:cura/src/commands/base_command.dart';
import 'package:cura/src/core/error/error_handler.dart';
import 'package:cura/src/core/error/exception.dart';
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
        'verbose',
        aliases: ['-v'],
        negatable: false,
        help: 'Output as JSON',
      )
      ..addFlag(
        'json',
        negatable: false,
        help: 'Output as JSON',
      );
  }

  @override
  Future<int> run() async {
     final outputVerbose = argResults!['verbose'] as bool;
     final outputJson = argResults!['json'] as bool;

    final errorHandler = ErrorHandler(logger: logger, verbose: outputVerbose);

    return await errorHandler.handle(() async {
      final packageName = argResults!.rest.firstOrNull;
    
      if (packageName == null) {
        throw ValidationException(['Package name is required']);
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
    });
  }
}
