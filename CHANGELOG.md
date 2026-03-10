# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **`UpdateChecker` port** (`lib/src/domain/ports/update_checker.dart`): Abstract contract for update checking; `VersionCommand` now depends on the port, not the concrete service — consistent with the hexagonal architecture.
- **Update check on `--version` flag**: `cura --version` now runs a lightweight update check and prints a notice to stderr when a newer version is available (stdout stays clean for scripts).
- **`VersionCommand` unit tests**: 13 tests covering `--short` mode, full output, update check integration, `v` alias, and port contract.

### Fixed

- **`VersionUtils` pre-release handling**: `1.0.0-beta` was incorrectly treated as equal to `1.0.0`. Per semver spec, pre-release < stable for the same base — users on a pre-release are now notified when the stable version ships.
- **`cyan.wrap` bypassed `useColors`** in `VersionCommand._showDetailedVersion()`: the homepage URL was always coloured regardless of `use_colors` config. Now uses the theme token with the standard `_c()` guard.
- **`UpdateCheckerService` response parsing**: no null-checks before casting `response.data['latest']['version']`. Now validates each field explicitly and throws a descriptive error if the shape is unexpected.
- **Missing `sendTimeout`** on the update check HTTP request: only `receiveTimeout` was set; `sendTimeout` is now configured as well.
- **`AppInfo.getDetailedInfo()` was dead code**: `VersionCommand` built its own output and never called this method. Removed.

- **`--theme <name>` global flag**: Override the active theme for a single run (`dark` / `light` / `minimal`) without editing the config file.
- **`ThemeManager.isValidTheme()`**: Returns whether a theme name is registered; used by validation points.
- **`CuraTheme.styleInfo()` / `BaseCuraTheme.styleInfo()`**: Completes the style-helper set alongside `stylePrimary`, `styleSuccess`, `styleWarning`, `styleError`.
- **`--no-cache` global flag**: Bypass the file cache for a single run without editing the config file (e.g. `cura check --no-cache`).
- **Cache unit tests**: `TtlStrategy`, `JsonFileSystemCache`, and `CachedAggregator` are now covered by 38 unit tests.

### Fixed

- **`config set` wrote to global instead of project config**: `ConfigSetCommand` was calling `updateKey()`, which performed a surgical YAML edit on `~/.cura/config.yaml`. It now calls `setValue()`, which targets `./.cura/config.yaml` (creating it from the project template if absent) while still preserving comments and formatting via `YamlEditor`.
- **Project config path resolved to empty string**: `_resolveProjectConfigPath()` returned `''` when no `.cura/config.yaml` was found, making `config set` fail silently or write to the wrong location. It now returns the correct path where the file would be created (`<project_root>/.cura/config.yaml`).
- **`ConfigRepository` had a dead `updateKey()` method**: The `updateKey()` declaration was still in the port interface despite being marked for removal. It has been removed; `setValue()` is now the single write API.
- **`ConfigHierarchy.getOverrides()` missing 7 fields**: `maxSuggestionsPerPackage`, `verboseLogging`, `quiet`, `githubToken`, `score_weights.*`, `ignore_packages`, and `trusted_publishers` were not compared. All fields are now covered; list fields are compared after sorting to avoid false positives from ordering differences.

