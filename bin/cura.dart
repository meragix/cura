import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cura/src/commands/check_command.dart';
import 'package:cura/src/commands/view_command.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:cura/src/infrastructure/api/pub_api_service.dart';
import 'package:cura/src/infrastructure/respositories/pub_dev_repository.dart';

void main(List<String> arguments) async {
  final service = PubApiService();
  final repository = PubDevRepository(service);
  final logger = Logger();

  final runner = CommandRunner(
    'cura',
    '🩺 Flutter/Dart package health audit tool',
  )
    ..addCommand(CheckCommand(
      repository: repository,
      logger: logger,
    ))
    ..addCommand(ViewCommand(
      repository: repository,
      logger: logger,
    ));

  try {
    final exitCode = await runner.run(arguments);
    exit(exitCode ?? 0);
  } on UsageException catch (e) {
    print(e);
    exit(64); // Exit code for usage error
  } catch (e) {
    print('Unexpected error: $e');
    exit(1);
  }
}
