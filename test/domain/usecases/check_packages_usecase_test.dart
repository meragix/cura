import 'package:cura/src/domain/entities/aggregated_package_data.dart';
import 'package:cura/src/domain/entities/github_metrics.dart';
import 'package:cura/src/domain/entities/package_audit_result.dart';
import 'package:cura/src/domain/entities/package_info.dart';
import 'package:cura/src/domain/entities/score.dart';
import 'package:cura/src/domain/entities/vulnerability.dart';
import 'package:cura/src/domain/ports/package_data_aggregator.dart';
import 'package:cura/src/domain/ports/score_calculator.dart';
import 'package:cura/src/domain/usecases/check_packages_usecase.dart';
import 'package:cura/src/domain/value_objects/errors.dart';
import 'package:cura/src/domain/value_objects/grade.dart';
import 'package:cura/src/domain/value_objects/package_result.dart';
import 'package:cura/src/domain/value_objects/result.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Mocks & Fakes
// ---------------------------------------------------------------------------

class MockPackageDataAggregator extends Mock implements PackageDataAggregator {}

class MockScoreCalculator extends Mock implements ScoreCalculator {}

class FakePackageInfo extends Fake implements PackageInfo {}

class FakeGitHubMetrics extends Fake implements GitHubMetrics {}

class FakeVulnerability extends Fake implements Vulnerability {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

PackageInfo _makePackageInfo({
  String name = 'test_pkg',
  String version = '1.0.0',
  bool isDiscontinued = false,
  DateTime? lastPublished,
}) {
  return PackageInfo(
    name: name,
    version: version,
    description: 'A test package',
    lastPublished: lastPublished ?? DateTime.now(),
    panaScore: 100,
    likes: 200,
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
    vitality: total ~/ 2,
    technicalHealth: total ~/ 4,
    trust: total ~/ 8,
    maintenance: total ~/ 8,
    grade: Grade.fromScore(total),
    breakdown: const ScoreBreakdown(
      vitalityDetails: '',
      technicalHealthDetails: '',
      trustDetails: '',
      maintenanceDetails: '',
    ),
  );
}

AggregatedPackageData _makeAggregated({
  PackageInfo? packageInfo,
  List<Vulnerability> vulnerabilities = const [],
  GitHubMetrics? githubMetrics,
}) {
  return AggregatedPackageData(
    packageInfo: packageInfo ?? _makePackageInfo(),
    githubMetrics: githubMetrics,
    vulnerabilities: vulnerabilities,
  );
}

Vulnerability _makeCriticalVuln({String id = 'CVE-2024-0001'}) {
  return Vulnerability(
    id: id,
    summary: 'Critical issue',
    details: 'Details about the vulnerability',
    severity: VulnerabilitySeverity.critical,
    published: DateTime(2024),
    affectedVersions: ['1.0.0'],
    references: [],
  );
}

// ---------------------------------------------------------------------------
// SUT factory
// ---------------------------------------------------------------------------

CheckPackagesUsecase _makeUsecase({
  required MockPackageDataAggregator aggregator,
  required MockScoreCalculator calculator,
}) {
  return CheckPackagesUsecase(
    aggregator: aggregator,
    scoreCalculator: calculator,
  );
}

void main() {
  late MockPackageDataAggregator aggregator;
  late MockScoreCalculator calculator;

  setUpAll(() {
    registerFallbackValue(FakePackageInfo());
    registerFallbackValue(FakeGitHubMetrics());
    registerFallbackValue(<Vulnerability>[]);
  });

  setUp(() {
    aggregator = MockPackageDataAggregator();
    calculator = MockScoreCalculator();

    // dispose() is always called in cleanup — stub it globally.
    when(() => aggregator.dispose()).thenAnswer((_) async {});
  });

  // -------------------------------------------------------------------------
  // Happy path
  // -------------------------------------------------------------------------

  group('execute — success path', () {
    test('emits one Success<PackageAuditResult> per package', () async {
      final info = _makePackageInfo(name: 'dio', version: '5.4.0');
      final aggregated = _makeAggregated(packageInfo: info);
      final score = _makeScore(total: 85);

      when(() => aggregator.fetchMany(['dio'])).thenAnswer(
        (_) => Stream.fromIterable([
          PackageResult.success(
              data: aggregated, fromCache: false, requestCount: 3),
        ]),
      );
      when(() => calculator.execute(
            info,
            githubMetrics: any(named: 'githubMetrics'),
            vulnerabilities: any(named: 'vulnerabilities'),
          )).thenReturn(score);

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final results = await usecase.execute(['dio']).toList();

      expect(results, hasLength(1));
      expect(results.first, isA<Success<PackageAuditResult>>());

      final audit = (results.first as Success<PackageAuditResult>).value;
      expect(audit.name, 'dio');
      expect(audit.version, '5.4.0');
      expect(audit.score.total, 85);
      expect(audit.fromCache, isFalse);
      expect(audit.requestCount, 3);
    });

    test('emits results for each package in a multi-package list', () async {
      when(() => aggregator.fetchMany(['dio', 'provider', 'riverpod']))
          .thenAnswer((_) => Stream.fromIterable([
                PackageResult.success(
                  data: _makeAggregated(
                      packageInfo: _makePackageInfo(name: 'dio')),
                  fromCache: true,
                ),
                PackageResult.success(
                  data: _makeAggregated(
                      packageInfo: _makePackageInfo(name: 'provider')),
                  fromCache: false,
                  requestCount: 2,
                ),
                PackageResult.success(
                  data: _makeAggregated(
                      packageInfo: _makePackageInfo(name: 'riverpod')),
                  fromCache: true,
                ),
              ]));

      when(() => calculator.execute(
            any(),
            githubMetrics: any(named: 'githubMetrics'),
            vulnerabilities: any(named: 'vulnerabilities'),
          )).thenReturn(_makeScore());

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final results =
          await usecase.execute(['dio', 'provider', 'riverpod']).toList();

      expect(results, hasLength(3));
      expect(results.every((r) => r.isSuccess), isTrue);
    });

    test('propagates fromCache and requestCount from aggregator', () async {
      final info = _makePackageInfo();
      final aggregated = _makeAggregated(packageInfo: info);

      when(() => aggregator.fetchMany(any())).thenAnswer(
        (_) => Stream.fromIterable([
          PackageResult.success(
              data: aggregated, fromCache: true, requestCount: 0),
        ]),
      );
      when(() => calculator.execute(
            any(),
            githubMetrics: any(named: 'githubMetrics'),
            vulnerabilities: any(named: 'vulnerabilities'),
          )).thenReturn(_makeScore());

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final results = await usecase.execute(['test_pkg']).toList();
      final audit = (results.first as Success<PackageAuditResult>).value;

      expect(audit.fromCache, isTrue);
      expect(audit.requestCount, 0);
    });

    test('empty package list produces empty stream', () async {
      when(() => aggregator.fetchMany([]))
          .thenAnswer((_) => const Stream.empty());

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final results = await usecase.execute([]).toList();

      expect(results, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Failure path
  // -------------------------------------------------------------------------

  group('execute — failure path', () {
    test('emits Failure when aggregator returns notFound', () async {
      when(() => aggregator.fetchMany(['missing_pkg'])).thenAnswer(
        (_) => Stream.fromIterable([
          PackageResult.failure(
              const PackageProviderError.notFound('missing_pkg')),
        ]),
      );

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final results = await usecase.execute(['missing_pkg']).toList();

      expect(results, hasLength(1));
      expect(results.first, isA<Failure<PackageAuditResult>>());

      final error = (results.first as Failure<PackageAuditResult>).error;
      expect(error, isA<NotFoundError>());
      expect((error as NotFoundError).packageName, 'missing_pkg');
    });

    test('emits Failure when aggregator returns network error', () async {
      when(() => aggregator.fetchMany(any())).thenAnswer(
        (_) => Stream.fromIterable([
          PackageResult.failure(
              const PackageProviderError.network('connection refused')),
        ]),
      );

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final results = await usecase.execute(['flaky_pkg']).toList();

      expect(results.first, isA<Failure<PackageAuditResult>>());
      expect((results.first as Failure<PackageAuditResult>).error,
          isA<NetworkError>());
    });

    test('emits Failure when aggregator returns rate limit error', () async {
      when(() => aggregator.fetchMany(any())).thenAnswer(
        (_) => Stream.fromIterable([
          PackageResult.failure(
            PackageProviderError.rateLimit(const Duration(seconds: 60)),
          ),
        ]),
      );

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final results = await usecase.execute(['any_pkg']).toList();

      expect((results.first as Failure<PackageAuditResult>).error,
          isA<RateLimitError>());
    });

    test('continues processing remaining packages after a single failure',
        () async {
      final goodInfo = _makePackageInfo(name: 'good_pkg');
      final goodData = _makeAggregated(packageInfo: goodInfo);

      when(() => aggregator.fetchMany(['bad_pkg', 'good_pkg'])).thenAnswer(
        (_) => Stream.fromIterable([
          PackageResult.failure(const PackageProviderError.notFound('bad_pkg')),
          PackageResult.success(data: goodData, fromCache: false),
        ]),
      );
      when(() => calculator.execute(
            goodInfo,
            githubMetrics: any(named: 'githubMetrics'),
            vulnerabilities: any(named: 'vulnerabilities'),
          )).thenReturn(_makeScore());

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final results = await usecase.execute(['bad_pkg', 'good_pkg']).toList();

      expect(results, hasLength(2));
      expect(results[0], isA<Failure<PackageAuditResult>>());
      expect(results[1], isA<Success<PackageAuditResult>>());
    });
  });

  // -------------------------------------------------------------------------
  // Issue detection — discontinued
  // -------------------------------------------------------------------------

  group('_identifyIssues — discontinued', () {
    test('adds discontinued critical issue when package is discontinued',
        () async {
      final info = _makePackageInfo(isDiscontinued: true);
      final aggregated = _makeAggregated(packageInfo: info);

      when(() => aggregator.fetchMany(any())).thenAnswer(
        (_) => Stream.fromIterable([
          PackageResult.success(data: aggregated, fromCache: false),
        ]),
      );
      when(() => calculator.execute(
            any(),
            githubMetrics: any(named: 'githubMetrics'),
            vulnerabilities: any(named: 'vulnerabilities'),
          )).thenReturn(_makeScore());

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final audit = (await usecase.execute(['test_pkg']).toList()).first
          as Success<PackageAuditResult>;

      expect(
          audit.value.issues.any((i) => i.type == AuditIssueType.discontinued),
          isTrue);
      expect(
        audit.value.issues
            .firstWhere((i) => i.type == AuditIssueType.discontinued)
            .severity,
        AuditIssueSeverity.critical,
      );
    });

    test('no discontinued issue when package is active', () async {
      final aggregated = _makeAggregated(packageInfo: _makePackageInfo());

      when(() => aggregator.fetchMany(any())).thenAnswer(
        (_) => Stream.fromIterable([
          PackageResult.success(data: aggregated, fromCache: false),
        ]),
      );
      when(() => calculator.execute(
            any(),
            githubMetrics: any(named: 'githubMetrics'),
            vulnerabilities: any(named: 'vulnerabilities'),
          )).thenReturn(_makeScore());

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final audit = ((await usecase.execute(['test_pkg']).toList()).first
              as Success<PackageAuditResult>)
          .value;

      expect(audit.issues.any((i) => i.type == AuditIssueType.discontinued),
          isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Issue detection — critical vulnerabilities
  // -------------------------------------------------------------------------

  group('_identifyIssues — critical vulnerabilities', () {
    test('adds vulnerability critical issue and includes CVE id in message',
        () async {
      final vuln = _makeCriticalVuln(id: 'CVE-2024-9999');
      final aggregated = _makeAggregated(vulnerabilities: [vuln]);

      when(() => aggregator.fetchMany(any())).thenAnswer(
        (_) => Stream.fromIterable([
          PackageResult.success(data: aggregated, fromCache: false),
        ]),
      );
      when(() => calculator.execute(
            any(),
            githubMetrics: any(named: 'githubMetrics'),
            vulnerabilities: any(named: 'vulnerabilities'),
          )).thenReturn(_makeScore());

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final audit = ((await usecase.execute(['test_pkg']).toList()).first
              as Success<PackageAuditResult>)
          .value;

      expect(audit.issues.any((i) => i.type == AuditIssueType.vulnerability),
          isTrue);
      final issue = audit.issues
          .firstWhere((i) => i.type == AuditIssueType.vulnerability);
      expect(issue.severity, AuditIssueSeverity.critical);
      expect(issue.message, contains('CVE-2024-9999'));
    });

    test('no vulnerability issue when only non-critical CVEs present',
        () async {
      final vuln = Vulnerability(
        id: 'CVE-2024-LOW',
        summary: 'Low severity',
        details: '',
        severity: VulnerabilitySeverity.low,
        published: DateTime(2024),
        affectedVersions: ['1.0.0'],
        references: [],
      );
      final aggregated = _makeAggregated(vulnerabilities: [vuln]);

      when(() => aggregator.fetchMany(any())).thenAnswer(
        (_) => Stream.fromIterable([
          PackageResult.success(data: aggregated, fromCache: false),
        ]),
      );
      when(() => calculator.execute(
            any(),
            githubMetrics: any(named: 'githubMetrics'),
            vulnerabilities: any(named: 'vulnerabilities'),
          )).thenReturn(_makeScore(total: 75));

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final audit = ((await usecase.execute(['test_pkg']).toList()).first
              as Success<PackageAuditResult>)
          .value;

      expect(audit.issues.any((i) => i.type == AuditIssueType.vulnerability),
          isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Issue detection — low score
  // -------------------------------------------------------------------------

  group('_identifyIssues — low score', () {
    test('adds lowScore warning issue when score.total < 50', () async {
      final aggregated = _makeAggregated();

      when(() => aggregator.fetchMany(any())).thenAnswer(
        (_) => Stream.fromIterable([
          PackageResult.success(data: aggregated, fromCache: false),
        ]),
      );
      when(() => calculator.execute(
            any(),
            githubMetrics: any(named: 'githubMetrics'),
            vulnerabilities: any(named: 'vulnerabilities'),
          )).thenReturn(_makeScore(total: 30));

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final audit = ((await usecase.execute(['test_pkg']).toList()).first
              as Success<PackageAuditResult>)
          .value;

      expect(
          audit.issues.any((i) => i.type == AuditIssueType.lowScore), isTrue);
      expect(
        audit.issues
            .firstWhere((i) => i.type == AuditIssueType.lowScore)
            .severity,
        AuditIssueSeverity.warning,
      );
    });

    test('no lowScore issue when score.total == 50 (boundary)', () async {
      final aggregated = _makeAggregated();

      when(() => aggregator.fetchMany(any())).thenAnswer(
        (_) => Stream.fromIterable([
          PackageResult.success(data: aggregated, fromCache: false),
        ]),
      );
      when(() => calculator.execute(
            any(),
            githubMetrics: any(named: 'githubMetrics'),
            vulnerabilities: any(named: 'vulnerabilities'),
          )).thenReturn(_makeScore(total: 50));

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final audit = ((await usecase.execute(['test_pkg']).toList()).first
              as Success<PackageAuditResult>)
          .value;

      expect(
          audit.issues.any((i) => i.type == AuditIssueType.lowScore), isFalse);
    });

    test('no lowScore issue when score.total > 50', () async {
      final aggregated = _makeAggregated();

      when(() => aggregator.fetchMany(any())).thenAnswer(
        (_) => Stream.fromIterable([
          PackageResult.success(data: aggregated, fromCache: false),
        ]),
      );
      when(() => calculator.execute(
            any(),
            githubMetrics: any(named: 'githubMetrics'),
            vulnerabilities: any(named: 'vulnerabilities'),
          )).thenReturn(_makeScore(total: 80));

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final audit = ((await usecase.execute(['test_pkg']).toList()).first
              as Success<PackageAuditResult>)
          .value;

      expect(
          audit.issues.any((i) => i.type == AuditIssueType.lowScore), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Issue detection — stale
  // -------------------------------------------------------------------------

  group('_identifyIssues — stale', () {
    test('adds stale warning issue when lastPublished > 730 days ago',
        () async {
      final staleDate = DateTime.now().subtract(const Duration(days: 800));
      final info = _makePackageInfo(lastPublished: staleDate);
      final aggregated = _makeAggregated(packageInfo: info);

      when(() => aggregator.fetchMany(any())).thenAnswer(
        (_) => Stream.fromIterable([
          PackageResult.success(data: aggregated, fromCache: false),
        ]),
      );
      when(() => calculator.execute(
            any(),
            githubMetrics: any(named: 'githubMetrics'),
            vulnerabilities: any(named: 'vulnerabilities'),
          )).thenReturn(_makeScore(total: 75));

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final audit = ((await usecase.execute(['test_pkg']).toList()).first
              as Success<PackageAuditResult>)
          .value;

      expect(audit.issues.any((i) => i.type == AuditIssueType.stale), isTrue);
      final staleIssue =
          audit.issues.firstWhere((i) => i.type == AuditIssueType.stale);
      expect(staleIssue.severity, AuditIssueSeverity.warning);
      expect(staleIssue.message, contains('800'));
    });

    test('no stale issue when lastPublished is exactly 730 days ago (boundary)',
        () async {
      final boundaryDate = DateTime.now().subtract(const Duration(days: 730));
      final info = _makePackageInfo(lastPublished: boundaryDate);
      final aggregated = _makeAggregated(packageInfo: info);

      when(() => aggregator.fetchMany(any())).thenAnswer(
        (_) => Stream.fromIterable([
          PackageResult.success(data: aggregated, fromCache: false),
        ]),
      );
      when(() => calculator.execute(
            any(),
            githubMetrics: any(named: 'githubMetrics'),
            vulnerabilities: any(named: 'vulnerabilities'),
          )).thenReturn(_makeScore(total: 75));

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final audit = ((await usecase.execute(['test_pkg']).toList()).first
              as Success<PackageAuditResult>)
          .value;

      expect(audit.issues.any((i) => i.type == AuditIssueType.stale), isFalse);
    });

    test('no stale issue when package was recently published', () async {
      final recentDate = DateTime.now().subtract(const Duration(days: 30));
      final info = _makePackageInfo(lastPublished: recentDate);
      final aggregated = _makeAggregated(packageInfo: info);

      when(() => aggregator.fetchMany(any())).thenAnswer(
        (_) => Stream.fromIterable([
          PackageResult.success(data: aggregated, fromCache: false),
        ]),
      );
      when(() => calculator.execute(
            any(),
            githubMetrics: any(named: 'githubMetrics'),
            vulnerabilities: any(named: 'vulnerabilities'),
          )).thenReturn(_makeScore(total: 90));

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final audit = ((await usecase.execute(['test_pkg']).toList()).first
              as Success<PackageAuditResult>)
          .value;

      expect(audit.issues.any((i) => i.type == AuditIssueType.stale), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Combined issues
  // -------------------------------------------------------------------------

  group('_identifyIssues — multiple issues combined', () {
    test('accumulates all 4 issue types for a severely degraded package',
        () async {
      final staleDate = DateTime.now().subtract(const Duration(days: 900));
      final info =
          _makePackageInfo(isDiscontinued: true, lastPublished: staleDate);
      final vuln = _makeCriticalVuln();
      final aggregated =
          _makeAggregated(packageInfo: info, vulnerabilities: [vuln]);

      when(() => aggregator.fetchMany(any())).thenAnswer(
        (_) => Stream.fromIterable([
          PackageResult.success(data: aggregated, fromCache: false),
        ]),
      );
      when(() => calculator.execute(
            any(),
            githubMetrics: any(named: 'githubMetrics'),
            vulnerabilities: any(named: 'vulnerabilities'),
          )).thenReturn(_makeScore(total: 0));

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final audit = ((await usecase.execute(['test_pkg']).toList()).first
              as Success<PackageAuditResult>)
          .value;

      final types = audit.issues.map((i) => i.type).toSet();
      expect(
        types,
        containsAll([
          AuditIssueType.discontinued,
          AuditIssueType.vulnerability,
          AuditIssueType.lowScore,
          AuditIssueType.stale,
        ]),
      );
    });
  });
}