- **Theme not applied to renderers**: `BarRenderer` and `TableRenderer` were using hardcoded mason_logger ANSI codes. Both now read colours from `ThemeManager.current` so custom themes take full effect.
- **Theme not applied to presenters**: `ViewPresenter` and `CheckPresenter` contained ~30 hardcoded colour calls (`cyan.wrap`, `red.wrap`, etc.). All replaced with theme tokens via a `_c(text, color)` helper that also respects `_useColors`.
- **`useColors: false` not respected**: `ConsoleLogger.warn()`, `error()`, `debug()`, and `alert()` always coloured output regardless of the `use_colors` config flag.
- **`autoDetect()` was dead code**: `ThemeManager.autoDetect()` was never called. The startup flow now calls it when no theme is explicitly set in any config file, enabling automatic dark/light detection on macOS and CI→minimal fallback.
- **CI theme desync**: In CI environments, `ThemeManager` now correctly mirrors the minimal logger (via `autoDetect()`), preventing themed output if code paths bypass the logger.
- **`config set theme xyz` caused a startup crash**: Writing an invalid theme name to the config file would throw an unhandled `ArgumentError` on the next run. `ConfigSetCommand` now validates the name before persisting.
- **`mergeWith` silently discarded global theme**: When a project config did not declare `theme:`, `CuraConfig.fromYaml` defaulted it to `'dark'`, overriding a global `theme: light`. `theme` is now nullable in `CuraConfig`; `fromYaml` returns `null` for absent keys and `mergeWith` uses `other.theme ?? this.theme`.
- **`MinimalTheme.isDark` was `true`**: A no-colour theme is not a dark theme. Corrected to `false`.
- **`enable_cache: false` was ignored**: `CachedAggregator` was always instantiated regardless of `config.enableCache`. The startup now conditionally wraps `MultiApiAggregator` only when caching is enabled.
- **`cache_max_age_hours` was ignored**: The configured TTL value was never passed to `TtlStrategy`. It is now forwarded as `defaultTtl` so the 70–89 popularity tier honours the user setting.
- **`cache clear` confirmed before deleting**: `JsonFileSystemCache.clearAll()` used fire-and-forget deletions, returning before files were actually removed. Deletions are now awaited sequentially.
- **Dead code in `TtlStrategy`**: `getPackageTtl()`, `getAlternativesTtl()`, and `getScoresTtl()` were never called. Removed.
- **Dead constants in `CacheConstants`**: Six unused TTL/limit constants removed; the hardcoded cache path in the entry point replaced with `CacheConstants.cacheSubDir`.

## [0.10.0] - 2026-03-09

### Added

- **`cura view` command**: Full implementation with issue detection, `RecommendationEngine`, risk signals (`--verbose`), and verbose score breakdown with penalty line items.
- **`view --verbose` cache and timing footer**: Cache hit/miss status at top; elapsed time and API call count at bottom.
- **`view --json`**: Machine-readable JSON output (`timestamp`, `package`, `score`, `github`, `red_flags`, `vulnerabilities`, `issues`, `recommendations`, `performance`).
- **`PenaltyEvaluator` line items**: `calculate()` returns `PenaltyResult = ({int total, List<PenaltyItem> items})`. Individual deductions are now exposed for verbose rendering.
- **`JsonFileSystemCache.getEntry()`**: Returns `({data, cachedAt})` alongside the cached payload. Used by `CachedAggregator` to surface cache age in the UI.
- **`PackageSuccess.cachedAt`**: UTC write timestamp propagated from the cache layer to `PackageAuditResult`.
- **`RecommendationEngine` flag coverage**: Added handlers for `NoNullSafetyFlag` (critical), `NotDart3CompatibleFlag` (warning), and `LimitedPlatformSupportFlag` (advisory).

### Changed

- **`PackageAuditResult.recommendations`**: Renamed from `suggestions`. Type changed from `List<String>` to `List<Recommendation>` so the presenter can drive icon and color rendering from `RecommendationLevel`.
- **`ViewPackageDetails.execute`**: Switched from `mapAsync` to a direct `switch` to capture `requestCount` and `cachedAt` from `PackageSuccess`.
- **`ViewCommand`**: Added `Stopwatch` and `--json` flag.
- **`ViewPresenter._showVerboseScoreBreakdown`**: Redesigned with aligned columns (`label.padRight(13)`, `ratio.padRight(6)`), status icons (green `✓` / yellow `!` / red `✗`) at percentage thresholds (75% / 50%), and tree connectors (`├─` / `└─`) for penalty line items. Clamped penalty totals are annotated.
- **`ViewPresenter._showRecommendations`**: Now receives `List<Recommendation>` and renders level-based icons: `✗` critical, `!` warning, `→` action, `→` advisory.
- **`RecommendationEngine` messages**: All messages rewritten to senior tone. Declarative, no em dashes, no incises.
- **`RedFlag` messages**: All `message` getters rewritten to senior tone.
- **`AuditIssue` factory messages**: All four factory constructors rewritten to senior tone.

## [0.9.0] - 2026-03-08

### Added

