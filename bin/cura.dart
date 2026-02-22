import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cura/src/application/commands/check_command.dart';
import 'package:cura/src/application/commands/config/config_command.dart';
import 'package:cura/src/application/commands/version_command.dart';
import 'package:cura/src/application/commands/view_command.dart';
import 'package:cura/src/domain/ports/cache_repository.dart';
import 'package:cura/src/domain/ports/config_repository.dart';
import 'package:cura/src/domain/ports/package_data_aggregator.dart';
import 'package:cura/src/domain/usecases/calculate_score.dart';
import 'package:cura/src/domain/usecases/check_packages_usecase.dart';
import 'package:cura/src/domain/usecases/view_package_details.dart';
import 'package:cura/src/infrastructure/aggregators/cached_aggregator.dart';
import 'package:cura/src/infrastructure/aggregators/multi_api_aggregator.dart';
import 'package:cura/src/infrastructure/api/clients/github_client.dart';
import 'package:cura/src/infrastructure/api/clients/osv_client.dart';
import 'package:cura/src/infrastructure/api/clients/pub_dev_client.dart';
import 'package:cura/src/infrastructure/api/interceptors/logging_interceptor.dart';
import 'package:cura/src/infrastructure/api/interceptors/retry_interceptor.dart';
import 'package:cura/src/infrastructure/respositories/sqlite_cache_repository.dart';
import 'package:cura/src/infrastructure/respositories/yaml_config_repository.dart';
import 'package:cura/src/presentation/error_handler.dart';
import 'package:cura/src/presentation/loggers/logger_factory.dart';
import 'package:cura/src/presentation/presenters/check_presenter.dart';
import 'package:cura/src/presentation/presenters/view_presenter.dart';
import 'package:cura/src/presentation/themes/theme_manager.dart';
import 'package:cura/src/shared/app_info.dart';
import 'package:cura/src/shared/constants/app_constants.dart';
import 'package:dio/dio.dart';

/// Composition Root: Single entry point for dependency graph construction.
///
/// Principles:
/// - Pure Constructor Injection (No Service Locator/GetIt).
/// - Explicit Composition (Visible Decorator patterns).
/// - Lifecycle management (Resource cleanup).
/// - Centralized configuration.
Future<void> main(List<String> arguments) async {
  if (arguments.contains('--version') || arguments.contains('-v')) {
    final version = await AppInfo.getFullVersion();
    print(version);
    exit(0);
  }

  if (arguments.contains('--help') || arguments.contains('-h')) {
    await _printHelp();
    exit(0);
  }

  // ===========================================================================
  // PHASE 1 : CONFIGURATION & INITIALIZATION
  // ===========================================================================

  final configRepo = await _initializeConfiguration();
  final config = await configRepo.load();

  // Apply the theme before any UI
  ThemeManager.setTheme(config.theme);

  // ===========================================================================
  // PHASE 2 : INFRASTRUCTURE LAYER (Adapters externes)
  // ===========================================================================

  // HTTP Client avec interceptors
  final httpClient = _buildHttpClient(
    timeout: Duration(seconds: config.timeoutSeconds),
    verbose: config.verboseLogging,
  );

  // API Clients
  final pubDevClient = PubDevApiClient(httpClient);
  final githubClient = GitHubApiClient(httpClient, token: config.githubToken);
  final osvClient = OsvApiClient(httpClient);

  // Cache Repository
  final cacheRepo = await _initializeCache(
    maxAgeHours: config.cacheMaxAgeHours,
  );

  // ⭐ AGGREGATOR (remplace les 3 providers séparés)
  final aggregator = CachedAggregator(
    delegate: MultiApiAggregator(
      pubDevClient: pubDevClient,
      githubClient: githubClient,
      osvClient: osvClient,
      maxConcurrency: config.maxConcurrency,
    ),
    cache: cacheRepo,
  );

  // ===========================================================================
  // PHASE 3 : DOMAIN LAYER (Use Cases)
  // ===========================================================================

  final scoreCalculator = CalculateScore(
    weights: config.scoreWeights,
  );

  final checkUseCase = CheckPackagesUsecase(
    aggregator: aggregator,
    scoreCalculator: scoreCalculator,
    minScore: config.minScore,
    failOnVulnerable: config.failOnVulnerable,
    failOnDiscontinued: config.failOnDiscontinued,
  );

  final viewUseCase = ViewPackageDetails(
    aggregator: aggregator,
    scoreCalculator: scoreCalculator,
  );

  // ===========================================================================
  // PHASE 4 : PRESENTATION LAYER (CLI)
  // ===========================================================================

  final logger = LoggerFactory.fromConfig(config);

  // ErrorHandler wraps the runner so every unhandled exception is formatted
  // with context-aware suggestions before the process exits.
  final errorHandler = ErrorHandler(logger);

  // Warn about missing GitHub token only for commands that call the GitHub API
  // and only when output is not suppressed.
  final _apiCommands = const {'check', 'view'};
  if (config.githubToken == null &&
      !logger.isQuiet &&
      arguments.isNotEmpty &&
      _apiCommands.contains(arguments.first)) {
    logger.warn('GitHub token not set — rate limited to 60 req/h');
    logger.muted('  Add one: cura config set github_token YOUR_TOKEN');
    logger.spacer();
  }

  final checkPresenter = CheckPresenter(
    logger: logger,
    showSuggestions: config.showSuggestions,
  );

  final viewPresenter = ViewPresenter(logger: logger);

  // ===========================================================================
  // PHASE 5 : APPLICATION LAYER (Commands)
  // ===========================================================================

  final checkCommand = CheckCommand(
    checkUseCase: checkUseCase,
    presenter: checkPresenter,
    ignoredPackages: config.ignoredPackages,
  );

  final viewCommand = ViewCommand(
    viewUseCase: viewUseCase,
    presenter: viewPresenter,
  );

  final configCommand = ConfigCommand(
    configRepository: configRepo,
  );

  final versionCommand = VersionCommand(logger: logger);

  // ===========================================================================
  // PHASE 6 : CLI RUNNER
  // ===========================================================================

  final runner = CommandRunner<int>(
    AppConstants.appName,
    AppConstants.appDescription,
  )
    ..addCommand(checkCommand)
    ..addCommand(viewCommand)
    ..addCommand(configCommand)
    ..addCommand(versionCommand);

  // ===========================================================================
  // PHASE 7 : EXECUTION & CLEANUP
  // ===========================================================================

  try {
    final exitCode = await errorHandler.handle(
      () async => await runner.run(arguments) ?? 0,
    );
    exit(exitCode);
  } finally {
    await _cleanup(
      httpClient: httpClient,
      cacheRepo: cacheRepo,
      aggregator: aggregator,
    );
  }
}

