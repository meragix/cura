import 'package:cura/src/presentation/themes/theme.dart';
import 'package:mason_logger/mason_logger.dart';

class MinimalTheme implements CuraTheme {
  @override
  final String name = 'minimal';

  @override
  final bool isDark = true;

  // Pas de couleurs
  @override
  AnsiCode get primary => resetAll;

  @override
  AnsiCode get secondary => resetAll;

  @override
  AnsiCode get accent => resetAll;

  @override
  AnsiCode get success => resetAll;

  @override
  AnsiCode get warning => resetAll;

  @override
  AnsiCode get error => resetAll;

  @override
  AnsiCode get info => resetAll;

  @override
  AnsiCode get textPrimary => resetAll;

  @override
  AnsiCode get textSecondary => resetAll;

  @override
  AnsiCode get textMuted => resetAll;

  @override
  AnsiCode get backgroundPrimary => resetAll;

  @override
  AnsiCode get backgroundSecondary => resetAll;

  @override
  AnsiCode get scoreExcellent => resetAll;

  @override
  AnsiCode get scoreGood => resetAll;

  @override
  AnsiCode get scoreFair => resetAll;

  @override
  AnsiCode get scorePoor => resetAll;

  // Symboles ASCII simples
  @override
  String get symbolSuccess => '[OK]';

  @override
  String get symbolWarning => '[WARN]';

  @override
  String get symbolError => '[ERR]';

  @override
  String get symbolInfo => '[INFO]';

  // Barres ASCII
  @override
  String get barFilled => '#';

  @override
  String get barEmpty => '-';

  @override
  String get barPartial => '=';
}
