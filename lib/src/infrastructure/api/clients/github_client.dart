import 'package:cura/src/domain/entities/github_metrics.dart';
import 'package:cura/src/shared/constants/api_constants.dart';
import 'package:dio/dio.dart';

/// Client HTTP pour GitHub API
///
/// Endpoints utilisés :
/// - GET /repos/{owner}/{repo} → Repository info
/// - GET /repos/{owner}/{repo}/stats/commit_activity → Commit activity
class GitHubApiClient {
  final Dio _dio;
  final String? _token;

  GitHubApiClient(this._dio, {String? token}) : _token = token {
    // Add auth header si token fourni
    if (_token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
    }
  }

  /// Fetch GitHub metrics depuis une URL de repository
  ///
  /// Input : https://github.com/owner/repo
  /// Output : GitHubMetrics ou null si fail
  Future<GitHubMetrics?> fetchMetrics(String repositoryUrl) async {
    try {
      final (owner, repo) = _parseGitHubUrl(repositoryUrl);
      if (owner == null || repo == null) return null;

      // Parallel fetching (repo + commit activity)
      final (repoData, activityData) = await (
        _fetchRepository(owner, repo),
        _fetchCommitActivity(owner, repo),
      ).wait;

      if (repoData == null) return null;

      return _mapToEntity(repoData, activityData, repositoryUrl);
    } catch (e) {
      // Graceful fail (GitHub indisponible ou rate limit)
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchRepository(
    String owner,
    String repo,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.githubApiUrl}/repos/$owner/$repo',
      );

      if (response.statusCode != 200) return null;
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>?> _fetchCommitActivity(
    String owner,
    String repo,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.githubApiUrl}/repos/$owner/$repo/stats/commit_activity',
      );

      if (response.statusCode != 200) return null;
      return response.data as List<dynamic>;
    } catch (e) {
      return null;
    }
  }

  GitHubMetrics _mapToEntity(
    Map<String, dynamic> repoData,
    List<dynamic>? activityData,
    String repositoryUrl,
  ) {
    // Parse commit activity (last 90 days)
    var commitCountLast90Days = 0;
    if (activityData != null && activityData.isNotEmpty) {
      // GitHub returns 52 weeks, take last ~13 weeks (90 days)
      final last13Weeks = activityData.reversed.take(13);
      commitCountLast90Days = last13Weeks.fold<int>(
        0,
        (sum, week) => sum + (week['total'] as int? ?? 0),
      );
    }

    // Parse last commit date
    DateTime? lastCommitDate;
    final pushedAt = repoData['pushed_at'] as String?;
    if (pushedAt != null) {
      lastCommitDate = DateTime.parse(pushedAt);
    }

    return GitHubMetrics(
      repositoryUrl: repositoryUrl,
      stars: repoData['stargazers_count'] as int? ?? 0,
      forks: repoData['forks_count'] as int? ?? 0,
      openIssues: repoData['open_issues_count'] as int? ?? 0,
      contributors: 0, // todo Fetch /contributors (needs extra call)
      lastCommitDate: lastCommitDate,
      commitCountLast90Days: commitCountLast90Days,
    );
  }

  (String?, String?) _parseGitHubUrl(String url) {
    // Parse: https://github.com/owner/repo → (owner, repo)
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host != 'github.com') return (null, null);

    final segments = uri.pathSegments;
    if (segments.length < 2) return (null, null);

    return (segments[0], segments[1]);
  }
}
