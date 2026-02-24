# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[unreleased]: https://github.com/meragix/cura/compare/cura-0.7.0...HEAD
[0.7.0]: https://github.com/meragix/cura/releases/tag/cura-0.7.0
[0.6.1]: https://github.com/meragix/cura/releases/tag/cura-0.6.1
[0.6.0]: https://github.com/meragix/cura/releases/tag/cura-0.6.0
[0.5.0]: https://github.com/meragix/cura/releases/tag/cura-0.5.0
[0.4.0]: https://github.com/meragix/cura/releases/tag/cura-0.4.0
[0.3.0]: https://github.com/meragix/cura/releases/tag/cura-0.3.0
[0.2.0]: https://github.com/meragix/cura/releases/tag/cura-0.2.0
[0.1.0]: https://github.com/meragix/cura/releases/tag/cura-0.1.0
