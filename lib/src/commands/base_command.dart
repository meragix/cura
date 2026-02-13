import 'package:args/command_runner.dart';
import 'package:cura/src/domain/respositories/package_repository.dart';
import 'package:mason_logger/mason_logger.dart';

abstract class BaseCommand<T> extends Command {
  final PackageRepository repository;
  final Logger logger;

  BaseCommand({
    required this.repository,
    required this.logger,
  });
}