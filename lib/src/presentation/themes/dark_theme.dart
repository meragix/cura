import 'package:cura/src/presentation/themes/theme.dart';
import 'package:mason_logger/mason_logger.dart';

class DarkTheme implements CuraTheme {
  @override
  final String name = 'dark';

  @override
  final bool isDark = true;

  // Couleurs primaires
  @override
  AnsiCode get primary => cyan;

  @override
  AnsiCode get secondary => magenta;

  @override
  AnsiCode get accent => yellow;

  // Couleurs sémantiques
  @override
  AnsiCode get success => green;

  @override
  AnsiCode get warning => yellow;

  @override
  AnsiCode get error => red;

  @override
  AnsiCode get info => cyan;

  // Couleurs de texte (adaptées au fond sombre)
  @override
  AnsiCode get textPrimary => white;

  @override
  AnsiCode get textSecondary => lightGray;

  @override
  AnsiCode get textMuted => darkGray;

  // Couleurs de fond
  @override
  AnsiCode get backgroundPrimary => resetAll; // Terminal default

  @override
  AnsiCode get backgroundSecondary => darkGray;

  // Couleurs de score (vives pour fond sombre)
  @override
  AnsiCode get scoreExcellent => green;

  @override
  AnsiCode get scoreGood => lightGreen;

  @override
  AnsiCode get scoreFair => yellow;

  @override
  AnsiCode get scorePoor => red;

  // Symboles
  @override
  String get symbolSuccess => '✓';

  @override
  String get symbolWarning => '⚠';

  @override
  String get symbolError => '✗';

  @override
  String get symbolInfo => 'ℹ';

  // Barres de progression (caractères pleins pour visibilité)
  @override
  String get barFilled => '█';

  @override
  String get barEmpty => '░';

  @override
  String get barPartial => '▓';
}
