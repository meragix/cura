import 'package:cura/src/infrastructure/services/update_checker_service.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late UpdateCheckerService service;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    service = UpdateCheckerService(httpClient: mockDio);
  });

  group('UpdateCheckerService', () {
    test('detects available update', () async {
      // Mock pub.dev API response
      when(() => mockDio.get(any(), options: any(named: 'options'))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: {
              'latest': {'version': '2.0.0'},
            },
          ));

      final updateInfo = await service.checkForUpdate();

      expect(updateInfo, isNotNull);
      expect(updateInfo!.updateAvailable, true);
      expect(updateInfo.latestVersion, '2.0.0');
    });

    test('handles no update available', () async {
      // Mock current version = latest version
      when(() => mockDio.get(any(), options: any(named: 'options'))).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: {
              'latest': {'version': '0.4.0'},
            },
          ));

      final updateInfo = await service.checkForUpdate();

      expect(updateInfo, isNotNull);
      expect(updateInfo!.updateAvailable, false);
    });

    test('handles API failure gracefully', () async {
      when(() => mockDio.get(any(), options: any(named: 'options'))).thenThrow(Exception('Network error'));

      final updateInfo = await service.checkForUpdate();

      expect(updateInfo, isNull);
    });
  });
}
