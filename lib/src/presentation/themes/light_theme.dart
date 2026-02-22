import 'package:cura/src/presentation/themes/theme.dart';
import 'package:mason_logger/mason_logger.dart';

/// Light terminal theme.
///
/// Darker ANSI colours are chosen because they need more contrast against a
/// light background to remain legible.  Progress-bar characters use filled
/// circles instead of block elements to feel softer on light backgrounds.
class LightTheme extends BaseCuraTheme {
  @override
  final String name = 'light';

  @override
  final bool isDark = false;

  // ── Brand ─────────────────────────────────────────────────────────────────

  @override
  AnsiCode get primary => blue;

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
  AnsiCode get info => blue;

  // ── Text ──────────────────────────────────────────────────────────────────

  @override
  AnsiCode get textPrimary => resetAll; // terminal default (dark on light)

  @override
  AnsiCode get textSecondary => darkGray;

  @override
  AnsiCode get muted => lightGray;

  // ── Background ────────────────────────────────────────────────────────────

  @override
  AnsiCode get backgroundPrimary => resetAll;

  @override
  AnsiCode get backgroundSecondary => lightGray;

  // ── Score tier colours ────────────────────────────────────────────────────

  @override
  AnsiCode get scoreExcellent => green;

  @override
  AnsiCode get scoreGood => blue;

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
  String get barFilled => '●';

  @override
  String get barEmpty => '○';

  @override
  String get barPartial => '◐';
}
