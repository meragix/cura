import 'package:args/command_runner.dart';
import 'package:cura/src/application/commands/view_command.dart';
import 'package:cura/src/domain/entities/package_audit_result.dart';
import 'package:cura/src/domain/entities/package_info.dart';
import 'package:cura/src/domain/entities/score.dart';
import 'package:cura/src/domain/entities/vulnerability.dart';
import 'package:cura/src/domain/usecases/view_package_details.dart';
import 'package:cura/src/domain/value_objects/errors.dart';
import 'package:cura/src/domain/value_objects/grade.dart';
import 'package:cura/src/domain/value_objects/result.dart';
import 'package:cura/src/presentation/presenters/view_presenter.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Mocks & Fakes
// ---------------------------------------------------------------------------

class MockViewPackageDetails extends Mock implements ViewPackageDetails {}

class MockViewPresenter extends Mock implements ViewPresenter {}

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
    vitality: 32,
    technicalHealth: 24,
    trust: 16,
    maintenance: 8,
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

// ---------------------------------------------------------------------------
// Runner factory
// ---------------------------------------------------------------------------

CommandRunner<int> _makeRunner(
  MockViewPackageDetails usecase,
  MockViewPresenter presenter,
) {
  final command = ViewCommand(
    viewUseCase: usecase,
    presenter: presenter,
  );
  return CommandRunner<int>('cura', 'test')..addCommand(command);
}

