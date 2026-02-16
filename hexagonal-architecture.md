cura/
├── bin/
│   └── cura.dart                           # Entry point CLI + DI bootstrap
│
├── lib/
│   ├── cura_cli.dart                       # Public exports (API du package)
│   │
│   └── src/
│       │
│       ├── domain/                         # Business Rules (Pure Dart, 0 dépendances externes)
│       │   ├── entities/                   # Modèles métier immuables
│       │   │   ├── package_info.dart       # Entité Package (sans Freezed ici)
│       │   │   ├── score.dart              # Entité Score
│       │   │   ├── vulnerability.dart      # Entité Vulnérabilité
│       │   │   ├── health_metrics.dart     # Métriques de santé
│       │   │   └── suggestion.dart         # Suggestion d'alternative
│       │   │
│       │   ├── value_objects/              # Domain primitives (validation)
│       │   │   ├── result.dart             # Result<T> Pattern (Success/Failure)
│       │   │   ├── package_name.dart       # ValueObject: nom validé
│       │   │   ├── score_value.dart        # ValueObject: score 0-100
│       │   │   ├── version.dart            # ValueObject: semantic version
│       │   │   └── grade.dart              # ValueObject: A+, A, B, C, D, F
│       │   │
│       │   ├── ports/                      # Interfaces (contrats abstraits)
│       │   │   ├── package_provider.dart   # Port: récupération packages
│       │   │   ├── cache_repository.dart   # Port: cache local
│       │   │   ├── config_repository.dart  # Port: configuration
│       │   │   └── vulnerability_provider.dart # Port: CVE data
│       │   │
│       │   ├── usecases/                   # Use Cases (1 classe = 1 action métier)
│       │   │   ├── scan_packages.dart      # UC: Scanner tous les packages
│       │   │   ├── view_package.dart       # UC: Voir détails d'un package
│       │   │   ├── check_health.dart       # UC: Vérifier santé (CI/CD)
│       │   │   ├── suggest_alternatives.dart # UC: Suggérer alternatives
│       │   │   └── calculate_score.dart    # UC: Calculer score (scoring logic)
│       │   │
│       │   └── exceptions/                 # Domain exceptions
│       │       ├── package_provider_error.dart
│       │       ├── cache_error.dart
│       │       └── config_error.dart
│       │
│       ├── application/                    # Orchestration (Commands + DTOs)
│       │   ├── commands/                   # Implémentation des commandes CLI
│       │   │   ├── base/
│       │   │   │   └── base_command.dart   # Classe de base (optionnelle)
│       │   │   │
│       │   │   ├── scan_command.dart       # cura scan
│       │   │   ├── view_command.dart       # cura view <package>
│       │   │   ├── check_command.dart      # cura check (CI/CD)
│       │   │   └── config/                 # Sous-commandes config
│       │   │       ├── config_command.dart # cura config
│       │   │       ├── config_show.dart    # cura config show
│       │   │       ├── config_set.dart     # cura config set
│       │   │       ├── config_get.dart     # cura config get
│       │   │       ├── config_init.dart    # cura config init
│       │   │       └── config_edit.dart    # cura config edit
│       │   │
│       │   └── dto/                        # Data Transfer Objects (cross-layer)
│       │       ├── scan_request.dart       # Input DTO pour ScanPackages
│       │       ├── scan_response.dart      # Output DTO
│       │       ├── view_request.dart
│       │       ├── view_response.dart
│       │       ├── check_request.dart
│       │       └── check_response.dart
│       │
│       ├── infrastructure/                 # Adapters (implémentations concrètes)
│       │   │
│       │   ├── providers/                  # Implémentations des Ports
│       │   │   ├── pooled_package_provider.dart    # Pool-based provider
│       │   │   ├── cached_package_provider.dart    # Cache decorator
│       │   │   └── osv_vulnerability_provider.dart # OSV.dev adapter
│       │   │
│       │   ├── repositories/               # Implémentations Repository
│       │   │   ├── sqlite_cache_repository.dart    # Cache SQLite
│       │   │   ├── yaml_config_repository.dart     # Config YAML
│       │   │   └── json_config_repository.dart     # Config JSON (backup)
│       │   │
│       │   ├── api/                        # Clients HTTP (bas niveau)
│       │   │   ├── clients/
│       │   │   │   ├── pub_dev_client.dart         # Client pub.dev API
│       │   │   │   ├── github_client.dart          # Client GitHub API
│       │   │   │   └── osv_client.dart             # Client OSV.dev API
│       │   │   │
│       │   │   ├── dto/                    # DTOs spécifiques API (mapping)
│       │   │   │   ├── pub_dev_response.dart
│       │   │   │   ├── github_response.dart
│       │   │   │   └── osv_response.dart
│       │   │   │
│       │   │   └── interceptors/          # Dio interceptors
│       │   │       ├── retry_interceptor.dart      # Retry logic
│       │   │       └── logging_interceptor.dart    # HTTP logging
│       │   │
│       │   ├── cache/                      # Gestion cache bas niveau
│       │   │   ├── models/
│       │   │   │   └── cached_entry.dart   # Modèle d'entrée cachée
│       │   │   ├── database/
│       │   │   │   └── cache_database.dart # SQLite setup
│       │   │   └── strategies/
│       │   │       └── ttl_strategy.dart   # Stratégie TTL
│       │   │
│       │   ├── config/                     # Gestion configuration
│       │   │   ├── models/
│       │   │   │   ├── cura_config.dart    # Modèle config (Freezed)
│       │   │   │   └── config_defaults.dart # Valeurs par défaut
│       │   │   ├── loaders/
│       │   │   │   ├── yaml_loader.dart
│       │   │   │   └── env_loader.dart     # Variables d'environnement
│       │   │   └── validators/
│       │   │       └── config_validator.dart # Validation config
│       │   │
│       │   └── utils/                      # Utils infrastructure
│       │       ├── pool_manager.dart       # Gestion du Pool
│       │       ├── rate_limiter.dart       # Rate limiting (Token Bucket)
│       │       └── http_helper.dart        # Helpers HTTP
│       │
│       ├── presentation/                   # UI Layer (CLI uniquement pour v1)
│       │   │
│       │   ├── cli/                        # Tous les éléments CLI
│       │   │   │
│       │   │   ├── presenters/             # Presenters (format output)
│       │   │   │   ├── scan_presenter.dart
│       │   │   │   ├── view_presenter.dart
│       │   │   │   ├── check_presenter.dart
│       │   │   │   └── config_presenter.dart
│       │   │   │
│       │   │   ├── renderers/              # Renderers (composants UI)
│       │   │   │   ├── table_renderer.dart         # Tables ASCII
│       │   │   │   ├── progress_renderer.dart      # Barres de progression
│       │   │   │   ├── summary_renderer.dart       # Résumés
│       │   │   │   ├── header_renderer.dart        # Headers stylisés
│       │   │   │   └── chart_renderer.dart         # Mini-charts ASCII
│       │   │   │
│       │   │   ├── formatters/             # Formatters (données → texte)
│       │   │   │   ├── score_formatter.dart        # 85 → "85/100 (A)"
│       │   │   │   ├── date_formatter.dart         # DateTime → "3 days ago"
│       │   │   │   ├── number_formatter.dart       # 1500 → "1.5K"
│       │   │   │   └── duration_formatter.dart     # Duration → "2m 30s"
│       │   │   │
│       │   │   ├── themes/                 # Système de thèmes
│       │   │   │   ├── theme.dart          # Interface Theme
│       │   │   │   ├── theme_manager.dart  # Singleton ThemeManager
│       │   │   │   ├── dark_theme.dart
│       │   │   │   ├── light_theme.dart
│       │   │   │   ├── minimal_theme.dart  # Pour CI/CD
│       │   │   │   └── dracula_theme.dart
│       │   │   │
│       │   │   ├── widgets/                # Composants réutilisables CLI
│       │   │   │   ├── spinner.dart        # Spinner animé
│       │   │   │   ├── progress_bar.dart   # [████░░░░] 50%
│       │   │   │   ├── badge.dart          # [A+] [WARNING]
│       │   │   │   ├── box.dart            # Boîtes encadrées
│       │   │   │   └── list.dart           # Listes stylisées
│       │   │   │
│       │   │   └── loggers/                # Loggers spécialisés
│       │   │       ├── base_logger.dart    # Interface logger
│       │   │       ├── console_logger.dart # Logger normal
│       │   │       ├── verbose_logger.dart # Logger verbose
│       │   │       ├── quiet_logger.dart   # Logger minimal
│       │   │       └── json_logger.dart    # Logger JSON (CI/CD)
│       │   │
│       │   └── models/                     # ViewModels (si nécessaire)
│       │       └── package_view_model.dart
│       │
│       └── shared/                         # Code partagé entre layers
│           ├── extensions/                 # Extensions Dart
│           │   ├── string_extensions.dart
│           │   ├── list_extensions.dart
│           │   ├── datetime_extensions.dart
│           │   └── result_extensions.dart
│           │
│           ├── utils/                      # Utilitaires génériques
│           │   ├── pubspec_parser.dart     # Parser pubspec.yaml
│           │   ├── file_helper.dart        # Helpers fichiers
│           │   └── platform_helper.dart    # Helpers plateforme
│           │
│           └── constants/                  # Constantes globales
│               ├── api_constants.dart      # URLs API, timeouts
│               ├── cache_constants.dart    # TTLs, max size
│               └── app_constants.dart      # Version, nom, etc.
│
├── test/                                   # Tests (miroir de lib/src/)
│   ├── unit/                               # Tests unitaires
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── package_info_test.dart
│   │   │   │   └── score_test.dart
│   │   │   ├── value_objects/
│   │   │   │   ├── result_test.dart
│   │   │   │   └── package_name_test.dart
│   │   │   └── usecases/
│   │   │       ├── scan_packages_test.dart
│   │   │       └── calculate_score_test.dart
│   │   │
│   │   ├── infrastructure/
│   │   │   ├── providers/
│   │   │   │   ├── pooled_package_provider_test.dart
│   │   │   │   └── cached_package_provider_test.dart
│   │   │   └── repositories/
│   │   │       └── sqlite_cache_repository_test.dart
│   │   │
│   │   └── presentation/
│   │       └── cli/
│   │           ├── formatters/
│   │           │   └── score_formatter_test.dart
│   │           └── renderers/
│   │               └── table_renderer_test.dart
│   │
│   ├── integration/                        # Tests d'intégration
│   │   ├── api_integration_test.dart       # Tests API réels
│   │   ├── cache_integration_test.dart     # Tests cache + API
│   │   └── e2e_scan_test.dart              # Test scan complet
│   │
│   ├── e2e/                                # Tests end-to-end
│   │   ├── cli_test.dart                   # Tests CLI complets
│   │   └── ci_cd_test.dart                 # Tests scénarios CI/CD
│   │
│   ├── fixtures/                           # Données de test
│   │   ├── pubspec_samples/
│   │   │   ├── valid_pubspec.yaml
│   │   │   ├── invalid_pubspec.yaml
│   │   │   └── large_pubspec.yaml
│   │   ├── api_responses/
│   │   │   ├── pub_dev_dio_response.json
│   │   │   ├── github_flutter_response.json
│   │   │   └── osv_vulnerability_response.json
│   │   └── configs/
│   │       ├── default_config.yaml
│   │       └── custom_config.yaml
│   │
│   ├── mocks/                              # Mocks générés
│   │   └── mocks.dart                      # Mockito generated
│   │
│   └── helpers/                            # Test helpers
│       ├── test_logger.dart                # Logger pour tests
│       ├── test_config.dart                # Config pour tests
│       └── builders.dart                   # Test data builders
│
├── docs/                                   # Documentation
│   ├── architecture.md                     # Architecture overview
│   ├── scoring.md                          # Algorithme de scoring
│   ├── configuration.md                    # Guide configuration
│   ├── ci-cd.md                            # Guide CI/CD
│   ├── development.md                      # Guide développement
│   ├── api-integration.md                  # Guide API
│   └── diagrams/                           # Diagrammes
│       ├── architecture.puml
│       ├── data-flow.puml
│       └── sequence-scan.puml
│
├── examples/                               # Exemples d'utilisation
│   ├── basic_scan.dart
│   ├── custom_config.dart
│   ├── ci_cd_usage.dart
│   └── programmatic_usage.dart
│
├── scripts/                                # Scripts utilitaires
│   ├── build.sh                            # Build script
│   ├── test.sh                             # Test script
│   ├── coverage.sh                         # Coverage script
│   ├── publish.sh                          # Publish script
│   └── generate.sh                         # Code generation
│
├── .github/                                # GitHub workflows
│   ├── workflows/
│   │   ├── ci.yml                          # CI pipeline
│   │   ├── release.yml                     # Release automation
│   │   └── codeql.yml                      # Security scanning
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   └── pull_request_template.md
│
├── .vscode/                                # VS Code config
│   ├── launch.json                         # Debug config
│   ├── settings.json                       # Workspace settings
│   └── extensions.json                     # Recommended extensions
│
├── pubspec.yaml                            # Dependencies
├── pubspec.lock                            # Lock file
├── analysis_options.yaml                   # Linter rules
├── build.yaml                              # build_runner config
├── .gitignore
├── .env.example                            # Example env vars
├── README.md                               # Main README
├── CHANGELOG.md                            # Version history
├── LICENSE                                 # MIT License
└── CONTRIBUTING.md                         # Contribution guide

