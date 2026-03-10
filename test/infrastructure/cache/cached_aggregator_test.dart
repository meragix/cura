import 'dart:io';

import 'package:cura/src/domain/entities/aggregated_package_data.dart';
import 'package:cura/src/domain/entities/package_info.dart';
import 'package:cura/src/domain/ports/package_data_aggregator.dart';
import 'package:cura/src/domain/value_objects/errors.dart';
import 'package:cura/src/domain/value_objects/package_result.dart';
import 'package:cura/src/infrastructure/aggregators/cached_aggregator.dart';
import 'package:cura/src/infrastructure/cache/json_file_system_cache.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockPackageDataAggregator extends Mock implements PackageDataAggregator {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

PackageInfo _makePackageInfo({String name = 'dio', int popularity = 80}) {
  return PackageInfo(
    name: name,
    version: '5.0.0',
    description: 'A test package',
    lastPublished: DateTime(2024, 1, 1),
    panaScore: 100,
    likes: 500,
    popularity: popularity,
    grantedPoints: 130,
    maxPoints: 140,
    isNullSafe: true,
    isDart3Compatible: true,
    isDiscontinued: false,
    isFlutterFavorite: false,
    isNew: false,
    isWasmReady: false,
    supportedPlatforms: ['dart'],
  );
}

