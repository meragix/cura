# Architecture Overview

Cura follows **Hexagonal Architecture** (Ports & Adapters) with strict layering.
The domain layer has zero dependencies on external packages or infrastructure;
all I/O flows through explicit port interfaces implemented by infrastructure
adapters.

---

## Layer Diagram

```text
┌────────────────────────────────────────────────────────────┐
│  Entry Point  bin/cura.dart                                │
│  Manual constructor-injection DI -- wires all layers       │
└────────────────────────────────────────────────────────────┘
                            |
                            v
┌────────────────────────────────────────────────────────────┐
│  Application Layer   lib/src/application/                  │
│  Commands: CheckCommand, ViewCommand, ConfigCommand,       │
│            VersionCommand, CacheCommand                    │
└────────────────────────────────────────────────────────────┘
                            |
                            v
┌────────────────────────────────────────────────────────────┐
│  Domain Layer   lib/src/domain/                            │
│  Use cases, entities, value objects, port interfaces       │
│  Zero external dependencies -- pure Dart                   │
└────────────────────────────────────────────────────────────┘
         ^ ports (interfaces)    | adapters (implementations)
         |                       v
┌────────────────────────────────────────────────────────────┐
│  Infrastructure Layer   lib/src/infrastructure/            │
│  API clients, JSON file cache, YAML config repository      │
└────────────────────────────────────────────────────────────┘
                            |
                            v
┌────────────────────────────────────────────────────────────┐
│  Presentation Layer   lib/src/presentation/                │
│  Loggers, renderers, themes, presenters                    │
└────────────────────────────────────────────────────────────┘
```

---

## Directory Map

```text
bin/
  cura.dart                       <- composition root (DI in 7 phases)

lib/src/
  domain/
    entities/                     <- PackageInfo, Score, GitHubMetrics, Vulnerability
    value_objects/
      grade.dart                  <- Grade enum (A+…F) with Grade.fromScore()
      red_flag.dart               <- sealed class RedFlag + 12 typed subtypes
      recommendation.dart         <- Recommendation with RecommendationLevel
      score_weights.dart          <- ScoreWeights (source of truth — domain layer)
      result.dart, exception.dart <- sealed Result<T>, CuraException
    ports/                         <- abstract interfaces (contracts)
      package_data_aggregator.dart
      config_repository.dart
      score_calculator.dart        <- ScoreCalculator (mockable port for CalculateScore)
    usecases/                      <- CalculateScore (orchestrator), CheckPackagesUsecase,
                                      ViewPackageDetails
    services/
      scoring/                     <- Strategy pattern: one class per dimension
        scoring_input.dart         <- ScoringInput record typedef + isConsideredStable()
        scoring_dimension.dart     <- ScoringDimension abstract interface
        vitality_dimension.dart
        technical_health_dimension.dart
        trust_dimension.dart
        maintenance_dimension.dart
        penalty_evaluator.dart
        red_flag_detector.dart
        recommendation_engine.dart
    exceptions/                    <- CuraException hierarchy

  application/
    commands/                      <- CheckCommand, ViewCommand, ConfigCommand,
                                      VersionCommand, CacheCommand + sub-commands
    dto/                           <- Data Transfer Objects

  infrastructure/
    api/
      clients/                     <- PubDevApiClient, GitHubApiClient, OsvApiClient
    aggregators/
      multi_api_aggregator.dart    <- Facade: coordinates all three API clients
      cached_aggregator.dart       <- Decorator: adds caching transparently
    cache/
      json_file_system_cache.dart  <- JSON file cache
      strategies/ttl_strategy.dart <- popularity-based TTL
      models/cached_entry.dart
    repositories/
      yaml_config_repository.dart  <- ConfigRepository adapter
    config/
    config/models/score_weights.dart <- re-exports domain/value_objects/score_weights.dart

  presentation/
    loggers/                       <- ConsoleLogger (normal/verbose/quiet/JSON)
    presenters/                    <- CheckPresenter, ViewPresenter
    renderers/                     <- table, bar, summary
    themes/                        <- dark, light, minimal + ThemeManager
    formatters/                    <- ScoreFormatter, DateFormatter

  shared/
    constants/
    utils/
      http_helper.dart             <- Dio builder + RetryInterceptor + LoggingInterceptor
      pool_manager.dart            <- concurrency-bounded task pool
    app_info.dart
```

---

## Key Design Decisions

### Manual constructor injection

There is no service locator, `GetIt`, or any DI framework. `bin/cura.dart`
constructs every object explicitly in seven phases:

1. **Config** — load YAML configuration hierarchy
2. **Infrastructure** — build HTTP client, API clients, initialise JSON cache
3. **Domain** — wire use cases with aggregator and score calculator
4. **Presentation** — create logger, error handler, presenters
5. **Application** — create command objects
6. **Runner** — build `CommandRunner` and register commands
7. **Execute** — run the command, then clean up in `finally`

This makes the full dependency graph visible at a glance and guarantees that
every resource (HTTP client, concurrency pool) is closed in `_cleanup`
regardless of success or failure.

---

### Ports & Adapters

The domain layer declares **port interfaces** and never references concrete
infrastructure types:

```dart
// domain/ports/package_data_aggregator.dart
abstract class PackageDataAggregator {
  Future<AggregatedPackageData> fetchAll(List<String> names);
  Stream<PackageResult> fetchMany(List<String> names);
  Future<void> dispose();
}
```

