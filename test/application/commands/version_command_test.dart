import 'package:args/command_runner.dart';
import 'package:cura/src/application/commands/version_command.dart';
import 'package:cura/src/application/dto/update_info.dart';
import 'package:cura/src/domain/ports/update_checker.dart';
import 'package:cura/src/presentation/loggers/console_logger.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockUpdateChecker extends Mock implements UpdateChecker {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ConsoleLogger _quietLogger() => ConsoleLogger(
      useColors: false,
      useEmojis: false,
      quiet: true,
      level: Level.error,
    );

/// Builds a [CommandRunner] wired with [VersionCommand] using a mock
/// [UpdateChecker] and a silent [ConsoleLogger].
(CommandRunner<int>, MockUpdateChecker) _buildRunner({
  UpdateInfo? updateInfo,
}) {
  final mockChecker = MockUpdateChecker();
  when(() => mockChecker.checkForUpdate(any()))
      .thenAnswer((_) async => updateInfo);

  final command = VersionCommand(
    logger: _quietLogger(),
    updateChecker: mockChecker,
  );

  final runner = CommandRunner<int>('cura', 'test runner')..addCommand(command);

  return (runner, mockChecker);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('VersionCommand', () {
    // -----------------------------------------------------------------------
    // Metadata
    // -----------------------------------------------------------------------
    test('name is "version"', () {
      final (runner, _) = _buildRunner();
      expect(runner.commands.containsKey('version'), isTrue);
    });

    test('has "v" alias', () {
      final command = VersionCommand(
        logger: _quietLogger(),
        updateChecker: MockUpdateChecker()..mockCheckForUpdate(null),
      );
      expect(command.aliases, contains('v'));
    });

    test('has --short flag', () {
      final command = VersionCommand(
        logger: _quietLogger(),
        updateChecker: MockUpdateChecker()..mockCheckForUpdate(null),
      );
      expect(command.argParser.options.containsKey('short'), isTrue);
    });

    // -----------------------------------------------------------------------
    // --short mode
    // -----------------------------------------------------------------------
    test('--short returns exit code 0', () async {
      final (runner, _) = _buildRunner();
      final exitCode = await runner.run(['version', '--short']);
      expect(exitCode, 0);
    });

    test('--short does not call the update checker', () async {
      final (runner, mockChecker) = _buildRunner();
      await runner.run(['version', '--short']);
      verifyNever(() => mockChecker.checkForUpdate(any()));
    });

    // -----------------------------------------------------------------------
    // Full version output
    // -----------------------------------------------------------------------
    test('full version returns exit code 0', () async {
      final (runner, _) = _buildRunner();
      final exitCode = await runner.run(['version']);
      expect(exitCode, 0);
    });

    test('full version calls the update checker once', () async {
      final (runner, mockChecker) = _buildRunner();
      await runner.run(['version']);
      verify(() => mockChecker.checkForUpdate(any())).called(1);
    });

    // -----------------------------------------------------------------------
    // Update check integration
    // -----------------------------------------------------------------------
    test('completes without error when update check returns null', () async {
      final (runner, _) = _buildRunner(updateInfo: null);
      final exitCode = await runner.run(['version']);
      expect(exitCode, 0);
    });

    test('completes without error when update available', () async {
      final (runner, _) = _buildRunner(
        updateInfo: UpdateInfo(
          currentVersion: '0.1.0',
          latestVersion: '1.0.0',
          updateAvailable: true,
        ),
      );
      final exitCode = await runner.run(['version']);
      expect(exitCode, 0);
    });

    test('completes without error when no update needed', () async {
      final (runner, _) = _buildRunner(
        updateInfo: UpdateInfo(
          currentVersion: '1.0.0',
          latestVersion: '1.0.0',
          updateAvailable: false,
        ),
      );
      final exitCode = await runner.run(['version']);
      expect(exitCode, 0);
    });

    // -----------------------------------------------------------------------
    // "v" alias
    // -----------------------------------------------------------------------
    test('"v" alias runs successfully', () async {
      final (runner, _) = _buildRunner();
      final exitCode = await runner.run(['v']);
      expect(exitCode, 0);
    });
  });

  // -------------------------------------------------------------------------
  // Port contract
  // -------------------------------------------------------------------------
  group('UpdateChecker port contract', () {
    test('MockUpdateChecker satisfies UpdateChecker interface', () {
      expect(MockUpdateChecker(), isA<UpdateChecker>());
    });
  });
}

// ---------------------------------------------------------------------------
// Extension to cut boilerplate in simple mock setup
// ---------------------------------------------------------------------------
extension on MockUpdateChecker {
  void mockCheckForUpdate(UpdateInfo? info) {
    when(() => checkForUpdate(any())).thenAnswer((_) async => info);
  }
}
