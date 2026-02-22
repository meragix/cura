import 'package:cura/src/presentation/themes/theme.dart';
import 'package:mason_logger/mason_logger.dart';

/// Minimal (no-colour) theme for CI/CD environments and plain terminals.
///
/// All colour slots resolve to [resetAll] so text is never coloured.
/// Symbols and progress characters fall back to plain ASCII to maximise
/// compatibility with basic terminal emulators and log file viewers.
class MinimalTheme extends BaseCuraTheme {
  @override
  final String name = 'minimal';

  @override
  final bool isDark = true;

  // ── Brand ─────────────────────────────────────────────────────────────────

  @override
  AnsiCode get primary => resetAll;

  @override
  AnsiCode get secondary => resetAll;

  @override
  AnsiCode get accent => resetAll;

  // ── Semantic ──────────────────────────────────────────────────────────────

  @override
  AnsiCode get success => resetAll;

  @override
  AnsiCode get warning => resetAll;

  @override
  AnsiCode get error => resetAll;

  @override
  AnsiCode get info => resetAll;

  // ── Text ──────────────────────────────────────────────────────────────────

  @override
  AnsiCode get textPrimary => resetAll;

  @override
  AnsiCode get textSecondary => resetAll;

  @override
  AnsiCode get muted => resetAll;

  // ── Background ────────────────────────────────────────────────────────────

  @override
  AnsiCode get backgroundPrimary => resetAll;

  @override
  AnsiCode get backgroundSecondary => resetAll;

  // ── Score tier colours ────────────────────────────────────────────────────

  @override
  AnsiCode get scoreExcellent => resetAll;

  @override
  AnsiCode get scoreGood => resetAll;

  @override
  AnsiCode get scoreFair => resetAll;

  @override
  AnsiCode get scorePoor => resetAll;

  // ── Symbols (plain ASCII for maximum compatibility) ────────────────────────

  @override
  String get symbolSuccess => '[OK]';

  @override
  String get symbolWarning => '[WARN]';

  @override
  String get symbolError => '[ERR]';

  @override
  String get symbolInfo => '[INFO]';

  // ── Progress bar (plain ASCII) ─────────────────────────────────────────────

  @override
  String get barFilled => '#';

  @override
  String get barEmpty => '-';

  @override
  String get barPartial => '=';

  // ── Style helpers (no-op: return text unchanged) ───────────────────────────

  @override
  String stylePrimary(String text) => text;

  @override
  String styleSuccess(String text) => text;

  @override
  String styleWarning(String text) => text;

  @override
  String styleError(String text) => text;
}