The infrastructure layer provides concrete **adapters**:

- `MultiApiAggregator` — Facade that calls pub.dev, GitHub, and OSV.dev in
  parallel, bounded by `PoolManager`
- `CachedAggregator` — Decorator that wraps `MultiApiAggregator` and consults
  the JSON file cache before making any network call

---

### Decorator — CachedAggregator

```text
CachedAggregator            <- outer decorator (cache layer)
  └─ MultiApiAggregator     <- inner facade   (API layer)
       ├─ PubDevApiClient
       ├─ GitHubApiClient
       └─ OsvApiClient
```

`CachedAggregator` intercepts every `fetchAll` / `fetchMany` call:

1. Checks `JsonFileSystemCache` for a non-expired `.json` file
2. Cache hit: returns deserialized data immediately
3. Cache miss: delegates to `MultiApiAggregator`, caches the result, returns it

Swapping the underlying aggregator requires no changes to the domain or
application layers.

---

### Facade — MultiApiAggregator

`MultiApiAggregator` hides the complexity of three separate APIs behind the
single `PackageDataAggregator` port. It uses `PoolManager` to bound concurrency
(default: 5 simultaneous requests) so large projects do not hammer the APIs.

---

### Strategy Pattern — Scoring Engine

The scoring engine decomposes `CalculateScore` into eight single-responsibility
classes wired together at construction time:

```text
CalculateScore (implements ScoreCalculator)
  ├─ VitalityDimension          (implements ScoringDimension)
  ├─ TechnicalHealthDimension   (implements ScoringDimension)
  ├─ TrustDimension             (implements ScoringDimension)
  ├─ MaintenanceDimension       (implements ScoringDimension)
  ├─ PenaltyEvaluator
  ├─ RedFlagDetector
  └─ RecommendationEngine
```

All components receive a **`ScoringInput` record** — an immutable snapshot of
`PackageInfo`, `GitHubMetrics?`, and `List<Vulnerability>`:

```dart
typedef ScoringInput = ({
  PackageInfo package,
  GitHubMetrics? github,
  List<Vulnerability> vulnerabilities,
});
```

Using a Dart record eliminates the need to mock complex objects in dimension
unit tests — you construct the record inline with exactly the fields you need.

**Adding a new dimension** requires only implementing `ScoringDimension` and
injecting it via `CalculateScore.withDimensions()`. The orchestrator and all
other dimensions remain unchanged (Open/Closed Principle).

---

### Strong Typing — RedFlag, Recommendation, Grade

Qualitative signals are typed, not plain strings:

| Old (fragile) | New (type-safe) |
|---|---|
| `List<String> redFlags` | `List<RedFlag>` (sealed class, 12 subtypes) |
| `flags.any((f) => f.contains('No release'))` | `flags.any((f) => f is StalePackageFlag)` |
| `List<String> recommendations` | `List<Recommendation>` with `RecommendationLevel` |
| `grade: 'A+'` (String) | `grade: Grade.aPlus` (enum with `.label`) |

Each `RedFlag` subtype carries its own structured data (e.g.
`StalePackageFlag(months: 18)`) and a typed `severity` (info / warning /
critical), enabling the presentation layer to render colour, icons, and sort
order without parsing message strings.

---

### Trusted Publisher Floor

Trusted-publisher packages (e.g. `dart.dev`, `flutter.dev`) receive a
**score floor of 70** — `total.clamp(70, 100)` instead of an automatic
perfect score. This means:

- A stale or unlicensed official package **can still score below 80** and
  will show warnings.
- Red flags are **always evaluated** for trusted packages.
- The zero-score overrides (discontinued, critical CVE) **take precedence**
  over the floor.

---

### Sealed result types

The domain layer uses sealed classes for discriminated unions, forcing callers
to handle all cases and preventing silent error swallowing:

```dart
sealed class Result<T> {
  const factory Result.success(T value)           = Success<T>;
  const factory Result.failure(CuraException err) = Failure<T>;
}

sealed class PackageResult {
  const factory PackageResult.success({...}) = PackageSuccess;
  const factory PackageResult.failure(...)   = PackageFailure;
}
```

---

### JsonFileSystemCache

`JsonFileSystemCache` is a stateless, dependency-free cache store backed by
plain files under `~/.cura/cache/`. It requires no native libraries and holds
no persistent connection, so no explicit disposal is needed.

Every write uses the **write-then-rename** pattern for atomicity, and every
read/write method is fail-safe: any `FileSystemException` is silently swallowed
and treated as a cache miss, so the CLI never crashes due to a degraded cache.

---

## Error Handling

Errors are rooted at `CuraException` and propagate upward:

```text
Infrastructure  ->  NetworkException / PackageNotFoundException / RateLimitException
Domain          ->  propagated or wrapped in Result<T> / PackageResult
Application     ->  command returns exit code 1
Presentation    ->  ErrorHandler formats the message for the user
```

---

## Testing

```text
test/
  unit/          <- 70 % -- business logic, scoring, value objects
  integration/   <- 20 % -- API client contracts
  e2e/           <- 10 % -- CLI end-to-end scenarios
```

Target coverage: >= 80 %.

---

## Related

- [Development guide](development.md) — local setup and test commands
- [API integration](api-integration.md) — how external APIs are called
- [Caching](caching.md) — JSON file cache internals
