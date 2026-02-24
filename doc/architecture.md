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
    entities/                     <- PackageInfo, Score, Vulnerability, ...
    value_objects/                 <- Score (0-100), Grade, PackageName, Result<T>
    ports/                         <- abstract interfaces (contracts)
      package_data_aggregator.dart
      config_repository.dart
    usecases/                      <- CalculateScore, CheckPackagesUsecase,
                                      ViewPackageDetails
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
