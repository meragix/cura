import 'package:args/command_runner.dart';
import 'package:cura/src/domain/usecases/view_package_details.dart';
import 'package:cura/src/domain/value_objects/result.dart';

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

    _presenter.showHeader(packageName);

    // Fetch package details
    final result = await _viewUseCase.execute(packageName);

    switch (result) {
      case Success(:final value):
        _presenter.showPackageDetails(value, verbose: verbose);
        return 0;
      case Failure(:final error):
        _presenter.showError(error.toString());
        return 1;
    }
  }
}
