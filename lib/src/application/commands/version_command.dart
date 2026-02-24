import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cura/src/infrastructure/services/update_checker_service.dart';
import 'package:cura/src/presentation/loggers/console_logger.dart';
import 'package:cura/src/shared/app_info.dart';
import 'package:mason_logger/mason_logger.dart';

/// Displays version, environment info, and checks pub.dev for updates.
///
/// Usage:
///   cura version           — full output (environment + update check)
///   cura version --short   — bare version number only (machine-readable)
///   cura v                 — alias for `cura version`
class VersionCommand extends Command<int> {
  final ConsoleLogger _logger;
  final UpdateCheckerService _updateChecker;

  VersionCommand({
    required ConsoleLogger logger,
    required UpdateCheckerService updateChecker,
  })  : _logger = logger,
        _updateChecker = updateChecker {
    argParser.addFlag(
      'short',
      abbr: 's',
      help: 'Show short version only (bare semver string)',
      defaultsTo: false,
    );
  }

  @override
  String get name => 'version';

  /// `'v'` lets users type `cura v` as a convenient alias.
  /// `'--version'` and `'-v'` are NOT listed here — they are global flags
  /// intercepted by the pre-parse in `main()` before the command runner runs.
  @override
  List<String> get aliases => ['v'];

  @override
  String get description => 'Show version information';

  @override
  Future<int> run() async {
    final short = argResults!['short'] as bool;
    final version = await AppInfo.getVersion();

    if (short) {
      _logger.info(version);
      return 0;
    }

    await _showDetailedVersion(version);
    return 0;
  }

  Future<void> _showDetailedVersion(String version) async {
    _logger.spacer();
    _logger.info('═' * 65);
    _logger.spacer();

    _logger.primary('${AppInfo.name} v$version');
    _logger.muted(AppInfo.description);

    _logger.spacer();
    _logger.divider(length: 65);
    _logger.spacer();

    _logger.info('Information:');
    _logger.info('  Author:      ${AppInfo.author}');
    _logger.info('  Homepage:    ${cyan.wrap(AppInfo.homepage)}');
    _logger.info('  License:     MIT');

    _logger.spacer();

    _logger.info('Environment:');
    _logger.info('  Dart SDK:    ${_getDartVersion()}');
    _logger.info('  Platform:    ${_getPlatform()}');

    _logger.spacer();
    _logger.info('═' * 65);
    _logger.spacer();

    await _checkForUpdates(version);
  }

  /// Returns the Dart SDK semver string (e.g. `'3.3.0'`).
  String _getDartVersion() => Platform.version.split(' ').first;

  /// Returns a human-readable OS + architecture string.
  ///
  /// Architecture is inferred from [Platform.version] because `dart:io` does
  /// not expose a dedicated API for it without `dart:ffi`.
  String _getPlatform() {
    final os = Platform.operatingSystem;
    final v = Platform.version;
    final arch = v.contains('arm64')
        ? 'arm64'
        : v.contains('x64')
            ? 'x64'
            : v.contains('ia32')
                ? 'ia32'
                : 'unknown';
    return '$os ($arch)';
  }

  /// Queries pub.dev and prints an upgrade notice when a newer version exists.
  ///
  /// Never throws — a failed update check must not interrupt normal output.
  Future<void> _checkForUpdates(String currentVersion) async {
    final info = await _updateChecker.checkForUpdate(currentVersion);
    if (info == null || !info.updateAvailable) return;

    _logger.spacer();
    _logger.alert(
      'New version available: ${info.latestVersion}  '
      '(current: ${info.currentVersion})',
      level: AlertLevel.info,
    );
    _logger.muted('  Run: dart pub global activate cura');
    _logger.spacer();
  }
}
