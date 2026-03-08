# 🗺️ Full Roadmap — `cura` (2026–2027)

> **Vision**: Become the reference tool for auditing Dart/Flutter dependency health, eliminating "vibe code" and guiding developers toward robust production choices.

---

## 📅 Global Timeline

```text
┌─────────────────────────────────────────────────────────────────────┐
│ Q1 2026      │ Q2 2026      │ Q3 2026      │ Q4 2026    │ 2027      │
├─────────────────────────────────────────────────────────────────────┤
│ MVP          │ Community    │ Advanced     │ Enterprise │ Ecosystem │
│ v0.1–v0.5   │ v1.0–v1.2   │ v1.3–v1.5   │ v2.0       │ v2.x+     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🎯 Phase 1: MVP — "The Foundation" (Q1 2026, ~6–8 weeks)

**Goal**: Build a minimal working tool that solves the core problem: **identifying dead packages in a `pubspec.yaml`**.

---

### v0.1.0 — Proof of Concept (Week 1–2)

**Features:**

- ✅ Working `cura view <package>` command
- ✅ Basic scoring (maintenance + trust + popularity)
- ✅ Simple terminal output (no fancy table yet)
- ✅ Local cache operational
- ✅ Unit tests for `ScoreCalculator` (>80% coverage)

**Expected output:**

```bash
$ cura view dio
Package: dio (v5.4.0)
Score: 95/100 ✅ HEALTHY
Last update: 15 days ago
Publisher: dart.dev (verified)
```

**Technical decisions:**

- Use `mason_logger` for colored output
- No request pool yet (added in v0.2)
- Simple cache without variable TTL (24h fixed)

**Success criteria:**

- [ ] Tool correctly analyzes `dio`, `http`, `flutter_bloc`
- [ ] Cache works and avoids repeated API calls
- [ ] Tests pass on CI/CD (GitHub Actions)

---

### v0.2.0 — Automatic Scan (Week 3–4)

**Features:**

- ✅ `cura check` command reading `pubspec.yaml`
- ✅ Dependency parsing (dependencies + dev_dependencies)
- ✅ Concurrent request pool (max 5 simultaneous)
- ✅ Progress bar (`mason_logger.progress()`)
- ✅ Text report with summary

**Expected output:**

```bash
$ cura check
📦 Analyzing 23 packages...
[████████████████████████] 100%

╭───────────────────────────────────────╮
│ SUMMARY                               │
├───────────────────────────────────────┤
│ ✅ Healthy:  18 packages              │
│ ⚠️  Warning:  4 packages              │
│ ❌ Critical:  1 package               │
╰───────────────────────────────────────╯

CRITICAL PACKAGES:
- old_package (score: 25/100)
  └─ Legacy (540+ days), no repository
```

**Technical challenges:**

- Correctly parse Git/Path dependencies (ignore for MVP)
- Handle network errors gracefully
- Display progress without polluting the terminal

**Success criteria:**

- [ ] Analyzes a standard Flutter project (30+ deps) in <30 seconds
- [ ] Rate limiting respected (no 429 errors)
- [ ] Robust error handling (package not found → warning, not crash)

---

### v0.3.0 — CI/CD Mode (Week 5–6)

**Features:**

- ✅ `--fail-on <score>` flag returning exit code 1 if threshold reached
- ✅ JSON output (`--json`) for automated parsing
- ✅ `--verbose` flag for debugging
- ✅ Complete README documentation

**Expected output:**

```bash
# GitLab CI pipeline
$ cura check --fail-on 50 --json > report.json
$ echo $?  # 1 if any package < 50/100

# JSON format
{
  "overall_score": 68,
  "status": "FAILED",
  "critical_packages": [
    {"name": "old_pkg", "score": 45}
  ]
}
```

**Use cases:**

- Block a merge request if a critical package is added
- Monitoring dashboard (integration with Grafana/Datadog)

**Success criteria:**

- [ ] Successful integration in a GitHub Actions pipeline
- [ ] Detailed documentation with `.gitlab-ci.yml` examples
- [ ] Valid JSON output (validated with JSON Schema)

---

### v0.4.0 — UX Polish (Week 7)

**Features:**

- ✅ Elegant ASCII table (with `package:cli_table`)
- ✅ Colors and emojis for status display
- ✅ `--skip-cache` flag to force refresh
- ✅ `cura cache clear` command

**Expected output:**

```bash
$ cura check

