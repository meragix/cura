import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cura/src/presentation/loggers/console_logger.dart';
import 'package:cura/src/shared/app_info.dart';
import 'package:mason_logger/mason_logger.dart';

/// Command : cura version
///
/// Display version information with details
class VersionCommand extends Command<int> {
  final ConsoleLogger _logger;

  VersionCommand({required ConsoleLogger logger}) : _logger = logger {
    argParser.addFlag(
      'short',
      abbr: 's',
      help: 'Show short version only',
      defaultsTo: false,
    );
  }

  @override
  String get name => 'version';

  @override
  List<String> get aliases => ['v', '--version', '-v'];

  @override
  String get description => 'Show version information';

  @override
  Future<int> run() async {
    final short = argResults!['short'] as bool;

    if (short) {
      // Short version: just the number
      final version = await AppInfo.getVersion();
      _logger.info(version);
      return 0;
    }

    // Detailed version info
    await _showDetailedVersion();

    return 0;
  }

  Future<void> _showDetailedVersion() async {
    final version = await AppInfo.getVersion();

    _logger.spacer();
    _logger.info('═' * 65);
    _logger.spacer();

    // Header with logo
    _logger.primary('${AppInfo.name} v$version');
    _logger.muted(AppInfo.description);

    _logger.spacer();
    _logger.divider(length: 65);
    _logger.spacer();

    // Info
    _logger.info('Information:');
    _logger.info('  Author:      ${AppInfo.author}');
    _logger.info('  Homepage:    ${cyan.wrap(AppInfo.homepage)}');
    _logger.info('  License:     MIT');

    _logger.spacer();

    // Environment info
    _logger.info('Environment:');
    _logger.info('  Dart SDK:    ${_getDartVersion()}');
    _logger.info('  Platform:    ${_getPlatform()}');

    _logger.spacer();
    _logger.info('═' * 65);
    _logger.spacer();

    // Check for updates
    await _checkForUpdates(version);
  }

  String _getDartVersion() {
    // Get Dart SDK version
    return Platform.version.split(' ').first;
  }

  String _getPlatform() {
    final os = Platform.operatingSystem;
    final arch = Platform.version.contains('x64')
        ? 'x64'
        : Platform.version.contains('arm64')
            ? 'arm64'
            : 'unknown';

    return '$os ($arch)';
  }

  Future<void> _checkForUpdates(String currentVersion) async {
    try {
      // todo: Fetch latest version from pub.dev API
      // final latestVersion = await _fetchLatestVersion();

      // if (_isNewerVersion(latestVersion, currentVersion)) {
      //   _logger.spacer();
      //   _logger.alert(
      //     '📢 New version available: $latestVersion',
      //     level: AlertLevel.info,
      //   );
      //   _logger.info('   Run: dart pub global activate cura');
      //   _logger.spacer();
      // }
    } catch (e) {
      // Silent fail (no internet, API error, etc.)
    }
  }
}
