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

  /// Helpers
  bool get isActivelyMaintained => commitCountLast90Days > 0;

  int get daysSinceLastCommit => lastCommitDate != null ? DateTime.now().difference(lastCommitDate!).inDays : 999;

  bool get hasRecentActivity => daysSinceLastCommit <= 90;
  bool get isPopular => stars > 1000;
}