┌─────────────────────┬───────┬────────┬─────────────┐
│ Package             │ Score │ Status │ Last Update │
├─────────────────────┼───────┼────────┼─────────────┤
│ dio                 │ 95    │ ✅     │ 15 days     │
│ http                │ 88    │ ✅     │ 2 months    │
│ old_package         │ 25    │ ❌     │ 18 months   │
└─────────────────────┴───────┴────────┴─────────────┘
```

**Success criteria:**

- [ ] Interface quality comparable to `flutter pub outdated`
- [ ] Acceptable response time (cache hit <50ms)

---

### v0.5.0 — Official Publication (Week 8)

**Tasks:**

- ✅ Publish to pub.dev
- ✅ Logo and branding
- ✅ README with demo GIF
- ✅ Structured changelog
- ✅ MIT license
- ✅ Contributing guidelines

---

## 🌍 Phase 2: Community — "Adoption" (Q2 2026, ~12 weeks)

**Goal**: Build an active community and improve the tool based on user feedback.

---

### v1.0.0 — Stable Release (Week 9–10)

Focus: Production-ready

**Improvements:**

- 🔒 Stable API (no breaking changes before v2.0)
- 📝 Comprehensive documentation (pub.dev + docs)
- 🧪 Integration tests (100+ scenarios)
- 🐛 All major bugs fixed

**New features:**

- ✅ Git dependency support (`git: url: ...`)
- ✅ Path dependency support (`path: ../local_pkg`)
- ✅ Detection of packages hosted on GitLab/Bitbucket

**Expected output:**

```bash
$ cura check
⚠️  internal_package (Git dependency)
   └─ Cannot analyze (not published on pub.dev)
   └─ Recommendation: Audit manually
```

**Success criteria:**

- [ ] Zero crashes on 1,000 Flutter projects analyzed
- [ ] pub.dev score of 130/140 minimum
- [ ] Featured in Flutter Weekly newsletter

---

## Contributor Guide

> All contributions are welcome. To maintain project quality, please follow these rules before opening a PR.

### Before contributing

- [ ] Read [CONTRIBUTING.md](./CONTRIBUTING.md) in full
- [ ] Check that no existing issue already covers your topic
- [ ] Open a discussion issue before any significant work
- [ ] Fork the repo and create a branch from `main`

### Branch naming convention

```text
feat/v1.1.0-suggest-command
fix/score-calculation-edge-case
docs/update-contributing-guide
test/add-integration-tests-osv
refactor/extract-cache-strategy
```

### PR checklist (mandatory)

Every Pull Request must check all of these before review:

- [ ] Branch starts from `main` and is up to date
- [ ] Title follows [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`)
- [ ] Unit tests pass: `dart test`
- [ ] No analysis regressions: `dart analyze`
- [ ] Formatting respected: `dart format --set-exit-if-changed .`
- [ ] Test coverage stays >= 80%
- [ ] A clear description explains the "why" of the change
- [ ] Edge cases are covered (package not found, network error, invalid cache)
- [ ] No raw `print()` — use `mason_logger`
- [ ] New dependencies are justified in the PR description

### Code standards

- Strict hexagonal architecture: the domain never imports infrastructure
- Manual dependency injection only — no `GetIt` or service locator
- Typed exceptions only — no `throw Exception('message')`
- Zero native dependencies outside `dart:io`

### Review process

1. At least **1 approval** required to merge
2. Blocking comments must be resolved, not ignored
3. The maintainer performs the merge (not the contributor)
4. Squash merge mandatory to keep a clean history

---

### v1.1.0 — Alternative Suggestion (Week 11–14)

**Suggested owner**: maintainer + external contributor welcome
**GitHub label**: `feat`, `good first issue` (for similarity mappings)

**Features to implement:**

- [ ] `cura suggest <package>` command
- [ ] `SuggestionEntry` data model in the domain layer
- [ ] Similarity database (`assets/suggestions.json`)
- [ ] Comparative scoring between source package and alternatives
- [ ] Display suggestion reasons (performance, maintenance, security)
- [ ] Support for `.cura/suggestions.yaml` for project-level overrides

**Expected output:**

```bash
$ cura suggest shared_preferences

shared_preferences (score: 65/100)
   Last update: 8 months — Publisher: flutter.dev

Recommended alternatives:

1. hive (score: 92/100) — Recommended
   Lightweight NoSQL, better maintained
   +45% faster reads
   Migration guide: https://docs.hivedb.dev

2. flutter_secure_storage (score: 88/100)
   Best if encryption is required
   Overhead: +20ms per operation
```

