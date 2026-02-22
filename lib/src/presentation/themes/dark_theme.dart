import 'package:cura/src/presentation/themes/theme.dart';
import 'package:mason_logger/mason_logger.dart';

/// Default dark terminal theme.
///
/// Vibrant ANSI colours chosen for legibility on dark backgrounds.
/// Score tier colours graduate from green (excellent) → red (poor) to
/// give an at-a-glance health signal.
class DarkTheme extends BaseCuraTheme {
  @override
  final String name = 'dark';

  @override
  final bool isDark = true;

  // ── Brand ─────────────────────────────────────────────────────────────────

  @override
  AnsiCode get primary => cyan;

  @override
  AnsiCode get secondary => magenta;

  @override
  AnsiCode get accent => yellow;

  // ── Semantic ──────────────────────────────────────────────────────────────

  @override
  AnsiCode get success => green;

  @override
  AnsiCode get warning => yellow;

  @override
  AnsiCode get error => red;

  @override
  AnsiCode get info => cyan;

  // ── Text ──────────────────────────────────────────────────────────────────

  @override
  AnsiCode get textPrimary => white;

  @override
  AnsiCode get textSecondary => lightGray;

  @override
  AnsiCode get muted => darkGray;

  // ── Background ────────────────────────────────────────────────────────────

  @override
  AnsiCode get backgroundPrimary => resetAll; // terminal default

  @override
  AnsiCode get backgroundSecondary => darkGray;

  // ── Score tier colours ────────────────────────────────────────────────────

  @override
  AnsiCode get scoreExcellent => green;

  @override
  AnsiCode get scoreGood => lightGreen;

  @override
  AnsiCode get scoreFair => yellow;

  @override
  AnsiCode get scorePoor => red;

  // ── Symbols ───────────────────────────────────────────────────────────────

  @override
  String get symbolSuccess => '✓';

  @override
  String get symbolWarning => '!';

  @override
  String get symbolError => '✗';

  @override
  String get symbolInfo => 'ℹ';

  // ── Progress bar ──────────────────────────────────────────────────────────

  @override
  String get barFilled => '█';

  @override
  String get barEmpty => '░';

  @override
  String get barPartial => '▓';
}
