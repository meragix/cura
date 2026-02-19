// lib/src/infrastructure/services/update_checker_service.dart

import 'package:cura/src/shared/app_info.dart';
import 'package:cura/src/shared/constants/api_constants.dart';
import 'package:cura/src/shared/utils/version_utils.dart';
import 'package:dio/dio.dart';

/// Service : Check for updates on pub.dev
class UpdateCheckerService {
  final Dio _httpClient;

  UpdateCheckerService({required Dio httpClient}) : _httpClient = httpClient;

  /// Check if update available
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final currentVersion = await AppInfo.getVersion();
      final latestVersion = await _fetchLatestVersion();

      if (VersionUtils.isNewer(latestVersion, currentVersion)) {
        return UpdateInfo(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          updateAvailable: true,
        );
      }

      return UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        updateAvailable: false,
      );
    } catch (e) {
      // Silent fail (no internet, API error)
      return null;
    }
  }

  /// Fetch latest version from pub.dev
  Future<String> _fetchLatestVersion() async {
    final response = await _httpClient.get(
      '${ApiConstants.pubDevApiUrl}/packages/cura',
      options: Options(receiveTimeout: Duration(seconds: 5)),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch latest version');
    }

    final data = response.data as Map<String, dynamic>;
    final latest = data['latest'] as Map<String, dynamic>;
    final version = latest['version'] as String;

    return version;
  }
}

/// Update information
class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final bool updateAvailable;

  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.updateAvailable,
  });
}