**Technical challenges:**

- Build the initial similarity database (50+ manual mappings)
- Avoid out-of-context suggestions (`dio` is not a replacement for `http` in all cases)
- Allow clean crowdsourcing via PR on the JSON file

**Acceptance criteria:**

- [ ] `cura suggest <package>` works for the 20 most-used packages in the Flutter ecosystem
- [ ] 80%+ suggestion relevance (manual validation by maintainer)
- [ ] 50+ similarity mappings documented in `assets/suggestions.json`
- [ ] Contribution mechanism via PR clearly documented in CONTRIBUTING.md
- [ ] Unit tests for suggestion file parsing
- [ ] Correct handling of the "no known alternative" case

---

### v1.2.0 — Local & Community Whitelist (Week 15–17)

**Suggested owner**: maintainer
**GitHub label**: `feat`, `community`

**Features to implement:**

- [ ] Support for `.cura/whitelist.yaml` in the current project
- [ ] Support for global whitelist in `~/.cura/whitelist.yaml`
- [ ] `cura whitelist add <package> --reason "..."` command
- [ ] `cura whitelist list` command to inspect active entries
- [ ] `cura whitelist remove <package>` command
- [ ] Community whitelist hosted on GitHub (optional sync)

**File format:**

```yaml
# .cura/whitelist.yaml
packages:
  old_but_stable_pkg:
    reason: "Stable package, no bugs in 2 years, no viable alternative"
    added_by: "john@company.com"
    date: "2026-04-15"
    expires: "2026-10-15"   # optional — forces periodic review
```

**Acceptance criteria:**

- [ ] Local whitelist takes priority over global
- [ ] A whitelisted package displays a distinct badge in the results table
- [ ] Expiration is checked at analysis time and generates a warning if exceeded
- [ ] `cura whitelist list` displays reasons and dates
- [ ] 100+ initial packages in the community whitelist on GitHub
- [ ] Tests covering the merging of both whitelist levels

---

## 🚀 Phase 3: Advanced — "Intelligence" (Q3 2026, ~12 weeks)

**Goal**: Add advanced features that make `cura` indispensable in team workflows.

---

### v1.3.0 — Transitive Dependency Analysis (Week 18–21)

**Suggested owner**: maintainer
**GitHub label**: `feat`, `hard`

**Features to implement:**

- [ ] Parse `pubspec.lock` to extract the full dependency graph
- [ ] Recursive resolution up to N levels deep (default: 3, max: 5)
- [ ] Cycle detection with clean exit (no infinite loop)
- [ ] Aggregate scoring taking transitive dependencies into account
- [ ] ASCII graph visualization in the terminal
- [ ] `--deep` flag to enable transitive analysis

**Expected output:**

```bash
$ cura check --deep

Deep analysis (3 levels)...

Your app (aggregate score: 85/100)
├── dio (95/100)
│   └── http_parser (90/100)
├── old_package (45/100)
│   └── deprecated_lib (10/100)  <-- TRANSITIVE RISK
└── flutter_bloc (92/100)

ALERT: old_package ships deprecated_lib (abandoned 900+ days ago)
Recommendation: Migrate to new_package
```

**Technical challenges:**

- Parse `pubspec.lock` (complex YAML with nested dependencies)
- Handle dependency cycles without infinite loops
- Limit depth (max 5 levels to prevent request explosion)

**Acceptance criteria:**

- [ ] Detects 95%+ of problematic transitive dependencies on a reference test project
- [ ] Analysis time under 2 minutes for a project with 50+ direct dependencies
- [ ] Cycles are detected and logged without crashing
- [ ] `--deep` flag documented in `--help`
- [ ] Integration tests with a fixture `pubspec.lock`

---

### v1.4.0 — Security & CVE (Week 22–25)

**Suggested owner**: maintainer + security contributor welcome
**GitHub label**: `feat`, `security`

**Features to implement:**

- [ ] Integration with OSV.dev API (`OsvApiClient` — already architected)
- [ ] Batch request for all packages in a single pass
- [ ] CVE → CVSS severity mapping (Critical / High / Medium / Low)
- [ ] Score automatically set to zero if a Critical CVE is detected
- [ ] `--security` flag to display the vulnerability report
- [ ] JSON output enriched with `vulnerabilities` field

**Expected output:**