void main() {
  late MockViewPackageDetails usecase;
  late MockViewPresenter presenter;

  setUpAll(() {
    registerFallbackValue(FakeProgress());
    registerFallbackValue(FakePackageAuditResult());
    registerFallbackValue(const PackageProviderError.notFound('_fake_'));
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    usecase = MockViewPackageDetails();
    presenter = MockViewPresenter();

    // Stub all presenter side-effect methods (void returns).
    when(() => presenter.showProgressHeader(any())).thenReturn(FakeProgress());
    when(() => presenter.showPackageDetails(
          any(),
          verbose: any(named: 'verbose'),
          elapsed: any(named: 'elapsed'),
        )).thenReturn(null);
    when(() => presenter.showError(any())).thenReturn(null);
    when(() => presenter.showUsage(any())).thenReturn(null);
    when(() => presenter.showProviderError(any())).thenReturn(null);
  });

  // -------------------------------------------------------------------------
  // Argument validation
  // -------------------------------------------------------------------------

  group('argument validation', () {
    test('returns 1 and shows error when no package name is provided',
        () async {
      final runner = _makeRunner(usecase, presenter);
      final exitCode = await runner.run(['view']);

      expect(exitCode, 1);
      verify(() => presenter.showError(any())).called(1);
      verify(() => presenter.showUsage(any())).called(1);
    });

    test('uses only the first positional argument when multiple are given',
        () async {
      when(() => usecase.execute('dio')).thenAnswer(
        (_) async => Result.success(_makeAuditResult(name: 'dio')),
      );

      final runner = _makeRunner(usecase, presenter);
      await runner.run(['view', 'dio', 'extra_arg']);

      verify(() => usecase.execute('dio')).called(1);
      verifyNever(() => usecase.execute('extra_arg'));
    });
  });

  // -------------------------------------------------------------------------
  // Exit codes — success
  // -------------------------------------------------------------------------

  group('exit code — success', () {
    test('returns 0 when package data is retrieved successfully', () async {
      when(() => usecase.execute('dio')).thenAnswer(
        (_) async => Result.success(_makeAuditResult(name: 'dio')),
      );

      final runner = _makeRunner(usecase, presenter);
      final exitCode = await runner.run(['view', 'dio']);

      expect(exitCode, 0);
    });

    test('calls showPackageDetails with the audit result on success', () async {
      final audit = _makeAuditResult(name: 'provider');
      when(() => usecase.execute('provider')).thenAnswer(
        (_) async => Result.success(audit),
      );

      final runner = _makeRunner(usecase, presenter);
      await runner.run(['view', 'provider']);

      verify(() => presenter.showPackageDetails(
            audit,
            verbose: any(named: 'verbose'),
            elapsed: any(named: 'elapsed'),
          )).called(1);
    });

    test('passes verbose: false to showPackageDetails by default', () async {
      final audit = _makeAuditResult();
      when(() => usecase.execute(any())).thenAnswer(
        (_) async => Result.success(audit),
      );

      final runner = _makeRunner(usecase, presenter);
      await runner.run(['view', 'test_pkg']);

      final captured = verify(() => presenter.showPackageDetails(
            any(),
            verbose: captureAny(named: 'verbose'),
            elapsed: any(named: 'elapsed'),
          )).captured;
      expect(captured.first, false);
    });

    test('passes verbose: true when --verbose flag is set', () async {
      final audit = _makeAuditResult();
      when(() => usecase.execute(any())).thenAnswer(
        (_) async => Result.success(audit),
      );

      final runner = _makeRunner(usecase, presenter);
      await runner.run(['view', 'test_pkg', '--verbose']);

      final captured = verify(() => presenter.showPackageDetails(
            any(),
            verbose: captureAny(named: 'verbose'),
            elapsed: any(named: 'elapsed'),
          )).captured;
      expect(captured.first, true);
    });

    test('passes verbose: true when -v shorthand is set', () async {
      final audit = _makeAuditResult();
      when(() => usecase.execute(any())).thenAnswer(
        (_) async => Result.success(audit),
      );

      final runner = _makeRunner(usecase, presenter);
      await runner.run(['view', 'test_pkg', '-v']);

      final captured = verify(() => presenter.showPackageDetails(
            any(),
            verbose: captureAny(named: 'verbose'),
            elapsed: any(named: 'elapsed'),
          )).captured;
      expect(captured.first, true);
    });
  });

  // -------------------------------------------------------------------------
  // Exit codes — fetch failures
  // -------------------------------------------------------------------------

  group('exit code — fetch failures', () {
    test('returns 1 when package is not found', () async {
      when(() => usecase.execute('missing_pkg')).thenAnswer(
        (_) async => Result.failure(
            const PackageProviderError.notFound('missing_pkg')),
      );

      final runner = _makeRunner(usecase, presenter);
      final exitCode = await runner.run(['view', 'missing_pkg']);

      expect(exitCode, 1);
    });

    test('calls showProviderError on failure', () async {
      when(() => usecase.execute('missing_pkg')).thenAnswer(
        (_) async => Result.failure(
            const PackageProviderError.notFound('missing_pkg')),
      );

      final runner = _makeRunner(usecase, presenter);
      await runner.run(['view', 'missing_pkg']);

      verify(() => presenter.showProviderError(any())).called(1);
    });

    test('returns 1 on network error', () async {
      when(() => usecase.execute(any())).thenAnswer(
        (_) async => Result.failure(
            const PackageProviderError.network('timeout')),
      );

      final runner = _makeRunner(usecase, presenter);
      final exitCode = await runner.run(['view', 'flaky_pkg']);

      expect(exitCode, 1);
      verify(() => presenter.showProviderError(any())).called(1);
    });

    test('does not call showPackageDetails on failure', () async {
      when(() => usecase.execute(any())).thenAnswer(
        (_) async => Result.failure(
            const PackageProviderError.notFound('bad_pkg')),
      );

      final runner = _makeRunner(usecase, presenter);
      await runner.run(['view', 'bad_pkg']);

      verifyNever(() =>
          presenter.showPackageDetails(any(), verbose: any(named: 'verbose')));
    });
  });

  // -------------------------------------------------------------------------
  // Progress indicator
  // -------------------------------------------------------------------------

  group('progress indicator', () {
    test('shows progress header with the package name before fetching',
        () async {
      when(() => usecase.execute('dio')).thenAnswer(
        (_) async => Result.success(_makeAuditResult(name: 'dio')),
      );

      final runner = _makeRunner(usecase, presenter);
      await runner.run(['view', 'dio']);

      verify(() => presenter.showProgressHeader('dio')).called(1);
    });
  });
}
