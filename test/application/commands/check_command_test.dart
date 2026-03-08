import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cura/src/application/commands/check_command.dart';
import 'package:cura/src/domain/entities/package_audit_result.dart';
import 'package:cura/src/domain/entities/package_info.dart';
import 'package:cura/src/domain/entities/score.dart';
import 'package:cura/src/domain/entities/vulnerability.dart';
import 'package:cura/src/domain/usecases/check_packages_usecase.dart';
import 'package:cura/src/domain/value_objects/errors.dart';
import 'package:cura/src/domain/value_objects/grade.dart';
import 'package:cura/src/domain/value_objects/result.dart';
import 'package:cura/src/presentation/presenters/check_presenter.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Mocks & Fakes
// ---------------------------------------------------------------------------

class MockCheckPackagesUsecase extends Mock implements CheckPackagesUsecase {}

class MockCheckPresenter extends Mock implements CheckPresenter {}

/// Concrete no-op Progress so tests don't need to stub every call.
class FakeProgress extends Fake implements Progress {
  @override
  void cancel() {}
  @override
  void complete([String? update]) {}
  @override
  void update(String update) {}
  @override
  void fail([String? update]) {}
}

class FakePackageAuditResult extends Fake implements PackageAuditResult {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

PackageInfo _makePackageInfo({
  String name = 'test_pkg',
  bool isDiscontinued = false,
}) {
  return PackageInfo(
    name: name,
    version: '1.0.0',
    description: 'Test package',
    lastPublished: DateTime.now(),
    panaScore: 100,
    likes: 100,
    popularity: 60,
    grantedPoints: 100,
    maxPoints: 140,
    isNullSafe: true,
    isDart3Compatible: true,
    isDiscontinued: isDiscontinued,
    isFlutterFavorite: false,
    isNew: false,
    isWasmReady: false,
    supportedPlatforms: ['dart'],
  );
}

Score _makeScore({int total = 80}) {
  return Score(
    total: total,
    vitality: 30,
    technicalHealth: 25,
    trust: 15,
    maintenance: 10,
    grade: Grade.fromScore(total),
    breakdown: const ScoreBreakdown(
      vitalityDetails: '',
      technicalHealthDetails: '',
      trustDetails: '',
      maintenanceDetails: '',
    ),
  );
}

PackageAuditResult _makeAuditResult({
  String name = 'test_pkg',
  int score = 80,
  bool isDiscontinued = false,
  List<Vulnerability> vulnerabilities = const [],
  List<AuditIssue> issues = const [],
}) {
  return PackageAuditResult(
    name: name,
    version: '1.0.0',
    packageInfo: _makePackageInfo(name: name, isDiscontinued: isDiscontinued),
    score: _makeScore(total: score),
    fromCache: false,
    vulnerabilities: vulnerabilities,
    issues: issues,
  );
}

Vulnerability _makeCriticalVuln() => Vulnerability(
      id: 'CVE-2024-0001',
      summary: 'Critical',
      details: '',
      severity: VulnerabilitySeverity.critical,
      published: DateTime(2024),
      affectedVersions: ['1.0.0'],
      references: [],
    );

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Minimal valid pubspec.yaml with the given package names under [dependencies].
String _pubspecWith(List<String> packages,
    {List<String> devPackages = const []}) {
  final deps = packages.map((p) => '  $p: ^1.0.0').join('\n');
  final devDeps = devPackages.map((p) => '  $p: ^1.0.0').join('\n');
  final devSection = devPackages.isEmpty ? '' : '\ndev_dependencies:\n$devDeps';
  return 'name: test_app\ndependencies:\n$deps$devSection\n';
}

/// Creates a [CommandRunner] wired with a [CheckCommand] backed by [usecase]
/// and [presenter]. Tests call `runner.run(['check', '--path', path, ...])`.
CommandRunner<int> _makeRunner(
  MockCheckPackagesUsecase usecase,
  MockCheckPresenter presenter, {
  List<String> ignoredPackages = const [],
  int defaultMinScore = 70,
  bool defaultFailOnVulnerable = true,
  bool defaultFailOnDiscontinued = true,
}) {
  final command = CheckCommand(
    checkUseCase: usecase,
    presenter: presenter,
    ignoredPackages: ignoredPackages,
    defaultMinScore: defaultMinScore,
    defaultFailOnVulnerable: defaultFailOnVulnerable,
    defaultFailOnDiscontinued: defaultFailOnDiscontinued,
  );
  return CommandRunner<int>('cura', 'test')..addCommand(command);
}

void main() {
  late MockCheckPackagesUsecase usecase;
  late MockCheckPresenter presenter;
  late Directory tempDir;
  late File pubspecFile;

  setUpAll(() {
    registerFallbackValue(FakeProgress());
    registerFallbackValue(FakePackageAuditResult());
    registerFallbackValue(Stopwatch());
  });

  setUp(() async {
    usecase = MockCheckPackagesUsecase();
    presenter = MockCheckPresenter();

    tempDir = await Directory.systemTemp.createTemp('cura_check_test_');
    pubspecFile = File('${tempDir.path}/pubspec.yaml');

    // Stub all presenter side-effect methods (void returns).
    when(() => presenter.showHeader(total: any(named: 'total')))
        .thenReturn(null);
    when(() => presenter.showProgress()).thenReturn(FakeProgress());
    when(() => presenter.updateProgress(
          current: any(named: 'current'),
          total: any(named: 'total'),
          progress: any(named: 'progress'),
        )).thenReturn(null);
    when(() => presenter.stopProgress(
          current: any(named: 'current'),
          total: any(named: 'total'),
          progress: any(named: 'progress'),
        )).thenReturn(null);
    when(() => presenter.collectPackageResult(any())).thenReturn(null);
    when(() => presenter.showPackageError(any(), any())).thenReturn(null);
    when(() => presenter.showSummary(
          total: any(named: 'total'),
          failures: any(named: 'failures'),
          stopwatch: any(named: 'stopwatch'),
        )).thenReturn(null);
    when(() => presenter.showJsonOutput(any())).thenReturn(null);
    when(() => presenter.showError(any())).thenReturn(null);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  // -------------------------------------------------------------------------
  // pubspec parsing
  // -------------------------------------------------------------------------

  group('pubspec parsing', () {
    test('returns 1 when pubspec has no auditable dependencies', () async {
      await pubspecFile.writeAsString('name: test_app\ndependencies:\n');

      final runner = _makeRunner(usecase, presenter);
      final exitCode = await runner.run(['check', '--path', pubspecFile.path]);

      expect(exitCode, 1);
      verify(() => presenter.showError(any())).called(1);
    });

    test('excludes ignored packages from the audit', () async {
      await pubspecFile.writeAsString(_pubspecWith(['dio', 'provider']));

      when(() => usecase.execute(['provider'])).thenAnswer(
        (_) => Stream.fromIterable([
          Result.success(_makeAuditResult(name: 'provider')),
        ]),
      );

      final runner = _makeRunner(usecase, presenter, ignoredPackages: ['dio']);
      final exitCode = await runner.run(['check', '--path', pubspecFile.path]);

      expect(exitCode, 0);
      verify(() => usecase.execute(['provider'])).called(1);
    });

    test('includes dev_dependencies when --dev-dependencies flag is set',
        () async {
      await pubspecFile
          .writeAsString(_pubspecWith(['dio'], devPackages: ['build_runner']));

      when(() => usecase.execute(['dio', 'build_runner'])).thenAnswer(
        (_) => Stream.fromIterable([
          Result.success(_makeAuditResult(name: 'dio')),
          Result.success(_makeAuditResult(name: 'build_runner')),
        ]),
      );

      final runner = _makeRunner(usecase, presenter);
      final exitCode = await runner
          .run(['check', '--path', pubspecFile.path, '--dev-dependencies']);

      expect(exitCode, 0);
      verify(() => usecase.execute(['dio', 'build_runner'])).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // Exit code — success
  // -------------------------------------------------------------------------

  group('exit code — success', () {
    test('returns 0 when all packages pass min-score', () async {
      await pubspecFile.writeAsString(_pubspecWith(['dio']));

      when(() => usecase.execute(['dio'])).thenAnswer(
        (_) => Stream.fromIterable([
          Result.success(_makeAuditResult(score: 85)),
        ]),
      );

      final runner = _makeRunner(usecase, presenter);
      final exitCode = await runner
          .run(['check', '--path', pubspecFile.path, '--min-score', '70']);

      expect(exitCode, 0);
    });

    test('returns 0 when package score equals min-score (boundary)', () async {
      await pubspecFile.writeAsString(_pubspecWith(['dio']));

      when(() => usecase.execute(['dio'])).thenAnswer(
        (_) => Stream.fromIterable([
          Result.success(_makeAuditResult(score: 70)),
        ]),
      );

      final runner = _makeRunner(usecase, presenter);
      final exitCode = await runner
          .run(['check', '--path', pubspecFile.path, '--min-score', '70']);

      expect(exitCode, 0);
    });
  });

  // -------------------------------------------------------------------------
  // Exit code — min-score failures
  // -------------------------------------------------------------------------

  group('exit code — min-score', () {
    test('returns 1 when package score is below min-score', () async {
      await pubspecFile.writeAsString(_pubspecWith(['old_pkg']));

      when(() => usecase.execute(['old_pkg'])).thenAnswer(
        (_) => Stream.fromIterable([
          Result.success(_makeAuditResult(name: 'old_pkg', score: 60)),
        ]),
      );

      final runner = _makeRunner(usecase, presenter);
      final exitCode = await runner
          .run(['check', '--path', pubspecFile.path, '--min-score', '80']);

      expect(exitCode, 1);
    });

    test(
        'returns 0 when score is below default min-score but flag overrides it',
        () async {
      await pubspecFile.writeAsString(_pubspecWith(['old_pkg']));

      when(() => usecase.execute(['old_pkg'])).thenAnswer(
        (_) => Stream.fromIterable([
          Result.success(_makeAuditResult(name: 'old_pkg', score: 50)),
        ]),
      );

      final runner = _makeRunner(usecase, presenter);
      // Explicitly set min-score to 40 — score 50 should pass.
      final exitCode = await runner
          .run(['check', '--path', pubspecFile.path, '--min-score', '40']);

      expect(exitCode, 0);
    });
  });

  // -------------------------------------------------------------------------
  // Exit code — fail-on-discontinued
  // -------------------------------------------------------------------------

  group('exit code — fail-on-discontinued', () {
    test('returns 1 when package is discontinued and --fail-on-discontinued',
        () async {
      await pubspecFile.writeAsString(_pubspecWith(['old_pkg']));

      when(() => usecase.execute(['old_pkg'])).thenAnswer(
        (_) => Stream.fromIterable([
          Result.success(_makeAuditResult(
            name: 'old_pkg',
            score: 0,
            isDiscontinued: true,
            issues: [AuditIssue.discontinued('old_pkg')],
          )),
        ]),
      );

      final runner = _makeRunner(usecase, presenter);
      final exitCode = await runner.run([
        'check',
        '--path',
        pubspecFile.path,
        '--fail-on-discontinued',
      ]);

      expect(exitCode, 1);
    });

    test('returns 0 when discontinued but --no-fail-on-discontinued', () async {
      await pubspecFile.writeAsString(_pubspecWith(['old_pkg']));

      when(() => usecase.execute(['old_pkg'])).thenAnswer(
        (_) => Stream.fromIterable([
          Result.success(_makeAuditResult(
            name: 'old_pkg',
            isDiscontinued: true,
            score: 80,
          )),
        ]),
      );

      final runner = _makeRunner(usecase, presenter);
      final exitCode = await runner.run([
        'check',
        '--path',
        pubspecFile.path,
        '--no-fail-on-discontinued',
        '--min-score',
        '0',
      ]);

      expect(exitCode, 0);
    });
  });

  // -------------------------------------------------------------------------
  // Exit code — fail-on-vulnerable
  // -------------------------------------------------------------------------

  group('exit code — fail-on-vulnerable', () {
    test('returns 1 when package has vulnerabilities and --fail-on-vulnerable',
        () async {
      await pubspecFile.writeAsString(_pubspecWith(['unsafe_pkg']));

      final vuln = _makeCriticalVuln();
      when(() => usecase.execute(['unsafe_pkg'])).thenAnswer(
        (_) => Stream.fromIterable([
          Result.success(_makeAuditResult(
            name: 'unsafe_pkg',
            vulnerabilities: [vuln],
            issues: [
              AuditIssue.criticalVulnerabilities(
                  count: 1, cveIds: ['CVE-2024-0001'])
            ],
          )),
        ]),
      );

      final runner = _makeRunner(usecase, presenter);
      final exitCode = await runner.run([
        'check',
        '--path',
        pubspecFile.path,
        '--fail-on-vulnerable',
        '--min-score',
        '0',
      ]);

      expect(exitCode, 1);
    });

    test('returns 0 when vulnerable but --no-fail-on-vulnerable', () async {
      await pubspecFile.writeAsString(_pubspecWith(['unsafe_pkg']));

      final vuln = _makeCriticalVuln();
      when(() => usecase.execute(['unsafe_pkg'])).thenAnswer(
        (_) => Stream.fromIterable([
          Result.success(_makeAuditResult(
            name: 'unsafe_pkg',
            vulnerabilities: [vuln],
          )),
        ]),
      );

      final runner = _makeRunner(usecase, presenter);
      final exitCode = await runner.run([
        'check',
        '--path',
        pubspecFile.path,
        '--no-fail-on-vulnerable',
        '--min-score',
        '0',
      ]);

      expect(exitCode, 0);
    });
  });

  // -------------------------------------------------------------------------
  // Exit code — fetch failures
  // -------------------------------------------------------------------------

  group('exit code — fetch failures', () {
    test('returns 1 when package is not found', () async {
      await pubspecFile.writeAsString(_pubspecWith(['missing_pkg']));

      when(() => usecase.execute(['missing_pkg'])).thenAnswer(
        (_) => Stream.fromIterable([
          Result.failure(const PackageProviderError.notFound('missing_pkg')),
        ]),
      );

      final runner = _makeRunner(usecase, presenter);
      final exitCode = await runner.run(['check', '--path', pubspecFile.path]);

      expect(exitCode, 1);
    });

    test('returns 1 immediately on NetworkError', () async {
      await pubspecFile.writeAsString(_pubspecWith(['flaky_pkg']));

      when(() => usecase.execute(['flaky_pkg'])).thenAnswer(
        (_) => Stream.fromIterable([
          Result.failure(
              const PackageProviderError.network('connection refused')),
        ]),
      );

      final runner = _makeRunner(usecase, presenter);
      final exitCode = await runner.run(['check', '--path', pubspecFile.path]);

      expect(exitCode, 1);
      // Summary must NOT be shown on early abort.
      verifyNever(() => presenter.showSummary(
            total: any(named: 'total'),
            failures: any(named: 'failures'),
            stopwatch: any(named: 'stopwatch'),
          ));
    });

    test('returns 1 but processes remaining packages after notFound', () async {
      await pubspecFile.writeAsString(_pubspecWith(['bad_pkg', 'good_pkg']));

      when(() => usecase.execute(['bad_pkg', 'good_pkg'])).thenAnswer(
        (_) => Stream.fromIterable([
          Result.failure(const PackageProviderError.notFound('bad_pkg')),
          Result.success(_makeAuditResult(name: 'good_pkg')),
        ]),
      );

      final runner = _makeRunner(usecase, presenter);
      final exitCode = await runner.run(['check', '--path', pubspecFile.path]);

      expect(exitCode, 1);
      // good_pkg result was still collected.
      verify(() => presenter.collectPackageResult(any())).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // Output mode
  // -------------------------------------------------------------------------

  group('output mode', () {
    test('calls showJsonOutput when --json flag is set', () async {
      await pubspecFile.writeAsString(_pubspecWith(['dio']));

      when(() => usecase.execute(['dio'])).thenAnswer(
        (_) => Stream.fromIterable([
          Result.success(_makeAuditResult()),
        ]),
      );

      final runner = _makeRunner(usecase, presenter);
      await runner.run(['check', '--path', pubspecFile.path, '--json']);

      verify(() => presenter.showJsonOutput(any())).called(1);
      verifyNever(() => presenter.showSummary(
            total: any(named: 'total'),
            failures: any(named: 'failures'),
            stopwatch: any(named: 'stopwatch'),
          ));
    });

    test('calls showSummary when --json is not set', () async {
      await pubspecFile.writeAsString(_pubspecWith(['dio']));

      when(() => usecase.execute(['dio'])).thenAnswer(
        (_) => Stream.fromIterable([
          Result.success(_makeAuditResult()),
        ]),
      );

      final runner = _makeRunner(usecase, presenter);
      await runner.run(['check', '--path', pubspecFile.path]);

      verify(() => presenter.showSummary(
            total: any(named: 'total'),
            failures: any(named: 'failures'),
            stopwatch: any(named: 'stopwatch'),
          )).called(1);
      verifyNever(() => presenter.showJsonOutput(any()));
    });
  });

  // -------------------------------------------------------------------------
  // Config hierarchy: CLI flag > config default > built-in default
  // -------------------------------------------------------------------------

  group('config hierarchy', () {
    test('config min-score is used as default when no CLI flag is given',
        () async {
      await pubspecFile.writeAsString(_pubspecWith(['pkg']));

      // Score 75 — would pass built-in default (70) but fail config default (80).
      when(() => usecase.execute(['pkg'])).thenAnswer(
        (_) => Stream.fromIterable([
          Result.success(_makeAuditResult(score: 75)),
        ]),
      );

      // Simulate config with min_score: 80.
      final runner = _makeRunner(usecase, presenter, defaultMinScore: 80);
      final exitCode = await runner.run(['check', '--path', pubspecFile.path]);

      expect(exitCode, 1);
    });

    test('CLI --min-score overrides config default', () async {
      await pubspecFile.writeAsString(_pubspecWith(['pkg']));

      // Score 75 — config default would fail (80) but CLI flag allows (60).
      when(() => usecase.execute(['pkg'])).thenAnswer(
        (_) => Stream.fromIterable([
          Result.success(_makeAuditResult(score: 75)),
        ]),
      );

      final runner = _makeRunner(usecase, presenter, defaultMinScore: 80);
      final exitCode = await runner
          .run(['check', '--path', pubspecFile.path, '--min-score', '60']);

      expect(exitCode, 0);
    });

    test('config fail-on-discontinued=false is used as default', () async {
      await pubspecFile.writeAsString(_pubspecWith(['old_pkg']));

      when(() => usecase.execute(['old_pkg'])).thenAnswer(
        (_) => Stream.fromIterable([
          Result.success(_makeAuditResult(
            name: 'old_pkg',
            isDiscontinued: true,
            score: 80,
          )),
        ]),
      );

      // Simulate config with fail_on_discontinued: false.
      final runner = _makeRunner(usecase, presenter,
          defaultFailOnDiscontinued: false, defaultMinScore: 0);
      final exitCode = await runner.run(['check', '--path', pubspecFile.path]);

      expect(exitCode, 0);
    });

    test('CLI --fail-on-discontinued overrides config false default', () async {
      await pubspecFile.writeAsString(_pubspecWith(['old_pkg']));

      when(() => usecase.execute(['old_pkg'])).thenAnswer(
        (_) => Stream.fromIterable([
          Result.success(_makeAuditResult(
            name: 'old_pkg',
            isDiscontinued: true,
            score: 80,
          )),
        ]),
      );

      // Config says false, CLI overrides to true.
      final runner = _makeRunner(usecase, presenter,
          defaultFailOnDiscontinued: false, defaultMinScore: 0);
      final exitCode = await runner.run([
        'check',
        '--path',
        pubspecFile.path,
        '--fail-on-discontinued',
      ]);

      expect(exitCode, 1);
    });
  });
}
