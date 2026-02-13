# Architecture Overview

## System Architecture

Cura follows a **layered architecture** with clear separation of concerns:

```

┌─────────────────────────────────────────────┐
│           CLI Interface (bin/)              │
│  Entry point, argument parsing, routing    │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│      Presentation Layer (presentation/)     │
│  Loggers, Renderers, Formatters, Themes    │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│         Command Layer (commands/)           │
│  Scan, View, Check, Config commands        │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│         Core Layer (core/)                  │
│  Business Logic, Calculators, Services     │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│    Infrastructure Layer (infrastructure/)  │
│  API Clients, Cache, External Services     │
└─────────────────────────────────────────────┘

```

---

## Layer Details

### 1. CLI Interface

**Location:** `bin/cura.dart`

**Responsibilities:**

- Parse command-line arguments
- Load configuration (global + project)
- Initialize theme system
- Route to appropriate command

**Example:**

```dart
void main(List<String> arguments) async {
  // Load config
  final config = HierarchicalConfigManager.load();
  
  // Apply theme
  ThemeManager.setTheme(config.theme);
  
  // Create command runner
  final runner = CommandRunner('cura', 'Package health audit')
    ..addCommand(ScanCommand(config: config))
    ..addCommand(ViewCommand(config: config))
    ..addCommand(CheckCommand(config: config));
  
  await runner.run(arguments);
}
```

---

### 2. Presentation Layer

**Location:** `lib/src/presentation/`

**Responsibilities:**

- UI formatting and rendering
- Theme management
- Output generation (normal, verbose, JSON)

**Sub-layers:**

#### Loggers (`presentation/loggers/`)

```dart
// Base logger
abstract class CuraLogger {
  void info(String message);
  void success(String message);
  void error(String message);
}

// Specialized loggers
class ScanLogger {
  void printTable(List<PackageAnalysis> results);
  void printSummary(AnalysisSummary summary);
}
```

#### Renderers (`presentation/renderers/`)

```dart
class TableRenderer {
  void render(List<PackageAnalysis> data);
}

class SummaryRenderer {
  void render(AnalysisSummary summary);
}
```

#### Themes (`presentation/themes/`)

```dart
abstract class CuraTheme {
  AnsiCode get primary;
  AnsiCode get success;
  String get symbolSuccess;
}

class DarkTheme implements CuraTheme { }
class LightTheme implements CuraTheme { }
```

---

### 3. Command Layer

**Location:** `lib/src/commands/`

**Responsibilities:**

- Handle user commands
- Orchestrate business logic
- Format output via presentation layer

**Pattern:** Command Pattern

```dart
abstract class BaseCommand extends Command<int> {
  late final CommandContext context;
  
  @override
  Future<int> run() async {
    context = _buildContext();
    return await execute(context);
  }
  
  Future<int> execute(CommandContext context);
}

class ScanCommand extends BaseCommand {
  @override
  Future<int> execute(CommandContext context) async {
    // 1. Parse pubspec
    final packages = await _parsePubspec();
    
    // 2. Analyze packages (core layer)
    final results = await _analyzePackages(packages);
    
    // 3. Render results (presentation layer)
    context.scanLogger.printResults(results);
    
    return 0;
  }
}
```

---

### 4. Core Layer

**Location:** `lib/src/core/`

**Responsibilities:**

- Business logic
- Score calculation
- Data transformation

**Sub-modules:**

#### Models (`core/models/`)

```dart
@freezed
class CuraPackage with _$CuraPackage {
  const factory CuraPackage({
    required String name,
    required String version,
    required DateTime lastPublished,
    required HealthMetrics metrics,
  }) = _CuraPackage;
}
```

#### Calculators (`core/calculators/`)

```dart
class ScoreCalculator {
  static CuraScore calculate(CuraPackage package) {
    final vitality = _calculateVitality(package);
    final technicalHealth = _calculateTechnicalHealth(package);
    final trust = _calculateTrust(package);
    final maintenance = _calculateMaintenance(package);
    
    return CuraScore(
      total: vitality + technicalHealth + trust + maintenance,
      // ...
    );
  }
}
```