Explication des Choix Architecturaux
Domain Layer (Pur Dart)

✅ Aucune dépendance sur Infrastructure
✅ Entities = modèles immuables (pas forcément Freezed)
✅ Value Objects = validation + encapsulation
✅ Ports = interfaces abstraites (contracts)
✅ Use Cases = logique métier pure

Application Layer (Orchestration)

✅ Commands = pont entre CLI et Use Cases
✅ DTOs = transfert de données cross-layer
✅ Pas de logique métier (délégation uniquement)

Infrastructure Layer (Adapters)

✅ Providers = implémentations des Ports
✅ API Clients = bas niveau HTTP
✅ Repositories = stockage (cache, config)
✅ Décorateurs (Cache, Rate Limiting) séparés

Presentation Layer (CLI)

✅ Presenters = orchestration de rendu
✅ Renderers = composants UI réutilisables
✅ Formatters = transformation données → texte
✅ Themes = système de thèmes swappables

Dépendances entre Layers
┌─────────────────────────────────────────┐
│  Presentation (CLI)                     │
│  ↓ dépend de                            │
│  Application (Commands)                 │
│  ↓ dépend de                            │
│  Domain (Use Cases, Ports)              │
│  ↑ implémenté par                       │
│  Infrastructure (Adapters)              │
└─────────────────────────────────────────┘

Règles de dépendance :

✅ Presentation → Application → Domain
✅ Infrastructure → Domain (implémente Ports)
❌ Domain ne dépend de RIEN
❌ Application ne dépend PAS de Infrastructure
