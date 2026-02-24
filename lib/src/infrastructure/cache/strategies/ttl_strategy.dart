/// Stateless TTL (time-to-live) policy for Cura's cache layers.
///
/// All methods accept a [popularity] score in the **0–100** range as reported
/// by pub.dev (`PackageInfo.popularity`). Higher popularity implies that the
/// package changes less frequently relative to the interest it receives, so
/// longer cache durations are safe. Lower popularity packages are refreshed
/// more aggressively to surface deprecations or security issues sooner.
///
/// The class is uninstantiable; use the static factory methods directly.
class TtlStrategy {
  const TtlStrategy._();

  /// Returns the TTL in hours for a raw [PackageInfo] entry.
  ///
  /// | Popularity range | TTL             |
  /// |-----------------|-----------------|
  /// | ≥ 90            | 48 h            |
  /// | 70 – 89         | [defaultTtl] h  |
  /// | 40 – 69         | 12 h            |
  /// | < 40            | 6 h             |
  ///
  /// [popularity] must be in the range 0–100 (pub.dev popularity score).
  /// [defaultTtl] overrides the default 24-hour bucket for the 70–89 tier.
  static int getPackageTtl({
    required int popularity,
    int defaultTtl = 24,
  }) {
    if (popularity >= 90) return 48;
    if (popularity >= 70) return defaultTtl;
    if (popularity >= 40) return 12;
    return 6;
  }

  /// Returns the TTL in hours for a full [AggregatedPackageData] entry.
  ///
  /// Aggregated entries include GitHub metrics and OSV vulnerability data,
  /// which change more frequently than pub.dev metadata alone. TTLs are
  /// therefore halved compared to [getPackageTtl].
  ///
  /// | Popularity range | TTL             |
  /// |-----------------|-----------------|
  /// | ≥ 90            | 24 h            |
  /// | 70 – 89         | [defaultTtl] h  |
  /// | 40 – 69         | 6 h             |
  /// | < 40            | 3 h             |
  ///
  /// [popularity] must be in the range 0–100 (pub.dev popularity score).
  /// [defaultTtl] overrides the default 12-hour bucket for the 70–89 tier.
  static int getAggregatedTtl({
    required int popularity,
    int defaultTtl = 12,
  }) {
    if (popularity >= 90) return 24;
    if (popularity >= 70) return defaultTtl;
    if (popularity >= 40) return 6;
    return 3;
  }

  /// Returns the TTL in hours for the package-alternatives database.
  ///
  /// Alternatives data is relatively stable and updated at most once a day.
  static int getAlternativesTtl() => 24;

  /// Returns the TTL in hours for cached pub.dev score responses.
  ///
  /// Scores are recomputed by pub.dev infrastructure at most once a day,
  /// making a 24-hour TTL appropriate.
  static int getScoresTtl() => 24;
}
