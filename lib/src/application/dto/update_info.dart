/// Result of an update check against pub.dev.
///
/// Returned by [UpdateCheckerService.checkForUpdate]. A `null` result means
/// the check could not be completed (network error, API unavailable, etc.) and
/// should be silently ignored by callers.
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
