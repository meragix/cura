import 'package:args/command_runner.dart';
import 'package:cura/src/domain/usecases/view_package_details.dart';

import 'package:cura/src/presentation/cli/presenters/view_presenter.dart';

/// CLI command that displays a rich health report for a single pub.dev package.
///
/// `cura view <package>` fetches aggregated data from pub.dev, GitHub, and
/// OSV.dev, computes a composite health [Score], and renders a structured
/// report covering score breakdown, key metrics, GitHub activity,
/// vulnerabilities, and an overall recommendation.
///
/// The package name is passed as a positional argument. Exactly one argument
/// is expected; anything beyond the first is ignored.
///
/// ## Options
///
/// | Flag        | Short | Default | Description                                         |
/// |-------------|-------|---------|-----------------------------------------------------|
/// | `--verbose` | `-v`  | `false` | Show extended score breakdown and additional details.|
///
/// ## Exit codes
///
/// | Code | Meaning                                                     |
/// |------|-------------------------------------------------------------|
/// | `0`  | Package data retrieved and report rendered successfully.    |
/// | `1`  | Package not found, network error, or no argument supplied.  |
///
/// ## Examples
///
/// ```sh
/// # Inspect the dio package
/// cura view dio
///
/// # Show the full score breakdown for provider
/// cura view provider --verbose
/// ```
class ViewCommand extends Command<int> {
  /// Use case that fetches, scores, and returns a [PackageAuditResult] for a
  /// single package.
  final ViewPackageDetails _viewUseCase;

  /// Presenter that renders the package report to the terminal.
  final ViewPresenter _presenter;

  /// The canonical CLI invocation shown in usage / help text.
  @override
  String get invocation => 'cura view <package>';

  @override
  String get name => 'view';

  @override
  String get description =>
      'Show a detailed health report for a single pub.dev package.';

  /// Creates a [ViewCommand].
  ///
  /// - [viewUseCase] orchestrates data fetching and score computation.
  /// - [presenter] handles all terminal rendering.
  ViewCommand({
    required ViewPackageDetails viewUseCase,
    required ViewPresenter presenter,
  })  : _viewUseCase = viewUseCase,
        _presenter = presenter {
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Show an extended score breakdown and additional package details.',
      defaultsTo: false,
    );
  }

  /// Fetches package data and renders the health report.
  ///
  /// Execution follows three steps:
  ///
  /// 1. **Validate** — ensures a package name was provided as a positional
  ///    argument; exits with code `1` and a usage hint if it is missing.
  /// 2. **Fetch** — delegates to [ViewPackageDetails.execute], which calls the
  ///    aggregator and scorer; an animated progress indicator is shown while
  ///    the request is in flight.
  /// 3. **Render** — passes the [PackageAuditResult] to [ViewPresenter]; when
  ///    `--verbose` is active, extended score dimensions are included.
  ///
  /// Returns `0` on success, `1` on any error.
  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      _presenter.showError('Missing package name');
      _presenter.showUsage(invocation);
      return 1;
    }

    final packageName = argResults!.rest.first;
    final verbose = argResults!['verbose'] as bool;

    final progress = _presenter.showProgressHeader(packageName);

    final auditResult = await _viewUseCase.execute(packageName);

    if (auditResult.isFailure) {
      _presenter.showError(auditResult.errorOrNull.toString());
      return 1;
    }

    final audit = auditResult.valueOrNull!;

    progress.complete('Analysis complete');

    _presenter.showPackageDetails(audit, verbose: verbose);
    return 0;
  }
}
