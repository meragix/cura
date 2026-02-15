import 'package:args/command_runner.dart';
import 'package:cura/src/domain/respositories/package_repository.dart';
import 'package:mason_logger/mason_logger.dart';

abstract class BaseCommand<T> extends Command {
  final PackageRepository repository;
  final Logger logger;
  // late final CommandContext context;

  //  @override
  // Future run() async {
  //   // Initialiser le context selon les flags
  //   context = _buildContext();

  //   // Déléguer à la méthode execute
  //   return await execute(context);
  // }

  //  /// Méthode à implémenter par les commands enfants
  // Future execute(CommandContext context);

  // CommandContext _buildContext() {
  //   final verbose = argResults?['verbose'] as bool? ?? false;
  //   final json = argResults?['json'] as bool? ?? false;
  //   final quiet = argResults?['quiet'] as bool? ?? false;

  //   // Créer le bon logger
  //   final CuraLogger logger;
  //   if (json) {
  //     logger = JsonLogger();
  //   } else if (quiet) {
  //     logger = NormalLogger(level: LogLevel.silent);
  //   } else if (verbose) {
  //     logger = VerboseLogger();
  //   } else {
  //     logger = NormalLogger();
  //   }
  //  }

  BaseCommand({
    required this.repository,
    required this.logger,
  });
}
