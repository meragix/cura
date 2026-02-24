import 'package:cura/src/domain/entities/github_metrics.dart';
import 'package:cura/src/shared/constants/api_constants.dart';
import 'package:dio/dio.dart';

/// HTTP client for the GitHub REST API v3.
///
/// ### Endpoints used
/// | Method | Path                                          | Purpose                     |
/// |--------|-----------------------------------------------|-----------------------------|
/// | GET    | `/repos/{owner}/{repo}`                       | Stars, forks, open issues   |
/// | GET    | `/repos/{owner}/{repo}/stats/commit_activity` | Weekly commit counts        |
///
/// ### Authentication
/// An optional Bearer [token] can be supplied to raise the unauthenticated
/// rate limit from 60 to 5 000 requests per hour. The token is injected as
/// a per-request `Authorization` header so it is **never** sent to other
/// API clients (pub.dev, OSV.dev) that share the same [Dio] instance.
///
/// ### Known limitation — contributor count
/// The `contributors` field in the returned [GitHubMetrics] is always `0`
/// because fetching it requires an additional paginated call to
/// `/repos/{owner}/{repo}/contributors`. This will be implemented in a
/// future iteration.
class GitHubApiClient {
  final Dio _dio;
  final String? _token;

  /// Creates a [GitHubApiClient].
  ///
  /// [dio] is the shared HTTP client configured by [HttpHelper.buildClient].
  /// [token] is an optional GitHub personal access token or fine-grained PAT.
  GitHubApiClient(this._dio, {String? token}) : _token = token;

  /// Fetches repository health metrics for the package at [repositoryUrl].
  ///
  /// [repositoryUrl] must be a canonical GitHub URL of the form
  /// `https://github.com/{owner}/{repo}`. Non-GitHub URLs and malformed
  /// URLs return `null`.
  ///
  /// The repository endpoint and commit-activity endpoint are fetched in
  /// parallel. If the repository endpoint fails, `null` is returned.
  /// A missing commit-activity response degrades gracefully to a zero count.
  ///
  /// Any error (network failure, 404, rate limit) is silently swallowed and
  /// `null` is returned so that a GitHub outage never blocks an audit run.
  Future<GitHubMetrics?> fetchMetrics(String repositoryUrl) async {
    try {
      final (owner, repo) = _parseGitHubUrl(repositoryUrl);
      if (owner == null || repo == null) return null;

      final (repoData, activityData) = await (
        _fetchRepository(owner, repo),
        _fetchCommitActivity(owner, repo),
      ).wait;

      if (repoData == null) return null;

      return _mapToEntity(repoData, activityData, repositoryUrl);
    } catch (_) {
      return null;
    }
  }

  /// Calls `GET /repos/{owner}/{repo}` and returns the raw JSON body.
  ///
  /// Returns `null` on any non-200 response or network error.
  Future<Map<String, dynamic>?> _fetchRepository(
    String owner,
    String repo,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.githubApiUrl}/repos/$owner/$repo',
        options: _authOptions,
      );
      if (response.statusCode != 200) return null;
      return response.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Calls `GET /repos/{owner}/{repo}/stats/commit_activity` and returns
  /// the raw weekly-activity list.
  ///
  /// GitHub returns 52 weekly buckets. Returns `null` on any non-200 response
  /// or if GitHub is still computing the statistics (HTTP 202).
  Future<List<dynamic>?> _fetchCommitActivity(
    String owner,
    String repo,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.githubApiUrl}/repos/$owner/$repo/stats/commit_activity',
        options: _authOptions,
      );
      if (response.statusCode != 200) return null;
      return response.data as List<dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Maps raw API responses to a [GitHubMetrics] domain entity.
  ///
  /// Commit activity is summed over the last 13 weekly buckets (≈ 90 days)
  /// from the 52-week series returned by GitHub. [activityData] may be `null`
  /// when the stats endpoint is unavailable; the commit count defaults to `0`.
  GitHubMetrics _mapToEntity(
    Map<String, dynamic> repoData,
    List<dynamic>? activityData,
    String repositoryUrl,
  ) {
    var commitCountLast90Days = 0;
    if (activityData != null && activityData.isNotEmpty) {
      // GitHub returns 52 weekly buckets; the last 13 cover ≈ 90 days.
      final last13Weeks = activityData.reversed.take(13);
      commitCountLast90Days = last13Weeks.fold<int>(
        0,
        (sum, week) => sum + (week['total'] as int? ?? 0),
      );
    }

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
      // TODO(github): fetch /contributors to get an accurate count.
      contributors: 0,
      lastCommitDate: lastCommitDate,
      commitCountLast90Days: commitCountLast90Days,
    );
  }

  /// Parses a GitHub repository URL into an `(owner, repo)` record.
  ///
  /// Returns `(null, null)` for any URL that is not a valid
  /// `https://github.com/{owner}/{repo}` path.
  (String?, String?) _parseGitHubUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host != 'github.com') return (null, null);

    final segments = uri.pathSegments;
    if (segments.length < 2) return (null, null);

    return (segments[0], segments[1]);
  }

  /// Builds per-request Dio options carrying the Bearer token.
  ///
  /// Returns `null` when no token was provided, which leaves the default
  /// (unauthenticated) headers unchanged for that request.
  Options? get _authOptions => _token != null
      ? Options(headers: {'Authorization': 'Bearer $_token'})
      : null;
}
