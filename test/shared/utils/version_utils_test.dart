import 'package:cura/src/shared/utils/version_utils.dart';
import 'package:test/test.dart';

void main() {
  group('VersionUtils', () {
    group('compare', () {
      test('compares major versions correctly', () {
        expect(VersionUtils.compare('2.0.0', '1.0.0'), 1);
        expect(VersionUtils.compare('1.0.0', '2.0.0'), -1);
      });

      test('compares minor versions correctly', () {
        expect(VersionUtils.compare('1.2.0', '1.1.0'), 1);
        expect(VersionUtils.compare('1.1.0', '1.2.0'), -1);
      });

      test('compares patch versions correctly', () {
        expect(VersionUtils.compare('1.0.2', '1.0.1'), 1);
        expect(VersionUtils.compare('1.0.1', '1.0.2'), -1);
      });

      test('returns 0 for equal versions', () {
        expect(VersionUtils.compare('1.2.3', '1.2.3'), 0);
      });

      test('handles versions with v prefix', () {
        expect(VersionUtils.compare('v1.2.3', '1.2.3'), 0);
      });

      test('pre-release is less than stable for same base version', () {
        // Semver spec: 1.0.0-beta < 1.0.0
        expect(VersionUtils.compare('1.0.0-beta', '1.0.0'), -1);
        expect(VersionUtils.compare('1.0.0', '1.0.0-beta'), 1);
      });

      test('two pre-release versions with same base are equal', () {
        expect(VersionUtils.compare('1.0.0-beta', '1.0.0-rc'), 0);
      });

      test('pre-release does not affect major/minor/patch ordering', () {
        // 1.1.0-beta is still newer than 1.0.0 stable
        expect(VersionUtils.compare('1.1.0-beta', '1.0.0'), 1);
        expect(VersionUtils.compare('1.0.0', '1.1.0-beta'), -1);
      });
    });

    group('isNewer', () {
      test('returns true when v1 is newer', () {
        expect(VersionUtils.isNewer('1.2.0', '1.1.0'), true);
      });

      test('returns false when v1 is older', () {
        expect(VersionUtils.isNewer('1.0.0', '1.1.0'), false);
      });

      test('returns false when versions are equal', () {
        expect(VersionUtils.isNewer('1.0.0', '1.0.0'), false);
      });

      test('stable is newer than pre-release of same base', () {
        expect(VersionUtils.isNewer('1.0.0', '1.0.0-beta'), true);
      });

      test('pre-release is not newer than stable of same base', () {
        expect(VersionUtils.isNewer('1.0.0-beta', '1.0.0'), false);
      });
    });
  });
}
