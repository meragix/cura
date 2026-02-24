class GitHubMetrics {
  final String repositoryUrl;
  final int stars;
  final int forks;
  final int openIssues;
  final int contributors;
  final DateTime? lastCommitDate;
  final int commitCountLast90Days;

  const GitHubMetrics({
    required this.repositoryUrl,
    required this.stars,
    required this.forks,
    required this.openIssues,
    required this.contributors,
    this.lastCommitDate,
    required this.commitCountLast90Days,
  });


  /// Serialize to JSON
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
  
  /// Deserialize from JSON
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

  /// Helpers
  bool get isActivelyMaintained => commitCountLast90Days > 0;

  int get daysSinceLastCommit => lastCommitDate != null
      ? DateTime.now().difference(lastCommitDate!).inDays
      : 999;

  bool get hasRecentActivity => daysSinceLastCommit <= 90;
  bool get isPopular => stars > 1000;
}
