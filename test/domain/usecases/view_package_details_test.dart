import 'package:cura/src/domain/entities/aggregated_package_data.dart';
import 'package:cura/src/domain/entities/github_metrics.dart';
import 'package:cura/src/domain/entities/package_audit_result.dart';
import 'package:cura/src/domain/entities/package_info.dart';
import 'package:cura/src/domain/entities/score.dart';
import 'package:cura/src/domain/entities/vulnerability.dart';
import 'package:cura/src/domain/ports/package_data_aggregator.dart';
import 'package:cura/src/domain/usecases/calculate_score.dart';
import 'package:cura/src/domain/usecases/view_package_details.dart';
import 'package:cura/src/domain/value_objects/errors.dart';
import 'package:cura/src/domain/value_objects/grade.dart';
import 'package:cura/src/domain/value_objects/package_result.dart';
import 'package:cura/src/domain/value_objects/recommendation.dart';
import 'package:cura/src/domain/value_objects/result.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Mocks & Fakes
// ---------------------------------------------------------------------------

class MockPackageDataAggregator extends Mock implements PackageDataAggregator {}

class MockCalculateScore extends Mock implements CalculateScore {}

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

/// [vitality], [technicalHealth], [trust], [maintenance] correspond to the
/// dimension weights (40, 30, 20, 10). Defaults are healthy values above the
/// 50 % suggestion thresholds.
Score _makeScore({
  int total = 80,
  int vitality = 32,
  int technicalHealth = 24,
  int trust = 16,
  int maintenance = 8,
  List<Recommendation> recommendations = const [],
}) {
  return Score(
    total: total,
    vitality: vitality,
    technicalHealth: technicalHealth,
    trust: trust,
    maintenance: maintenance,
    grade: Grade.fromScore(total),
    breakdown: const ScoreBreakdown(
      vitalityDetails: '',
      technicalHealthDetails: '',
      trustDetails: '',
      maintenanceDetails: '',
    ),
    recommendations: recommendations,
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
    details: 'Details',
    severity: VulnerabilitySeverity.critical,
    published: DateTime(2024),
    affectedVersions: ['1.0.0'],
    references: [],
  );
}

// ---------------------------------------------------------------------------
// SUT factory
// ---------------------------------------------------------------------------

ViewPackageDetails _makeUsecase({
  required MockPackageDataAggregator aggregator,
  required MockCalculateScore calculator,
}) {
  return ViewPackageDetails(
    aggregator: aggregator,
    scoreCalculator: calculator,
  );
}

// ---------------------------------------------------------------------------
// Helper: stubs the aggregator + calculator for a single successful fetch.
// ---------------------------------------------------------------------------

void _stubSuccess({
  required MockPackageDataAggregator aggregator,
  required MockCalculateScore calculator,
  required AggregatedPackageData data,
  required Score score,
  bool fromCache = false,
}) {
  when(() => aggregator.fetchAll(any())).thenAnswer(
    (_) async => PackageResult.success(data: data, fromCache: fromCache),
  );
  when(() => calculator.execute(
        any(),
        githubMetrics: any(named: 'githubMetrics'),
        vulnerabilities: any(named: 'vulnerabilities'),
      )).thenReturn(score);
}

