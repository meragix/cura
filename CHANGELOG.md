# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Multi-API aggregation (pub.dev + GitHub + OSV)
- Streaming reactive package analysis
- SQLite caching (24h TTL)
- GitHub metrics integration

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

[unreleased]: https://github.com/meragix/cura/compare/cura-0.2.0...HEAD
[0.2.0]: https://github.com/meragix/cura/releases/tag/cura-0.2.0
[0.1.0]: https://github.com/meragix/cura/releases/tag/cura-0.1.0