AggregatedPackageData _makeAggregated(
    {String name = 'dio', int popularity = 80}) {
  return AggregatedPackageData(
    packageInfo: _makePackageInfo(name: name, popularity: popularity),
    githubMetrics: null,
    vulnerabilities: [],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late Directory tempDir;
  late JsonFileSystemCache fileCache;
  late MockPackageDataAggregator mockDelegate;
  late CachedAggregator aggregator;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cura_agg_test_');
    fileCache = JsonFileSystemCache(cacheDir: tempDir.path);
    await fileCache.initialize();

    mockDelegate = MockPackageDataAggregator();
    aggregator = CachedAggregator(
      delegate: mockDelegate,
      cache: fileCache,
    );

    registerFallbackValue(
      PackageResult.success(data: _makeAggregated(), fromCache: false),
    );
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  // ---------------------------------------------------------------------------
  // fetchAll — cache miss path
  // ---------------------------------------------------------------------------
  group('fetchAll — cache miss', () {
    test('delegates to underlying aggregator on miss', () async {
      final data = _makeAggregated();
      when(() => mockDelegate.fetchAll('dio')).thenAnswer(
        (_) async => PackageResult.success(
            data: data, fromCache: false, requestCount: 3),
      );

      final result = await aggregator.fetchAll('dio');

      expect(result, isA<PackageSuccess>());
      final success = result as PackageSuccess;
      expect(success.fromCache, isFalse);
      expect(success.requestCount, 3);
      verify(() => mockDelegate.fetchAll('dio')).called(1);
    });

    test('persists successful result to cache', () async {
      final data = _makeAggregated();
      when(() => mockDelegate.fetchAll('dio')).thenAnswer(
        (_) async => PackageResult.success(data: data, fromCache: false),
      );

      await aggregator.fetchAll('dio'); // miss → populates cache
      final result2 =
          await aggregator.fetchAll('dio'); // hit → no delegate call

      // Delegate called exactly once (first request only)
      verify(() => mockDelegate.fetchAll('dio')).called(1);
      expect((result2 as PackageSuccess).fromCache, isTrue);
    });

    test('does not cache failure results', () async {
      when(() => mockDelegate.fetchAll('bad_pkg')).thenAnswer(
        (_) async => PackageResult.failure(
          PackageProviderError.notFound('bad_pkg'),
        ),
      );

      await aggregator.fetchAll('bad_pkg');
      await aggregator.fetchAll('bad_pkg');

      // Both calls must reach the delegate (nothing cached)
      verify(() => mockDelegate.fetchAll('bad_pkg')).called(2);
    });
  });

  // ---------------------------------------------------------------------------
  // fetchAll — cache hit path
  // ---------------------------------------------------------------------------
  group('fetchAll — cache hit', () {
    test('returns fromCache=true on second call', () async {
      final data = _makeAggregated();
      when(() => mockDelegate.fetchAll('dio')).thenAnswer(
        (_) async => PackageResult.success(data: data, fromCache: false),
      );

      await aggregator.fetchAll('dio'); // populates cache
      final result = await aggregator.fetchAll('dio');

      final success = result as PackageSuccess;
      expect(success.fromCache, isTrue);
      expect(success.cachedAt, isA<DateTime>());
    });

    test('returns requestCount=0 on cache hit', () async {
      final data = _makeAggregated();
      when(() => mockDelegate.fetchAll('dio')).thenAnswer(
        (_) async => PackageResult.success(
            data: data, fromCache: false, requestCount: 4),
      );

      await aggregator.fetchAll('dio');
      final cached = await aggregator.fetchAll('dio');

      expect((cached as PackageSuccess).requestCount, 0);
    });

    test('data fields survive serialization round-trip', () async {
      final data = _makeAggregated(name: 'provider', popularity: 95);
      when(() => mockDelegate.fetchAll('provider')).thenAnswer(
        (_) async => PackageResult.success(data: data, fromCache: false),
      );

      await aggregator.fetchAll('provider');
      final cached = await aggregator.fetchAll('provider');

      final success = cached as PackageSuccess;
      expect(success.data.packageInfo.name, 'provider');
      expect(success.data.packageInfo.popularity, 95);
      expect(success.data.vulnerabilities, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // cacheMaxAgeHours
  // ---------------------------------------------------------------------------
  group('cacheMaxAgeHours', () {
    test('uses configured cacheMaxAgeHours as defaultTtl for 70-89 popularity',
        () async {
      // Use a very short TTL so we can verify it has expired
      final shortTtlAggregator = CachedAggregator(
        delegate: mockDelegate,
        cache: fileCache,
        cacheMaxAgeHours: 0, // expires immediately for popularity 70-89
      );

      final data = _makeAggregated(name: 'pkg_ttl', popularity: 75);
      when(() => mockDelegate.fetchAll('pkg_ttl')).thenAnswer(
        (_) async => PackageResult.success(data: data, fromCache: false),
      );

      await shortTtlAggregator.fetchAll('pkg_ttl');

      // Entry should be expired (TTL=0h → expiresAt = now, already past)
      // A second call must hit the delegate again
      await shortTtlAggregator.fetchAll('pkg_ttl');
      verify(() => mockDelegate.fetchAll('pkg_ttl')).called(2);
    });
  });

  // ---------------------------------------------------------------------------
  // fetchMany
  // ---------------------------------------------------------------------------
  group('fetchMany', () {
    test('emits results in input order', () async {
      for (final name in ['pkg_a', 'pkg_b', 'pkg_c']) {
        when(() => mockDelegate.fetchAll(name)).thenAnswer(
          (_) async => PackageResult.success(
            data: _makeAggregated(name: name),
            fromCache: false,
          ),
        );
      }

      final results =
          await aggregator.fetchMany(['pkg_a', 'pkg_b', 'pkg_c']).toList();

      expect(results.length, 3);
      final names = results
          .whereType<PackageSuccess>()
          .map((r) => r.data.packageInfo.name)
          .toList();
      expect(names, ['pkg_a', 'pkg_b', 'pkg_c']);
    });
  });

  // ---------------------------------------------------------------------------
  // dispose
  // ---------------------------------------------------------------------------
  group('dispose', () {
    test('forwards dispose to delegate', () async {
      when(() => mockDelegate.dispose()).thenAnswer((_) async {});
      await aggregator.dispose();
      verify(() => mockDelegate.dispose()).called(1);
    });
  });
}