- **`PackageSuccess.requestCount`**: tracks exact HTTP requests per package (0 from cache).
- **`PackageAuditResult.requestCount`**: propagated from `PackageSuccess` through `mapAsync`.
- **`check --json` structured output**: `--json` now emits a full JSON report with `timestamp`, `total_packages`, `overall_health`, `status` (`PASSED` / `WARNING` / `FAILED`), `summary`, `packages` (with `red_flags` when present), `critical_packages`, and `performance` metrics.
- **`check` runtime flag overrides**: `--min-score`, `--fail-on-vulnerable`, and `--fail-on-discontinued` now take effect at runtime and override config-file values.
- **`check` config hierarchy**: `CheckCommand` accepts `defaultMinScore`, `defaultFailOnVulnerable`, `defaultFailOnDiscontinued` seeded from the resolved config — the full `CLI flag > config file > built-in default` hierarchy is now enforced.
- **`check` CI auto-detection**: `$CI` environment variable is detected at startup; cura automatically switches to plain-text output (no colors, no emojis) in any standard CI environment without extra configuration.
- **`CheckPackagesUsecase` unit tests**: 19 tests covering success path, all failure variants, and all 4 issue-detection rules (discontinued, critical CVE, low score, stale) including boundary conditions.
- **`CheckCommand` integration tests**: 20 tests covering pubspec parsing, exit-code logic for all flag combinations, config hierarchy overrides, and output mode selection.

### Changed

- **`PackageResultExtensions.mapAsync` / `mapValue`**: mapper signature extended with `int requestCount`.
- **`CheckPresenter`**: `_apiCalls` now accumulates `audit.requestCount`; label updated to `"HTTP requests"`.
- **`ErrorFormatter`**: refactored around a single `_renderBlock` primitive — all formatters now delegate to it, eliminating rendering duplication. `_verbose` made private. `_getSuggestions` converted to exhaustive switch.
- **`PubDevApiClient`**: pub.dev requests are now sequential to avoid `ParallelWaitError` swallowing typed exceptions. `fetchJson` catches `DioException` and maps 404 → `PackageNotFoundException`, 429 → `RateLimitException`.
- **`ViewCommand` / `CheckPresenter`**: `PackageProviderError` now routed through `ErrorFormatter` instead of raw `toString()`.
- **`CheckCommand`**: aborts on first `NetworkError` instead of continuing to remaining packages.
- **`CheckPackagesUsecase`**: `scoreCalculator` parameter type changed from `CalculateScore` to `ScoreCalculator` port — domain layer no longer depends on a concrete adapter.
- **`CheckPackagesUsecase`**: removed unused constructor params `minScore`, `failOnVulnerable`, `failOnDiscontinued` — acceptance criteria belong to the command layer, not the use case.
- **`PackageAuditResult.suggestions`**: changed from `required` to optional with default `[]`; use `score.recommendations` for programmatic improvement guidance.

## [0.8.0] - 2026-03-08

### Added

- **Strategy pattern for scoring**: `CalculateScore` is now a pure orchestrator delegating to `VitalityDimension`, `TechnicalHealthDimension`, `TrustDimension`, `MaintenanceDimension`, `PenaltyEvaluator`, `RedFlagDetector`, and `RecommendationEngine` — each independently testable via the `ScoringInput` Dart record.
- **`RedFlag` sealed class** with 12 typed subtypes and `RedFlagSeverity` (`info` / `warning` / `critical`) — replaces `List<String>` and eliminates fragile string matching in recommendation logic.
- **`Recommendation`** value object with `RecommendationLevel` — replaces `List<String>`.
- **`Grade` enum** with `Grade.fromScore()` and `.label` — replaces `String` grade field on `Score`.
- **`ScoreCalculator` port** (`domain/ports/`) — enables clean mocking without touching `CalculateScore`.
- **`MissingLicenseFlag`** (`critical` severity) — packages without an SPDX license are now flagged as a priority legal risk.
- **`ScoreWeights`** moved to `domain/value_objects/` (infrastructure path re-exports for compatibility).

### Changed

- **Trusted publisher**: removed automatic score of 100. Publishers like `dart.dev` now receive a **score floor of 70** — penalties and red flags still apply, ensuring stale or unlicensed official packages are surfaced.
- **`Score.grade`** `String` → `Grade`, **`Score.redFlags`** `List<String>` → `List<RedFlag>`, **`Score.recommendations`** `List<String>` → `List<Recommendation>`.