// =============================================================================
// FACTORY METHODS (Composition logic)
// =============================================================================

/// Build HTTP client avec interceptors configurés
Dio _buildHttpClient({
  required Duration timeout,
  required bool verbose,
}) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: timeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  // Interceptor : Retry automatique (3 tentatives)
  dio.interceptors.add(
    RetryInterceptor(
      dio: dio,
      maxRetries: 3,
      retryDelays: [
        Duration(milliseconds: 500),
        Duration(seconds: 1),
        Duration(seconds: 2),
      ],
    ),
  );

  // Interceptor : Logging (si verbose)
  if (verbose) {
    dio.interceptors.add(LoggingInterceptor());
  }

  return dio;
}

/// Initialize configuration repository
Future<ConfigRepository> _initializeConfiguration() async {
  final configRepo = YamlConfigRepository(
    globalConfigPath: _resolveGlobalConfigPath(),
    projectConfigPath: _resolveProjectConfigPath(),
  );

  // Create default configuration if it doesn't exist
  if (!await configRepo.exists()) {
    await configRepo.createDefault();
  }

  return configRepo;
}

/// Initialize cache repository
Future<CacheRepository> _initializeCache({
  required int maxAgeHours,
}) async {
  final cacheDir = _resolveCacheDirectory();
  await Directory(cacheDir).create(recursive: true);

  final cacheRepo = SqliteCacheRepository(
    databasePath: '$cacheDir/cura_cache.db',
    maxAgeHours: maxAgeHours,
  );

  await cacheRepo.initialize();

  return cacheRepo;
}

/// Cleanup des ressources
Future<void> _cleanup({
  required Dio httpClient,
  required CacheRepository cacheRepo,
  required PackageDataAggregator aggregator,
}) async {
  httpClient.close();

  if (cacheRepo is SqliteCacheRepository) {
    await cacheRepo.close();
  }

  await aggregator.dispose();
}

// =============================================================================
// PATH RESOLUTION (Platform-agnostic)
// =============================================================================

String _resolveGlobalConfigPath() {
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home == null) {
    throw StateError('Cannot resolve HOME directory');
  }
  return '$home/.cura/config.yaml';
}

String _resolveProjectConfigPath() {
  return '${Directory.current.path}/.cura/config.yaml';
}

String _resolveCacheDirectory() {
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home == null) {
    throw StateError('Cannot resolve HOME directory');
  }
  return '$home/.cura/cache';
}

/// Print custom help message
Future<void> _printHelp() async {
  final version = await AppInfo.getVersion();

  print('''
${AppInfo.name} v$version - ${AppInfo.description}

Usage: cura <command> [arguments]

Available commands:
  check       Audit all pub.dev packages listed in pubspec.yaml
  view        Show detailed health information for a single package
  config      Read and write cura configuration
  version     Print version information

Global options:
  -h, --help       Show this help message
  -v, --version    Print version information

Examples:
  cura check                          # Audit the current project
  cura check --dev-dependencies       # Include dev_dependencies
  cura check --min-score 80           # Fail below score 80 (CI/CD)
  cura view dio                       # Inspect the dio package
  cura config show                    # Display active configuration
  cura config set github_token TOKEN  # Set a GitHub API token

For more information, visit: ${AppInfo.homepage}
''');
}
