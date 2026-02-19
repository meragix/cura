import 'package:cura/src/domain/ports/package_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockPackageProvider extends Mock implements PackageProvider {}

//class MockVulnerabilityProvider extends Mock implements VulnerabilityProvider {}

//class MockCalculateScore extends Mock implements CalculateScore {}

void main() {
  // late CheckPackages useCase;
  // late MockPackageProvider mockPackageProvider;
  // //late MockVulnerabilityProvider mockVulnProvider;
  // //late MockCalculateScore mockScoreCalculator;

  // setUp(() {
  //   mockPackageProvider = MockPackageProvider();
  //  // mockVulnProvider = MockVulnerabilityProvider();
  //  // mockScoreCalculator = MockCalculateScore();

  //   useCase = CheckPackages(
  //     packageProvider: mockPackageProvider,
  //    // vulnerabilityProvider: mockVulnProvider,
  //    // scoreCalculator: mockScoreCalculator,
  //   );
  // });

  // test('streams check results as packages complete', () async {
  //   // Given
  //   final dioInfo = PackageInfo(name: 'dio');
  //   final httpInfo = PackageInfo(name: 'http');

  //   when(() => mockPackageProvider.fetchPackages(['dio', 'http'])).thenAnswer((_) => Stream.fromIterable([
  //         PackageResult.success(data: dioInfo, fromCache: false),
  //         PackageResult.success(data: httpInfo, fromCache: true),
  //       ]));

  //   // Utilisation de Result<List<Vulnerability>> pour le type safety
  //   when(() => mockVulnProvider.getVulnerabilities(any())).thenAnswer((_) async => const Result.success([]));

  //   when(() => mockScoreCalculator.execute(any(), vulnerabilities: any(named: 'vulnerabilities')))
  //       .thenReturn(const Score(total: 85));

  //   // When
  //   final results = <String>[];

  //   await for (final result in useCase.execute(['dio', 'http'])) {
  //     switch (result) {
  //       case Success<PackageAuditResult>(:final value):
  //         results.add(value.name);
  //     }
  //   }

  //   // Then
  //   expect(results, orderedEquals(['dio', 'http']));
  //   verify(() => mockPackageProvider.fetchPackages(['dio', 'http'])).called(1);
  // });

  // test('streams check results as packages complete', () async {
  //   // Given
  //   when(() => mockPackageProvider.fetchPackages(['dio', 'http'])).thenAnswer((_) => Stream.fromIterable([
  //         Result.success(PackageInfo(name: 'dio')),
  //         Result.success(PackageInfo(name: 'http')),
  //       ]));

  //   when(() => mockVulnProvider.getVulnerabilities(any())).thenAnswer((_) async => Result.success([]));

  //   when(() => mockScoreCalculator.execute(any(), vulnerabilities: any(named: 'vulnerabilities')))
  //       .thenReturn(Score(total: 85));

  //   // When
  //   final results = <String>[];
  //   await for (final result in useCase.execute(['dio', 'http'])) {
  //     result.when(
  //       success: (audit) => results.add(audit.name),
  //       failure: (_) {},
  //     );
  //   }

  //   // Then
  //   expect(results, containsAll(['dio', 'http']));
  //   verify(() => mockPackageProvider.fetchPackages(['dio', 'http'])).called(1);
  // });
}
