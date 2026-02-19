class VersionUtils {
  const VersionUtils._();

  /// Compare two semantic versions
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

    // Equal
    return 0;
  }

  /// Check if v1 is newer than v2
  static bool isNewer(String v1, String v2) {
    return compare(v1, v2) > 0;
  }

  /// Parse version string
  static _VersionParts _parseParts(String version) {
    // Remove 'v' prefix if present
    version = version.replaceFirst(RegExp(r'^v'), '');

    // Remove pre-release/build metadata (e.g., 1.0.0-beta+001)
    version = version.split('-').first.split('+').first;

    final parts = version.split('.');

    return _VersionParts(
      major: int.tryParse(parts.elementAtOrNull(0) ?? '0') ?? 0,
      minor: int.tryParse(parts.elementAtOrNull(1) ?? '0') ?? 0,
      patch: int.tryParse(parts.elementAtOrNull(2) ?? '0') ?? 0,
    );
  }
}

class _VersionParts {
  final int major;
  final int minor;
  final int patch;

  const _VersionParts({
    required this.major,
    required this.minor,
    required this.patch,
  });
}

extension on List<String> {
  String? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}
