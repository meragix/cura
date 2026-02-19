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
import 'package:cura/src/presentation/cli/loggers/logger_factory.dart';
import 'package:cura/src/presentation/cli/presenters/check_presenter.dart';
import 'package:cura/src/presentation/cli/presenters/view_presenter.dart';
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
    // Le code gère déjà gracefully (token optionnel)
    // Mais avertir l'utilisateur si absent :
    // if (config.githubToken == null) {
    //   logger.warn('! GitHub token not set. Rate limit: 60 req/h');
    //   logger.info('  Set token: cura config set github_token YOUR_TOKEN');
    //   logger.info('');
    // }

    final exitCode = await runner.run(arguments) ?? 0;
    exit(exitCode);
  } catch (e) {
    logger.error('Unhandled error: $e');
    exit(1);
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
  check       Check and audit all packages in pubspec.yaml
  view       View detailed information about a package
  suggest    Suggest better alternatives for packages
  update     Update alternatives database from remote
  config     Manage configuration
  cache      Show cache information

Global options:
  -h, --help       Show this help message
  -v, --version    Print version information
  --verbose        Enable verbose logging

Examples:
  cura check                   # Scan current project
  cura view dio                # View dio package details
  cura check --min-score 80    # CI/CD health check
  cura suggest http            # Suggest alternatives for http
  cura update                  # Update alternatives database

For more information, visit: ${AppInfo.homepage}
''');
}