#### Services (`core/services/`)

```dart
class SuggestionService {
  Future<List<Alternative>> getSuggestions(String packageName) {
    // Load alternatives database
    // Validate suggestions
    // Return healthy alternatives
  }
}
```

---

### 5. Infrastructure Layer

**Location:** `lib/src/infrastructure/`

**Responsibilities:**

- External API communication
- Caching
- File system operations

**Sub-modules:**

#### API Clients (`infrastructure/api/`)

```dart
class PubDevClient {
  Future<PackageInfo> getPackageInfo(String name) async {
    final response = await _client.get(
      Uri.parse('https://pub.dev/api/packages/$name'),
    );
    return PackageInfo.fromJson(jsonDecode(response.body));
  }
}

class GitHubClient {
  Future<GitHubData> getRepoData(String owner, String repo) async {
    // Fetch from GitHub API
  }
}

class OsvClient {
  Future<List<Vulnerability>> getVulnerabilities(String pkg) async {
    // Fetch from OSV.dev
  }
}
```

#### Cache (`infrastructure/cache/`)

```dart
class LocalCache {
  Future<T?> get<T>(String key, T Function(Map) fromJson) {
    // Check SQLite cache
  }
  
  Future<void> set(String key, Map<String, dynamic> value) {
    // Store in SQLite
  }
}
```

---

## Data Flow

### Example: Scan Command

```
1. User runs: cura scan

2. CLI parses arguments
   → bin/cura.dart

3. ScanCommand.execute() called
   → commands/scan_command.dart
   
4. Parse pubspec.yaml
   → Read file system
   
5. For each package:
   a. Check cache
      → infrastructure/cache/local_cache.dart
   
   b. If cache miss:
      - Fetch from pub.dev
        → infrastructure/api/pub_dev_client.dart
      - Fetch from GitHub (if available)
        → infrastructure/api/github_client.dart
      - Check vulnerabilities
        → infrastructure/api/osv_client.dart
   
   c. Aggregate data
      → core/services/multi_api_service.dart
   
   d. Calculate score
      → core/calculators/score_calculator.dart
   
   e. Store in cache
      → infrastructure/cache/local_cache.dart

6. Get suggestions (if needed)
   → core/services/suggestion_service.dart

7. Format results
   → presentation/renderers/table_renderer.dart
   → presentation/renderers/summary_renderer.dart

8. Display output
   → presentation/loggers/scan_logger.dart

9. Return exit code
   → 0 (success) or 1 (failure)
```

---

## Design Patterns

### 1. Command Pattern

```dart
abstract class Command<T> {
  Future<T> run();
}

class ScanCommand extends Command<int> { }
class ViewCommand extends Command<int> { }
```

**Benefits:**

- Encapsulates requests as objects
- Easy to add new commands
- Supports undo/redo (future)

---

### 2. Factory Pattern

```dart
class CuraConfig {
  factory CuraConfig.fromYaml(YamlMap yaml) {
    // Parse and construct
  }
  
  factory CuraConfig.defaultConfig() {
    // Return defaults
  }
}
```

**Benefits:**

- Flexible object creation
- Encapsulates construction logic

---

### 3. Strategy Pattern (Themes)

```dart
abstract class CuraTheme {
  AnsiCode get primary;
}

class DarkTheme implements CuraTheme { }
class LightTheme implements CuraTheme { }

// Usage
ThemeManager.setTheme('dark');
final theme = ThemeManager.current; // Returns DarkTheme
```

**Benefits:**

- Swappable algorithms (themes)
- Open/Closed Principle

---

### 4. Facade Pattern (Multi-API)

```dart
class MultiApiFetcher {
  Future<AggregatedData> fetchPackageData(String name) {
    // Coordinates multiple API calls
    final [pubDev, github, osv] = await Future.wait([
      _pubDevClient.fetch(name),
      _githubClient.fetch(name),
      _osvClient.fetch(name),
    ]);
    
    return AggregatedData(
      pubDev: pubDev,
      github: github,
      osv: osv,
    );
  }
}
```

