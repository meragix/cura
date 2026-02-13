import 'package:cura/src/presentation/themes/theme.dart';
import 'package:cura/src/presentation/themes/theme_logger.dart';
import 'package:cura/src/presentation/themes/theme_manager.dart';

class CommandContext {
  final ThemedLogger logger;

  CommandContext({
    bool verbose = false,
    bool json = false,
  }) : logger = ThemedLogger();

  // Accès au thème
  CuraTheme get theme => ThemeManager.current;
}
