import 'package:cura/src/application/dto/update_info.dart';

/// Port: contract for checking whether a newer version of Cura is available.
///
/// Implementations query an external registry (e.g. pub.dev) and compare the
/// published version against the [currentVersion] supplied by the caller.
///
/// ### Failure contract
/// All implementations must return `null` on any failure (network error, API
/// unavailable, parse error) rather than throwing. An update check that cannot
/// complete must never interrupt the main CLI flow.
///
/// ### Known implementations
/// - `UpdateCheckerService` — queries the pub.dev packages API.
abstract class UpdateChecker {
  /// Compares [currentVersion] against the latest published release.
  ///
  /// Returns an [UpdateInfo] when the check succeeds, or `null` when it fails
  /// for any reason (network, API, parse).
  Future<UpdateInfo?> checkForUpdate(String currentVersion);
}
