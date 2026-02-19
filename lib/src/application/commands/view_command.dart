import 'package:args/command_runner.dart';
import 'package:cura/src/domain/usecases/view_package_details.dart';

import 'package:cura/src/presentation/cli/presenters/view_presenter.dart';

/// Command : cura view <package>
///
/// Affiche les détails complets d'un package
class ViewCommand extends Command<int> {
  final ViewPackageDetails _viewUseCase;
  final ViewPresenter _presenter;

  ViewCommand({
    required ViewPackageDetails viewUseCase,
    required ViewPresenter presenter,
  })  : _viewUseCase = viewUseCase,
        _presenter = presenter {
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Show detailed breakdown',
      defaultsTo: false,
    );
  }

  @override
  String get name => 'view';

  @override
  String get description => 'View detailed information about a package';

  @override
  String get invocation => 'cura view <package>';

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

    // Fetch package details
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
