/// Repository health signals fetched from the GitHub REST API.
///
/// All fields reflect the state of the repository at the time of the last
/// successful API call. Instances are constructed by `GitHubApiClient` and
/// cached as part of [AggregatedPackageData] in the SQLite store.
///
/// [lastCommitDate] is `null` when the repository has no commits or when the
/// GitHub API does not return commit data.
class GitHubMetrics {
  /// Canonical repository URL (e.g. `https://github.com/owner/repo`).
  final String repositoryUrl;

  /// Total number of stars (GitHub ★).
  final int stars;

  /// Total number of forks.
  final int forks;

  /// Number of open issues at the time of the last API call.
  final int openIssues;

  /// Number of distinct contributors with at least one merged commit.
  final int contributors;

  /// Timestamp of the most recent commit, or `null` when unavailable.
  final DateTime? lastCommitDate;

  /// Number of commits merged in the last 90 days.
  final int commitCountLast90Days;

  /// Creates a [GitHubMetrics] snapshot.
  const GitHubMetrics({
    required this.repositoryUrl,
    required this.stars,
    required this.forks,
    required this.openIssues,
    required this.contributors,
    this.lastCommitDate,
    required this.commitCountLast90Days,
  });

  /// Serialises this snapshot to a JSON-compatible map for SQLite caching.
  Map<String, dynamic> toJson() {
    return {
      'repository_url': repositoryUrl,
      'stars': stars,
      'forks': forks,
      'open_issues': openIssues,
      'contributors': contributors,
      'last_commit_date': lastCommitDate?.toIso8601String(),
      'commit_count_last_90_days': commitCountLast90Days,
    };
  }

  /// Deserialises a [GitHubMetrics] snapshot from a JSON map produced by
  /// [toJson].
  factory GitHubMetrics.fromJson(Map<String, dynamic> json) {
    return GitHubMetrics(
      repositoryUrl: json['repository_url'] as String,
      stars: json['stars'] as int,
      forks: json['forks'] as int,
      openIssues: json['open_issues'] as int,
      contributors: json['contributors'] as int,
      lastCommitDate: json['last_commit_date'] != null
          ? DateTime.parse(json['last_commit_date'] as String)
          : null,
      commitCountLast90Days: json['commit_count_last_90_days'] as int,
    );
  }

  // ---------------------------------------------------------------------------
  // Derived properties
  // ---------------------------------------------------------------------------

  /// Whether the repository has received at least one commit in the last
  /// 90 days.
  bool get isActivelyMaintained => commitCountLast90Days > 0;

  /// Number of days since the last commit.
  ///
  /// Returns `999` as a sentinel value when [lastCommitDate] is `null`,
  /// ensuring that packages without commit data score low on the vitality
  /// dimension rather than receiving an undefined result.
  int get daysSinceLastCommit => lastCommitDate != null
      ? DateTime.now().difference(lastCommitDate!).inDays
      : 999;

  /// Whether the last commit is within the 90-day activity window.
  bool get hasRecentActivity => daysSinceLastCommit <= 90;

  /// Whether the repository has more than 1 000 stars.
  bool get isPopular => stars > 1000;
}
