import 'package:mason_logger/mason_logger.dart';

/// Interface pour tous les thèmes
abstract class CuraTheme {
  // Couleurs primaires
  AnsiCode get primary;
  AnsiCode get secondary;
  AnsiCode get accent;

  // Couleurs sémantiques
  AnsiCode get success;
  AnsiCode get warning;
  AnsiCode get error;
  AnsiCode get info;

  // Couleurs de texte
  AnsiCode get textPrimary;
  AnsiCode get textSecondary;
  AnsiCode get textMuted;

  // Couleurs de fond (pour éventuels backgrounds)
  AnsiCode get backgroundPrimary;
  AnsiCode get backgroundSecondary;

  // Couleurs de score
  AnsiCode get scoreExcellent; // A+/A (90-100)
  AnsiCode get scoreGood; // B (70-89)
  AnsiCode get scoreFair; // C (50-69)
  AnsiCode get scorePoor; // D/F (<50)

  // Symboles et emojis
  String get symbolSuccess;
  String get symbolWarning;
  String get symbolError;
  String get symbolInfo;

  // Barres de progression
  String get barFilled;
  String get barEmpty;
  String get barPartial;

  // Helpers
  String get name;
  bool get isDark;
}
