import 'package:cura/src/domain/models/package_health.dart';
import 'package:cura/src/presentation/loggers/cura_logger.dart';
import 'package:cura/src/presentation/renderers/summary_renderer.dart';
import 'package:cura/src/presentation/renderers/table_renderer.dart';
import 'package:mason_logger/mason_logger.dart';

class ScanLogger {
  final CuraLogger _logger;
  final TableRenderer _tableRenderer;
  final SummaryRenderer _summaryRenderer;

  ScanLogger({
    required CuraLogger logger,
    TableRenderer? tableRenderer,
    SummaryRenderer? summaryRenderer,
  })  : _logger = logger,
        _tableRenderer = tableRenderer ?? TableRenderer(logger: logger),
        _summaryRenderer = summaryRenderer ?? SummaryRenderer(logger: logger);

  void printTable(List<PackageHealth> results) {
    _tableRenderer.render(results);
  }

  // void printResults(List<PackageHealth> results) {
  //   _tableRenderer.render(results);
  //   _summaryRenderer.render(results);
  // }

  void printCriticalIssues(List<PackageHealth> criticalPackages) {
    if (criticalPackages.isEmpty) return;

    _logger.info('');
    _logger.error('CRITICAL ISSUES (require action):');
    for (final pkg in criticalPackages) {
      _logger.error(
          '   ${red.wrap('✗')} ${styleBold.wrap(pkg.info.name)} (score: ${pkg.score.total})');
      for (final issue in pkg.score.redFlags) {
        _logger.error('     └─ $issue');
      }
      // if (pkg.score.recommendations.isNotEmpty) {
      //   logger.info('     └─ Recommendations: ${pkg.score.recommendations}');
      // }
    }
    _logger.info('');
  }
}
