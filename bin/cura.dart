import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cura/src/commands/config_cli_command.dart';
import 'package:cura/src/commands/scan_command.dart';
import 'package:cura/src/commands/view_command.dart';
import 'package:cura/src/presentation/loggers/cura_logger.dart';
import 'package:cura/src/presentation/loggers/specialized/scan_logger.dart';
import 'package:cura/src/presentation/loggers/specialized/view_logger.dart';
import 'package:cura/src/presentation/themes/theme_manager.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:cura/src/infrastructure/api/pub_api_service.dart';
import 'package:cura/src/infrastructure/respositories/pub_dev_repository.dart';

void main(List<String> arguments) async {
  final service = PubApiService();
  final repository = PubDevRepository(service);
  final logger = Logger();
  final curaLogger = CuraLogger();
  final scanLogger = ScanLogger(logger: curaLogger);
  final viewLogger = ViewLogger(logger: curaLogger);

  final themeArg = arguments.firstWhere(
    (arg) => arg.startsWith('--theme='),
    orElse: () => '',
  );

  if (themeArg.isNotEmpty) {
    final themeName = themeArg.split('=')[1];
    try {
      ThemeManager.setTheme(themeName);
    } catch (e) {
      print('Invalid theme. Available: ${ThemeManager.availableThemes()}');
      exit(1);
    }
  } else {
    ThemeManager.autoDetect();
  }

  // Remove --theme from arguments to avoid polluting args
  // final cleanArgs = arguments.where((a) => !a.startsWith('--theme=')).toList();

  final runner = CommandRunner(
    'cura',
    '🩺 Flutter/Dart package health audit tool',
  )
    // ..run(cleanArgs)
    ..addCommand(ScanCommand(
      repository: repository,
      logger: logger,
      scanLogger: scanLogger
    ))
    ..addCommand(ViewCommand(
      repository: repository,
      logger: logger,
      viewLogger: viewLogger
    ))
    ..addCommand(ConfigCLICommand());

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
