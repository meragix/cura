# API Integration

Cura aggregates data from three external APIs to compute each package's health
score. This document describes what is fetched from each source, how errors are
handled, and how to configure authentication.

---

## Data Sources

| Source      | Base URL                        | Auth required |
|-------------|---------------------------------|---------------|
| **pub.dev** | `https://pub.dev/api`           | No            |
| **GitHub**  | `https://api.github.com`        | Optional (token) |
| **OSV.dev** | `https://api.osv.dev/v1`        | No            |

---

## pub.dev

### Endpoints used

| Endpoint                        | Data retrieved                                    |
|---------------------------------|---------------------------------------------------|
| `GET /packages/{name}`          | Version, publisher, homepage URL                  |
| `GET /packages/{name}/metrics`  | Pana score, likes, popularity, null-safety, tags  |

### Key fields

- `latest.pubspec` — version, description, repository, homepage
- `metrics.grantedPoints` / `metrics.maxPoints` — Pana score (0–140 scale)
- `metrics.likeCount` — community likes
- `metrics.popularityScore` — download-based popularity (0.0–1.0)
- `tags` — includes `is:discontinued`, `is:flutter-favorite`, `is:null-safe`, platform tags

### Rate limits

pub.dev does not publish an official rate limit. Cura limits concurrency to
`max_concurrency` parallel requests (default: 5) and retries transiently failed
requests with exponential back-off (default: 3 retries).

---

## GitHub

### Endpoints used

| Endpoint                        | Data retrieved                        |
|---------------------------------|---------------------------------------|
| `GET /repos/{owner}/{repo}`     | Stars, forks, open issues, description |
| `GET /repos/{owner}/{repo}/commits` | Commit recency (last 90 days)     |

The repository URL is extracted from the package's `pubspec.yaml` `repository`
or `homepage` field. If neither contains a `github.com` URL, GitHub metrics are
skipped for that package.

### Key fields

- `stargazers_count` — star count
- `forks_count` — fork count
- `open_issues_count` — open issue count
- First commit date in the response — used to derive days since last commit

### Authentication

Without a token, the GitHub API allows **60 requests per hour** per IP address.
With a personal access token the limit rises to **5 000 requests per hour**.

Set a token:

```bash
cura config set github_token ghp_xxxxxxxxxxxxx
```

Generate a token at <https://github.com/settings/tokens>. No scopes are
required for public repositories.

In CI, inject the workflow's built-in token:

```yaml
env:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

Then pass it to Cura before running the check:

```bash
cura config set github_token "$GITHUB_TOKEN"
```

### Skipping GitHub

If a GitHub token is unavailable and rate limits are a concern, disable GitHub
metrics entirely:

```bash
cura check --no-github
```

Packages without GitHub data receive 0 points for the GitHub-derived portion of
the Vitality score (commit recency). All other dimensions are unaffected.

---

## OSV.dev

### Endpoint used

| Endpoint                   | Data retrieved               |
|----------------------------|------------------------------|
| `POST /query`              | Security advisories for a package |

### Request body

```json
{
  "package": {
    "name": "package_name",
    "ecosystem": "Pub"
  }
}
```

### Key fields

- `vulns[].id` — advisory identifier (e.g. `GHSA-xxxx-xxxx-xxxx`)
- `vulns[].summary` — short description
- `vulns[].severity[].score` — CVSS score
- `vulns[].severity[].type` — scoring system (`CVSS_V3`, `CVSS_V2`)

### Score impact

A **critical or high** severity advisory forces the package score to **0**
regardless of all other criteria. The vulnerability details are surfaced in
`cura view <package>` output.

OSV.dev has no published rate limit and requires no authentication.

---

## HTTP Client

All three clients share a single [Dio](https://pub.dev/packages/dio) HTTP
client configured at startup:

- **Connect timeout** — `timeout_seconds` config key (default: 10 s)
- **Receive timeout** — same value
- **Retry** — up to `max_retries` attempts (default: 3) with exponential
  back-off on connection errors and 5xx responses
- **Concurrency** — bounded to `max_concurrency` simultaneous requests
  (default: 5) via a pool

The GitHub client attaches a `Bearer` token only when one is configured; the
auth header is injected per-request and never touches the shared client options,
so pub.dev and OSV.dev requests are never accidentally authenticated.

---

## Error Handling

| Condition            | Behaviour                                                     |
|----------------------|---------------------------------------------------------------|
| Network timeout      | Retried up to `max_retries` times, then `NetworkException`    |
| 404 Not Found        | `PackageNotFoundException` — package skipped in results       |
| 429 Rate Limited     | `RateLimitException` — surface to user with advice            |
| 5xx Server Error     | Retried, then treated as a transient failure                  |
| Missing GitHub URL   | GitHub metrics set to defaults (0 stars, no commits data)     |
| OSV.dev error        | Vulnerabilities treated as unknown — score not forced to 0    |

---

## Configuration Keys

| Key                | Default | Description                              |
|--------------------|---------|------------------------------------------|
| `github_token`     | —       | GitHub personal access token             |
| `timeout_seconds`  | `10`    | HTTP timeout in seconds                  |
| `max_retries`      | `3`     | Retry attempts before giving up          |
| `max_concurrency`  | `5`     | Max simultaneous outbound requests       |

---

## Related

- [Caching](caching.md) — how API responses are stored locally
- [Configuration reference](configuration.md) — full config key reference
- [Scoring algorithm](scoring.md) — how fetched data maps to scores
