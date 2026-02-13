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
  String get symbolSuccess => '✅';

  @override
  String get symbolWarning => '⚠️';

  @override
  String get symbolError => '❌';

  @override
  String get symbolInfo => '💡';

  // Barres de progression (caractères pleins pour visibilité)
  @override
  String get barFilled => '█';

  @override
  String get barEmpty => '░';

  @override
  String get barPartial => '▓';
}

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