### Breaking

- `Score.grade`, `Score.redFlags`, `Score.recommendations` field types changed — callers must use `score.grade.label` for string display.

## [0.7.0] - 2026-02-24

### Added

- **`JsonFileSystemCache`**: New cache backend that persists entries as individual JSON files under `~/.cura/cache/aggregated/`. Each file follows a versioned envelope (`schemaVersion`, `cachedAt`, `expiresAt`, `data`). No native dependencies required — pure `dart:io` + `dart:convert`.

### Changed

- **Cache backend replaced**: `CacheDatabase` (SQLite via `sqflite_common_ffi`) is replaced by `JsonFileSystemCache`. The `aggregated/` namespace maps to the former `aggregated_cache` table. TTL tiers are preserved and now stored as a pre-computed `expiresAt` ISO-8601 timestamp.
- **`CachedAggregator` refactored**: `JsonFileSystemCache` is injected via constructor instead of accessed through the `CacheDatabase` singleton. The `CachedAggregatedData` typedef and `sqflite_common_ffi` import are removed.
- **Atomicity**: All cache writes use the write-then-rename pattern (`<key>.json.tmp` → `<key>.json`). On POSIX this is atomic via `rename(2)`; on Windows the target is deleted before rename (best-effort, acceptable for a cache).
- **`cleanupExpired`** now also purges orphaned `.json.tmp` files older than 1 hour in addition to expired entries.
- **Cache commands** (`clear`, `stats`, `cleanup`) receive `JsonFileSystemCache` via constructor injection instead of calling `CacheDatabase` static methods. `stats` now shows valid entry counts per namespace instead of SQL `COUNT(*)` results.
- **`CacheConstants`**: `databaseName` and `databaseVersion` removed; replaced with `cacheSubDir` and `aggregatedNamespace`.
- **Documentation**: `doc/caching.md` rewritten for the JSON file model (schema, TTL tiers, CI examples). `doc/architecture.md`, `README.md`, `CLAUDE.md`, and all affected dartdoc comments updated.

### Removed

- **`CacheDatabase`** (`lib/src/infrastructure/cache/database/cache_database.dart`) — deleted.
- **`CachedEntry<T>`** (`lib/src/infrastructure/cache/models/cached_entry.dart`) — deleted; expiry is now evaluated inside `JsonFileSystemCache.get`.
- **`sqflite_common_ffi: ^2.3.0`** and **`sqflite_common: ^2.5.6`** removed from `pubspec.yaml`. The compiled binary no longer requires a native SQLite library on the host machine.

## [0.6.1] - 2026-02-24

### Fixed

- **`CacheDatabase` double-initialisation race**: Two concurrent `await CacheDatabase.instance` calls arriving before the database was ready both invoked `_initDatabase()`, creating the SQLite connection twice. Fixed by memoising the initialisation `Future` (`_initFuture ??= _initDatabase()`), ensuring all concurrent callers share a single in-flight operation. `close()` now also resets `_initFuture` so re-opening is safe.
- **`CachedAggregator.fetchMany` silent error swallow**: Errors thrown by pool tasks were not forwarded to the stream, leaving error cases silently dropped. Added `onError` forwarding so stream consumers receive errors correctly.
- **`CachedAggregator` dead import**: Unused `import 'package:cura/src/domain/ports/cache_repository.dart'` removed.

### Changed

- **`MultiApiAggregator` uses `PoolManager`**: Replaced the inline `Pool` construction with the shared `PoolManager` utility. The aggregator no longer owns a raw `pool` import; concurrency configuration flows through `PoolManager(maxConcurrency: ...)`.
- **Dartdoc — infrastructure cache layer**: Added comprehensive API documentation to `CachedEntry`, `CacheDatabase`, `TtlStrategy` (including popularity range 0–100 and per-tier TTL tables), `CachedAggregator`, and `MultiApiAggregator`.

## [0.6.0] - 2026-02-24

### Added

- **`config init --force`**: New `-f` / `--force` flag on `cura config init` to overwrite an existing config file with built-in defaults.
- **Complete `config show`**: Now displays all configuration fields grouped by category (Appearance, Cache, Scoring, Performance, Behaviour, Logging, API, Exclusions) with score-weights validation warning.