```bash
$ cura check --security

VULNERABILITIES DETECTED:

[CRITICAL] dio@4.0.0
   CVE-2023-12345 — SSRF vulnerability (CVSS: 9.8)
   Fix: Update to dio >= 5.4.0

[MEDIUM] http@0.13.0
   CVE-2022-67890 — Header injection (CVSS: 5.4)
   Fix: Update to http >= 1.0.0
```

**Data sources:**

- OSV.dev (Open Source Vulnerabilities) — free API
- GitHub Advisory Database — free API

**Acceptance criteria:**

- [ ] 100% of known critical CVEs detected (validated against OSV.dev dataset)
- [ ] False positives below 2%
- [ ] Overall score drops to 0 when a Critical CVE is present (rule documented)
- [ ] Graceful degradation if OSV.dev is unreachable (warning, not crash)
- [ ] Tests with mocked OSV response fixtures

---

### v1.5.0 — HTML Export & Audit Report (Week 26–29)

**Suggested owner**: maintainer
**GitHub label**: `feat`

**Features to implement:**

- [ ] `--report html` flag to generate an `audit.html` file
- [ ] Interactive, filterable, sortable table (vanilla JS)
- [ ] Score evolution chart over time (Chart.js, using cached data)
- [ ] "Priority recommendations" section generated automatically
- [ ] `--output <path>` flag to choose the output path

**Expected output:**

```bash
$ cura check --report html --output audit.html

Report generated: audit.html
   Contents:
     - Score evolution chart
     - Interactive filterable table
     - Priority recommendations
     - Migration roadmap
```

**Acceptance criteria:**

- [ ] Report opens in modern browsers with no network dependency
- [ ] Self-contained HTML file (inline assets or CDN acceptable)
- [ ] File size under 2MB for a 100-package project
- [ ] Report data matches terminal output exactly
- [ ] Non-regression test: compare generated HTML to a reference snapshot

---

## 🏢 Phase 4: Enterprise — "Scale" (Q4 2026, ~12 weeks)

**Goal**: Make `cura` usable in enterprise environments with governance and monitoring features.

---

### v2.0.0 — Multi-Project & Dashboard (Week 30–35)

**Suggested owner**: maintainer
**GitHub label**: `feat`, `breaking-change`

**Features to implement:**

- [ ] `cura serve [--port <port>]` command starting a local HTTP server
- [ ] Workspace scan: auto-detect `pubspec.yaml` files in a directory
- [ ] Internal REST API exposing results as JSON
- [ ] HTML/CSS/JS vanilla dashboard (zero framework)
- [ ] Cross-project comparison view
- [ ] Score history persistence with SQLite

**Target architecture:**

- Backend: `package:shelf` (Dart)
- Frontend: HTML + CSS + Alpine.js for lightweight interactivity
- Storage: SQLite via `package:sqlite3`

**Expected output:**

```bash
$ cura serve --port 8080

Dashboard available at http://localhost:8080

Detected projects:
  app_mobile    85/100   23 packages
  app_web       92/100   18 packages
  shared_lib    78/100   12 packages
```

**Acceptance criteria:**

- [ ] Support for 50+ simultaneous projects without visible degradation
- [ ] Responsive interface (tested on mobile via Chrome DevTools)
- [ ] Clean server shutdown via Ctrl+C (port released)
- [ ] `cura serve` command documented in the README
- [ ] REST API integration tests (endpoints `/projects`, `/packages/:name`)

---

### v2.1.0 — License Detection (Week 36–38)

**Suggested owner**: external contributor welcome
**GitHub label**: `feat`, `help wanted`

**Features to implement:**

- [ ] Extract license from pub.dev metadata
- [ ] License compatibility table (MIT, Apache 2.0, BSD, GPL-2, GPL-3, AGPL, etc.)
- [ ] Conflict detection against the current project's license (config `.cura/config.yaml`)
- [ ] `--licenses` flag to display the license report
- [ ] CSV export of license report for compliance audits

**Expected output:**

```bash
$ cura check --licenses

LICENSE CONFLICT DETECTED:

Your app: Proprietary license
├── dio (Apache 2.0)       compatible
├── flutter_bloc (MIT)     compatible
└── gpl_package (GPL-3.0)  INCOMPATIBLE
    GPL-3.0 requires open-sourcing the project

CSV report generated: licenses_report.csv
```

**Acceptance criteria:**