**Benefits:**

- Simplifies complex subsystems
- Single entry point

---

## Dependency Injection

### Manual DI via CommandContext

```dart
class CommandContext {
  final CuraLogger logger;
  
  // Lazy-loaded services
  ScanLogger? _scanLogger;
  ScoreCalculator? _calculator;
  
  CommandContext({required this.logger});
  
  ScanLogger get scanLogger => _scanLogger ??= ScanLogger(logger: logger);
  ScoreCalculator get calculator => _calculator ??= ScoreCalculator();
}

// Usage in commands
class ScanCommand extends BaseCommand {
  @override
  Future<int> execute(CommandContext context) async {
    context.scanLogger.printHeader();
    final score = context.calculator.calculate(package);
  }
}
```

**Benefits:**

- Testable (inject mocks)
- Lazy loading
- No external DI framework needed

---

## Error Handling Strategy

### Hierarchical Exceptions

```dart
// Base exception
abstract class CuraException implements Exception {
  final String message;
  final String? code;
  CuraException(this.message, {this.code});
}

// Specific exceptions
class PackageNotFoundException extends CuraException { }
class NetworkException extends CuraException { }
class RateLimitException extends CuraException { }
```

### Error Propagation

```
Infrastructure Layer
  └─ Throws specific exceptions (NetworkException)
        ↓
Core Layer
  └─ Catches and transforms if needed
        ↓
Command Layer
  └─ Catches and handles gracefully
        ↓
Presentation Layer
  └─ Formats error for display
```

---

## Testing Architecture

### Test Pyramid

```
        ┌────────────┐
        │  E2E Tests │  (10%)
        │  CLI Tests │
        └────────────┘
       ┌──────────────┐
       │ Integration  │  (20%)
       │    Tests     │
       └──────────────┘
    ┌──────────────────┐
    │   Unit Tests     │  (70%)
    │  Business Logic  │
    └──────────────────┘
```

### Test Structure

```
test/
├── unit/
│   ├── core/
│   │   ├── calculators/
│   │   │   └── score_calculator_test.dart
│   │   └── services/
│   ├── infrastructure/
│   └── presentation/
│
├── integration/
│   ├── api_integration_test.dart
│   └── cache_integration_test.dart
│
└── e2e/
    └── cli_test.dart
```

---

## Performance Considerations

### Caching Strategy

```dart
class CacheStrategy {
  Duration getTTL(PackageInfo info) {
    // Popular packages: shorter TTL (more updates expected)
    if (info.likes > 1000) return Duration(hours: 1);
    
    // Normal packages
    if (info.likes > 100) return Duration(hours: 6);
    
    // Unpopular packages: longer TTL
    return Duration(hours: 24);
  }
}
```

### Parallel Processing

```dart
// Analyze packages in parallel (batches of 5)
final chunks = _chunkList(packages, 5);
for (final chunk in chunks) {
  await Future.wait(
    chunk.map((pkg) => _analyzePackage(pkg)),
  );
}
```

### Rate Limiting

```dart
class RateLimiter {
  final Queue<DateTime> _requests = Queue();
  
  Future<void> acquire() async {
    _cleanup();
    if (_requests.length >= maxRequests) {
      final waitTime = window - DateTime.now().difference(_requests.first);
      await Future.delayed(waitTime);
    }
    _requests.add(DateTime.now());
  }
}
```

---

## Future Architecture Plans

### v2.0 (Backend Service)

```
┌─────────────┐
│  CLI Client │
└──────┬──────┘
       │ HTTP
       ↓
┌─────────────┐      ┌──────────────┐
│   Backend   │ ←──→ │  PostgreSQL  │
│  Dart Frog  │      │   Database   │
└─────────────┘      └──────────────┘
       ↓
┌─────────────┐
│  Web UI     │
│   (Astro)   │
└─────────────┘
```

**Benefits:**

- Centralized caching
- Real-time updates
- Community data aggregation

---

## Related Documents

- [Development Setup](development.md)
- [Contributing Guide](../CONTRIBUTING.md)
- [Testing Guide](testing.md)