### Fixed

- **`config set` incomplete key support**: `_writeValue` was missing `github_token`, `cache_max_age_hours`, `enable_cache`, `auto_update`, `fail_on_vulnerable`, `fail_on_discontinued`, `show_suggestions`, `max_suggestions_per_package`, `verbose_logging`, and `quiet` — those keys were readable but silently ignored on write.
- **`config get` null display**: Unknown / unset values now print `(not set)` instead of the string `"null"`.
- **`ScoreWeights.fromJson` type safety**: JSON fields are now cast with `as int?` before applying the default fallback.
- **`ConfigDefaults.defaultConfig` mutability**: Field changed from `static` to `static final` to prevent accidental reassignment at runtime.

### Changed

- Centralized concurrency manager built on top of the `pool` package.
- **Dartdoc**: Added comprehensive API documentation to `ScoreWeights`, `ConfigDefaults`, `ConfigRepository`, `YamlConfigRepository`, and all `config` sub-commands.

## [0.5.0] - 2026-02-22

### Added

- **Visual Score Breakdown**: New bar charts (█ ▓ ▒ ·) for intuitive score reading.
- **Rich UI Elements**: Added popularity dots (●●●) and Pub score indicators (●/◐/○).
- **Color-coded Status**: Visual update indicators (🟢/🟡/⚠) and severity colors for vulnerabilities.
- **GitHub Metrics**: Enhanced formatting for stars, forks, and last commit dates.

### Changed

- **Presenter Refactor**: Complete overhaul of `ViewPresenter` for better information hierarchy.
- **Output Styling**: Standardized usage of clean separator lines (═) for better scannability.

## [0.4.0] - 2026-02-19

### Added

- **Version Command**: Added a dedicated `version` command for detailed system information (CLI version, Dart SDK, Platform).
- **Update Checker**: Automatic check against pub.dev API to notify users when a newer version is available.
- **Global Flag**: Added `--version` / `-v` as a global flag for quick version check.
- **Versioning Logic**: Centralized `AppInfo` and `VersionUtils` for robust Semantic Versioning (SemVer) comparisons.
- Multi-API aggregation (pub.dev + GitHub + OSV)
- Streaming reactive package analysis
- SQLite caching (24h TTL)
- GitHub metrics integration

### Changed

- **CLI Output**: Customized the default help message for better UX.
- **Constants**: Refactored `AppConstants` to use dynamic versioning instead of hardcoded strings.

## [0.3.0] - 2026-02-15

### Added

- implement ui logger for scan command output
- implement logic to analize packages form path
- Config Hierarchy - Global vs Project Config

### Change

- update view command logger

## [0.2.0] - 2026-02-13

### Added

- add README documentation with base file in ./docs
- configuration system support
- complete theme system with dark/light mode

## [0.1.0] - 2026-02-13

### Added

- Complete error management system
- Functional `cura view <package>` command
- Basic scoring (maintenance + trust + popularity)
- Simple terminal display (no elegant table yet)
- Operational local cache.
- ScoreCalculator unit tests (>80% coverage)

[unreleased]: https://github.com/meragix/cura/compare/cura-0.10.0...HEAD
[0.10.0]: https://github.com/meragix/cura/releases/tag/cura-0.8.0
[0.9.0]: https://github.com/meragix/cura/releases/tag/cura-0.8.0
[0.8.0]: https://github.com/meragix/cura/releases/tag/cura-0.8.0
[0.7.0]: https://github.com/meragix/cura/releases/tag/cura-0.7.0
[0.6.1]: https://github.com/meragix/cura/releases/tag/cura-0.6.1
[0.6.0]: https://github.com/meragix/cura/releases/tag/cura-0.6.0
[0.5.0]: https://github.com/meragix/cura/releases/tag/cura-0.5.0
[0.4.0]: https://github.com/meragix/cura/releases/tag/cura-0.4.0
[0.3.0]: https://github.com/meragix/cura/releases/tag/cura-0.3.0
[0.2.0]: https://github.com/meragix/cura/releases/tag/cura-0.2.0
[0.1.0]: https://github.com/meragix/cura/releases/tag/cura-0.1.0
