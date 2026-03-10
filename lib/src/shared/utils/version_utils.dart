class VersionUtils {
  const VersionUtils._();

  /// Compares two semantic version strings.
  ///
  /// Handles optional `v` prefix (`v1.2.3` == `1.2.3`) and build metadata
  /// (`1.0.0+001` is treated as `1.0.0`).
  ///
  /// Pre-release versions follow the semver spec: a pre-release tag makes a
  /// version *less than* the same base version without a tag. For example:
  /// `1.0.0-beta` < `1.0.0` < `1.0.1-alpha`.
  ///
  /// Returns:
  ///   -1 if v1 < v2
  ///    0 if v1 == v2
  ///    1 if v1 > v2
  static int compare(String v1, String v2) {
    final parts1 = _parseParts(v1);
    final parts2 = _parseParts(v2);

    // Compare major
    if (parts1.major != parts2.major) {
      return parts1.major.compareTo(parts2.major);
    }

    // Compare minor
    if (parts1.minor != parts2.minor) {
      return parts1.minor.compareTo(parts2.minor);
    }

    // Compare patch
    if (parts1.patch != parts2.patch) {
      return parts1.patch.compareTo(parts2.patch);
    }

    // Semver pre-release rule: pre-release < stable for the same base version.
    // e.g. 1.0.0-beta < 1.0.0 — notifies users on a pre-release that
    // the stable version is available.
    if (parts1.hasPreRelease && !parts2.hasPreRelease) return -1;
    if (!parts1.hasPreRelease && parts2.hasPreRelease) return 1;

    return 0;
  }

  /// Returns `true` when [v1] is strictly newer than [v2].
  static bool isNewer(String v1, String v2) {
    return compare(v1, v2) > 0;
  }

  /// Parses a version string into its numeric components.
  static _VersionParts _parseParts(String version) {
    // Remove 'v' prefix if present
    version = version.replaceFirst(RegExp(r'^v'), '');

    // Detect pre-release before stripping it (e.g. 1.0.0-beta, 1.0.0-rc.1)
    final hasPreRelease = version.contains('-');

    // Remove pre-release and build metadata (e.g. 1.0.0-beta+001 → 1.0.0)
    version = version.split('-').first.split('+').first;

    final parts = version.split('.');

    return _VersionParts(
      major: int.tryParse(parts.elementAtOrNull(0) ?? '0') ?? 0,
      minor: int.tryParse(parts.elementAtOrNull(1) ?? '0') ?? 0,
      patch: int.tryParse(parts.elementAtOrNull(2) ?? '0') ?? 0,
      hasPreRelease: hasPreRelease,
    );
  }
}

class _VersionParts {
  final int major;
  final int minor;
  final int patch;
  final bool hasPreRelease;

  const _VersionParts({
    required this.major,
    required this.minor,
    required this.patch,
    required this.hasPreRelease,
  });
}

extension on List<String> {
  String? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}
