# Architecture Overview

Cura follows **Hexagonal Architecture** (Ports & Adapters) with strict layering.
The domain layer has zero dependencies on external packages or infrastructure;
all I/O flows through explicit port interfaces implemented by infrastructure
adapters.

---

## Layer Diagram

```
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
│  API clients, SQLite cache, YAML config repository         │
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

```
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
      database/cache_database.dart <- SQLite singleton
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
2. **Infrastructure** — build HTTP client, API clients, open SQLite
3. **Domain** — wire use cases with aggregator and score calculator
4. **Presentation** — create logger, error handler, presenters
5. **Application** — create command objects
6. **Runner** — build `CommandRunner` and register commands
7. **Execute** — run the command, then clean up in `finally`

This makes the full dependency graph visible at a glance and guarantees that
every resource (HTTP client, database connection) is closed in `_cleanup`
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
  the SQLite cache before making any network call

---

### Decorator — CachedAggregator

```
CachedAggregator            <- outer decorator (cache layer)
  └─ MultiApiAggregator     <- inner facade   (API layer)
       ├─ PubDevApiClient
       ├─ GitHubApiClient
       └─ OsvApiClient
```

`CachedAggregator` intercepts every `fetchAll` / `fetchMany` call:

1. Checks `CacheDatabase` for a non-expired entry
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

### CacheDatabase singleton

`CacheDatabase` is a lazy singleton backed by `sqflite_common_ffi`. A
`Future<Database>? _initFuture` guard prevents the double-init race condition
that would occur if two concurrent callers both read `_initFuture == null`:

```dart
static Future<Database> get instance {
  _initFuture ??= _initDatabase();
  return _initFuture!;
}
```

`close()` resets `_initFuture` to `null` so the next `get instance` call
re-opens the database cleanly.

---

## Error Handling

Errors are rooted at `CuraException` and propagate upward:

```
Infrastructure  ->  NetworkException / PackageNotFoundException / RateLimitException
Domain          ->  propagated or wrapped in Result<T> / PackageResult
Application     ->  command returns exit code 1
Presentation    ->  ErrorHandler formats the message for the user
```

---

## Testing

```
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
- [Caching](caching.md) — SQLite cache internals
