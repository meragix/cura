import 'package:cura/src/presentation/loggers/cura_logger.dart';
import 'package:cura/src/presentation/loggers/specialized/scan_logger.dart';
import 'package:cura/src/presentation/loggers/specialized/view_logger.dart';

class CommandContext {
  final CuraLogger logger;
  final bool verbose;
  final bool json;

  // Lazy loading des services
  ScanLogger? _scanLogger;
  ViewLogger? _viewLogger;

  CommandContext({
    required this.logger,
    required this.verbose,
    required this.json,
  });

  // Getters avec lazy loading
  ScanLogger get scanLogger => _scanLogger ??= ScanLogger(logger: logger);

  ViewLogger get viewLogger => _viewLogger ??= ViewLogger(logger: logger);
}
