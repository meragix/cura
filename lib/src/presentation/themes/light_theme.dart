import 'package:cura/src/presentation/themes/theme.dart';
import 'package:mason_logger/mason_logger.dart';

class LightTheme implements CuraTheme {
  @override
  final String name = 'light';

  @override
  final bool isDark = false;

  // Couleurs primaires (plus sombres pour lisibilité sur fond clair)
  @override
  AnsiCode get primary => blue;

  @override
  AnsiCode get secondary => magenta;

  @override
  AnsiCode get accent => yellow;

  // Couleurs sémantiques (versions plus sombres)
  @override
  AnsiCode get success => green;

  @override
  AnsiCode get warning => yellow;

  @override
  AnsiCode get error => red;

  @override
  AnsiCode get info => blue;

  // Couleurs de texte (sombres pour fond clair)
  @override
  AnsiCode get textPrimary => resetAll; // Noir du terminal

  @override
  AnsiCode get textSecondary => darkGray;

  @override
  AnsiCode get textMuted => lightGray;

  // Couleurs de fond
  @override
  AnsiCode get backgroundPrimary => resetAll;

  @override
  AnsiCode get backgroundSecondary => lightGray;

  // Couleurs de score (saturées pour fond clair)
  @override
  AnsiCode get scoreExcellent => green;

  @override
  AnsiCode get scoreGood => blue;

  @override
  AnsiCode get scoreFair => yellow;

  @override
  AnsiCode get scorePoor => red;

  // Symboles (identiques au dark)
  @override
  String get symbolSuccess => '✓';

  @override
  String get symbolWarning => '⚠';

  @override
  String get symbolError => '✗';

  @override
  String get symbolInfo => 'ℹ';

  // Barres de progression (caractères moins agressifs)
  @override
  String get barFilled => '●';

  @override
  String get barEmpty => '○';

  @override
  String get barPartial => '◐';
}
