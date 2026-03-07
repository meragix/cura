import 'package:cura/src/domain/entities/score.dart';

/// Formatter : Score → String lisible
class ScoreFormatter {
  const ScoreFormatter._();

  /// Format: "85/100 (A)"
  static String format(Score score) {
    return '${score.total.toString().padLeft(3)}/100 (${score.grade.label})';
  }

  /// Format avec couleurs
  static String formatColored(Score score) {
    return format(score);
  }
}