- [ ] Precision >= 95% on license detection (manual validation)
- [ ] The 10 most common licenses in the pub.dev ecosystem are handled
- [ ] A GPL conflict in a proprietary project generates an error (exit code 1)
- [ ] CSV report is importable in Excel and Google Sheets without manipulation

---

### v2.2.0 — Plugin System (Week 39–41)

**Suggested owner**: maintainer
**GitHub label**: `feat`, `architecture`

**Features to implement:**

- [ ] `CuraPlugin` interface in the domain layer (port)
- [ ] Hooks: `onAnalysisStart`, `onPackageScored`, `onCriticalPackageDetected`, `onAnalysisComplete`
- [ ] Plugin loading via `.cura/config.yaml` configuration
- [ ] Official `cura_plugin_github_actions` plugin (PR annotation)
- [ ] Plugin API documentation in `/docs/plugins.md`

**Target interface:**

```dart
abstract class CuraPlugin {
  String get name;
  String get version;

  Future<void> onAnalysisStart(List<String> packages) async {}
  Future<void> onPackageScored(PackageScore result) async {}
  Future<void> onCriticalPackageDetected(PackageScore result) async {}
  Future<void> onAnalysisComplete(AnalysisReport report) async {}
}
```

**Acceptance criteria:**

- [ ] 3+ official plugins published on pub.dev at launch
- [ ] Plugin API documented with complete examples
- [ ] A failing plugin does not crash `cura` (error isolation)
- [ ] Plugin API versioning (`PLUGIN_API_VERSION = 1`)

---

## 🌐 Phase 5: Ecosystem — "The Ecosystem" (2027+)

**Goal**: Build a sustainable ecosystem around `cura`: cloud API, AI, SaaS platform.

---

### v2.3.0 — Public Cloud API (Q1 2027)

**Target features:**

- [ ] Hosted REST cloud API (`api.cura.meragix.dev`)
- [ ] API key authentication
- [ ] Webhooks for continuous dependency monitoring
- [ ] Native GitHub App and GitLab Bot integration
- [ ] Free tier: 1,000 requests/month
- [ ] Pro tier: 50,000 requests/month ($29/month)
- [ ] Enterprise tier: unlimited ($299/month)

**Acceptance criteria:**

- [ ] Availability SLA >= 99.5%
- [ ] Median latency < 200ms per request
- [ ] Complete and up-to-date OpenAPI documentation

---

### v2.4.0 — AI-Powered Suggestions (Q2 2027)

**Target features:**

- [ ] Static analysis of the source code to detect actual package usage
- [ ] Personalized migration guide generation via LLM
- [ ] Contextual suggestions based on project code (not just package name)
- [ ] LLM API key optional (graceful degradation without key)

**Expected output:**

```bash
$ cura suggest shared_preferences --ai

Analyzing code...

Usage detected in your codebase:
  - JWT token storage (auth_service.dart:42)
  - User UI preferences (settings_page.dart:18)

Recommendations:
  1. flutter_secure_storage for tokens (AES encryption)
  2. Keep shared_preferences for UI preferences

Migration guide generated: migration_guide.md
```

**Acceptance criteria:**

- [ ] Static analysis covers Dart and Flutter without obvious false positives
- [ ] Generated migration guide is syntactically valid
- [ ] LLM API usage is optional and documented

---

### v3.0.0 — Full Platform (Q4 2027)

- [ ] `cura.dev` SaaS platform with hosted web dashboard
- [ ] Continuous monitoring and real-time alerts
- [ ] Predictive recommendations based on pub.dev trends
- [ ] DevOps integrations: Jira, Linear, PagerDuty, Datadog
- [ ] "Cura Verified" certification for quality packages

---

## 🛠️ Tech Stack

```yaml
CLI:
  - Pure Dart
  - mason_logger (terminal output)
  - args (command parsing)

Cache & Storage:
  - JSON files (package cache, dart:io only)
  - SQLite (dashboard history, v2.0+)

Dashboard (v2.0+):
  - Shelf (Dart HTTP server)
  - HTML + CSS + Alpine.js
  - Chart.js (charts)

Infrastructure:
  - GitHub Actions (CI/CD)
  - Docker (distribution packaging)

Monitoring:
  - Sentry (error tracking)
  - Plausible (privacy-first analytics)
```

---

**Conclusion**: The key to success is starting simple, iterating on field feedback, and maintaining exemplary code quality to attract serious contributors. The market is real, the architecture is solid. Every PR counts.
