import 'package:cura/src/domain/models/package_health.dart';
import 'package:mason_logger/src/mason_logger.dart';

class TableFormatter {
  static displayListed(List<PackageHealth> results, Logger logger) {
    logger.info('');
    logger.info('🔍 Running health check...\n');
    logger.info('');
  }

  static displayDetailed(PackageHealth health, Logger logger) {
    final daysAgo = DateTime.now().difference(health.info.published).inDays;

    logger.info('Package: ${health.info.name} (${health.info.version})');
    logger.info('Score: ${health.score.total}/100');
    logger.info('Last updat: $daysAgo days ago');
    logger.info('Publisher: ${health.info.publisherId}');
  }
}