void main() {
  late MockPackageDataAggregator aggregator;
  late MockCalculateScore calculator;

  setUpAll(() {
    registerFallbackValue(FakePackageInfo());
    registerFallbackValue(FakeGitHubMetrics());
    registerFallbackValue(<Vulnerability>[]);
  });

  setUp(() {
    aggregator = MockPackageDataAggregator();
    calculator = MockCalculateScore();

    when(() => aggregator.dispose()).thenAnswer((_) async {});
  });

  // -------------------------------------------------------------------------
  // Happy path
  // -------------------------------------------------------------------------

  group('execute — success path', () {
    test('returns Success<PackageAuditResult> with correct fields', () async {
      final info = _makePackageInfo(name: 'dio', version: '5.4.0');
      final data = _makeAggregated(packageInfo: info);
      final score = _makeScore(total: 85);

      _stubSuccess(
        aggregator: aggregator,
        calculator: calculator,
        data: data,
        score: score,
        fromCache: false,
      );

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final result = await usecase.execute('dio');

      expect(result, isA<Success<PackageAuditResult>>());
      final audit = (result as Success<PackageAuditResult>).value;
      expect(audit.name, 'dio');
      expect(audit.version, '5.4.0');
      expect(audit.score.total, 85);
      expect(audit.fromCache, isFalse);
    });

    test('propagates fromCache flag from aggregator', () async {
      final data = _makeAggregated();

      when(() => aggregator.fetchAll(any())).thenAnswer(
        (_) async => PackageResult.success(data: data, fromCache: true),
      );
      when(() => calculator.execute(
            any(),
            githubMetrics: any(named: 'githubMetrics'),
            vulnerabilities: any(named: 'vulnerabilities'),
          )).thenReturn(_makeScore());

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final audit =
          ((await usecase.execute('test_pkg')) as Success<PackageAuditResult>)
              .value;

      expect(audit.fromCache, isTrue);
    });

    test('passes packageInfo to score calculator', () async {
      final info = _makePackageInfo(name: 'provider');
      final data = _makeAggregated(packageInfo: info);

      when(() => aggregator.fetchAll('provider')).thenAnswer(
        (_) async => PackageResult.success(data: data, fromCache: false),
      );
      when(() => calculator.execute(
            info,
            githubMetrics: any(named: 'githubMetrics'),
            vulnerabilities: any(named: 'vulnerabilities'),
          )).thenReturn(_makeScore(total: 90));

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final result = await usecase.execute('provider');

      expect(result.isSuccess, isTrue);
      verify(() => calculator.execute(
            info,
            githubMetrics: any(named: 'githubMetrics'),
            vulnerabilities: any(named: 'vulnerabilities'),
          )).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // Failure path
  // -------------------------------------------------------------------------

  group('execute — failure path', () {
    test('returns Failure when aggregator returns notFound', () async {
      when(() => aggregator.fetchAll('missing_pkg')).thenAnswer(
        (_) async => PackageResult.failure(
            const PackageProviderError.notFound('missing_pkg')),
      );

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final result = await usecase.execute('missing_pkg');

      expect(result, isA<Failure<PackageAuditResult>>());
      final error = (result as Failure<PackageAuditResult>).error;
      expect(error, isA<NotFoundError>());
      expect((error as NotFoundError).packageName, 'missing_pkg');
    });

    test('returns Failure on network error', () async {
      when(() => aggregator.fetchAll(any())).thenAnswer(
        (_) async => PackageResult.failure(
            const PackageProviderError.network('connection refused')),
      );

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final result = await usecase.execute('flaky_pkg');

      expect(result, isA<Failure<PackageAuditResult>>());
      expect(
          (result as Failure<PackageAuditResult>).error, isA<NetworkError>());
    });

    test('returns Failure on rate limit error', () async {
      when(() => aggregator.fetchAll(any())).thenAnswer(
        (_) async => PackageResult.failure(
            PackageProviderError.rateLimit(const Duration(seconds: 60))),
      );

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final result = await usecase.execute('any_pkg');

      expect(
          (result as Failure<PackageAuditResult>).error, isA<RateLimitError>());
    });
  });

  // -------------------------------------------------------------------------
  // Issue detection — discontinued
  // -------------------------------------------------------------------------

  group('_identifyIssues — discontinued', () {
    test('adds discontinued critical issue when package is discontinued',
        () async {
      final info = _makePackageInfo(isDiscontinued: true);
      _stubSuccess(
        aggregator: aggregator,
        calculator: calculator,
        data: _makeAggregated(packageInfo: info),
        score: _makeScore(),
      );

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final audit =
          ((await usecase.execute('test_pkg')) as Success<PackageAuditResult>)
              .value;

      expect(audit.issues.any((i) => i.type == AuditIssueType.discontinued),
          isTrue);
      expect(
        audit.issues
            .firstWhere((i) => i.type == AuditIssueType.discontinued)
            .severity,
        AuditIssueSeverity.critical,
      );
    });

    test('no discontinued issue when package is active', () async {
      _stubSuccess(
        aggregator: aggregator,
        calculator: calculator,
        data: _makeAggregated(),
        score: _makeScore(),
      );

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final audit =
          ((await usecase.execute('test_pkg')) as Success<PackageAuditResult>)
              .value;

      expect(audit.issues.any((i) => i.type == AuditIssueType.discontinued),
          isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Issue detection — critical vulnerabilities
  // -------------------------------------------------------------------------

  group('_identifyIssues — critical vulnerabilities', () {
    test('adds vulnerability critical issue and includes CVE id', () async {
      final vuln = _makeCriticalVuln(id: 'CVE-2024-9999');
      _stubSuccess(
        aggregator: aggregator,
        calculator: calculator,
        data: _makeAggregated(vulnerabilities: [vuln]),
        score: _makeScore(),
      );

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final audit =
          ((await usecase.execute('test_pkg')) as Success<PackageAuditResult>)
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
      _stubSuccess(
        aggregator: aggregator,
        calculator: calculator,
        data: _makeAggregated(vulnerabilities: [vuln]),
        score: _makeScore(total: 75),
      );

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final audit =
          ((await usecase.execute('test_pkg')) as Success<PackageAuditResult>)
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
      _stubSuccess(
        aggregator: aggregator,
        calculator: calculator,
        data: _makeAggregated(),
        score: _makeScore(total: 30),
      );

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final audit =
          ((await usecase.execute('test_pkg')) as Success<PackageAuditResult>)
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
      _stubSuccess(
        aggregator: aggregator,
        calculator: calculator,
        data: _makeAggregated(),
        score: _makeScore(total: 50),
      );

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final audit =
          ((await usecase.execute('test_pkg')) as Success<PackageAuditResult>)
              .value;

      expect(
          audit.issues.any((i) => i.type == AuditIssueType.lowScore), isFalse);
    });

    test('no lowScore issue when score.total > 50', () async {
      _stubSuccess(
        aggregator: aggregator,
        calculator: calculator,
        data: _makeAggregated(),
        score: _makeScore(total: 80),
      );

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final audit =
          ((await usecase.execute('test_pkg')) as Success<PackageAuditResult>)
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
      _stubSuccess(
        aggregator: aggregator,
        calculator: calculator,
        data: _makeAggregated(packageInfo: info),
        score: _makeScore(total: 75),
      );

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final audit =
          ((await usecase.execute('test_pkg')) as Success<PackageAuditResult>)
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
      _stubSuccess(
        aggregator: aggregator,
        calculator: calculator,
        data: _makeAggregated(
            packageInfo: _makePackageInfo(lastPublished: boundaryDate)),
        score: _makeScore(total: 75),
      );

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final audit =
          ((await usecase.execute('test_pkg')) as Success<PackageAuditResult>)
              .value;

      expect(audit.issues.any((i) => i.type == AuditIssueType.stale), isFalse);
    });

    test('no stale issue when package was recently published', () async {
      final recentDate = DateTime.now().subtract(const Duration(days: 30));
      _stubSuccess(
        aggregator: aggregator,
        calculator: calculator,
        data: _makeAggregated(
            packageInfo: _makePackageInfo(lastPublished: recentDate)),
        score: _makeScore(total: 90),
      );

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final audit =
          ((await usecase.execute('test_pkg')) as Success<PackageAuditResult>)
              .value;

      expect(audit.issues.any((i) => i.type == AuditIssueType.stale), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Issue detection — combined
  // -------------------------------------------------------------------------

  group('_identifyIssues — multiple issues combined', () {
    test('accumulates all 4 issue types for a severely degraded package',
        () async {
      final staleDate = DateTime.now().subtract(const Duration(days: 900));
      final info =
          _makePackageInfo(isDiscontinued: true, lastPublished: staleDate);
      final vuln = _makeCriticalVuln();

      _stubSuccess(
        aggregator: aggregator,
        calculator: calculator,
        data: _makeAggregated(packageInfo: info, vulnerabilities: [vuln]),
        score: _makeScore(total: 0),
      );

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final audit =
          ((await usecase.execute('test_pkg')) as Success<PackageAuditResult>)
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

    test('no issues for a healthy package', () async {
      _stubSuccess(
        aggregator: aggregator,
        calculator: calculator,
        data: _makeAggregated(),
        score: _makeScore(total: 90),
      );

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final audit =
          ((await usecase.execute('test_pkg')) as Success<PackageAuditResult>)
              .value;

      expect(audit.issues, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Suggestions — delegated to score.recommendations
  // -------------------------------------------------------------------------

  group('recommendations', () {
    test('is empty when score has no recommendations', () async {
      _stubSuccess(
        aggregator: aggregator,
        calculator: calculator,
        data: _makeAggregated(),
        score: _makeScore(recommendations: []),
      );

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final audit =
          ((await usecase.execute('test_pkg')) as Success<PackageAuditResult>)
              .value;

      expect(audit.recommendations, isEmpty);
    });

    test('propagates score.recommendations in order', () async {
      const recs = [
        Recommendation(
            level: RecommendationLevel.critical, message: 'AVOID this package'),
        Recommendation(
            level: RecommendationLevel.action,
            message: 'Search for an alternative'),
      ];

      _stubSuccess(
        aggregator: aggregator,
        calculator: calculator,
        data: _makeAggregated(),
        score: _makeScore(recommendations: recs),
      );

      final usecase =
          _makeUsecase(aggregator: aggregator, calculator: calculator);
      final audit =
          ((await usecase.execute('test_pkg')) as Success<PackageAuditResult>)
              .value;

      expect(audit.recommendations, recs);
    });
  });
}
