import 'package:cura/src/application/dto/update_info.dart';
import 'package:cura/src/shared/app_info.dart';
import 'package:cura/src/shared/constants/api_constants.dart';
import 'package:cura/src/shared/utils/version_utils.dart';
import 'package:dio/dio.dart';

/// Checks pub.dev for a newer release of Cura.
///
/// All failures (network errors, non-200 responses, parse errors) are silently
/// swallowed and surface as `null` so the caller is never interrupted by an
/// update check that can't complete.
class UpdateCheckerService {
  final Dio _httpClient;

  UpdateCheckerService({required Dio httpClient}) : _httpClient = httpClient;

  /// Compares [currentVersion] against the latest release on pub.dev.
  ///
  /// Returns an [UpdateInfo] describing both versions and whether an upgrade
  /// is available. Returns `null` if the check fails for any reason.
  Future<UpdateInfo?> checkForUpdate(String currentVersion) async {
    try {
      final latestVersion = await _fetchLatestVersion();

      return UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        updateAvailable: VersionUtils.isNewer(latestVersion, currentVersion),
      );
    } catch (_) {
      return null;
    }
  }

  /// Fetches the latest published version from the pub.dev API.
  ///
  /// Uses [AppInfo.name] so the package name is never duplicated in source.
  Future<String> _fetchLatestVersion() async {
    final packageName = AppInfo.name.toLowerCase();
    final response = await _httpClient.get(
      '${ApiConstants.pubDevApiUrl}/packages/$packageName',
      options: Options(receiveTimeout: const Duration(seconds: 5)),
    );

    if (response.statusCode != 200) {
      throw Exception('pub.dev returned ${response.statusCode}');
    }

    final data = response.data as Map<String, dynamic>;
    return (data['latest'] as Map<String, dynamic>)['version'] as String;
  }
}
