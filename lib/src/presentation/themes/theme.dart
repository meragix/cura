import 'package:mason_logger/mason_logger.dart';

/// Contract every Cura theme must satisfy.
///
/// Concrete implementations cover the visual identity of a single terminal
/// appearance variant (dark, light, minimal, …).  All colour tokens use
/// [AnsiCode] so callers never need to import mason_logger directly for
/// styling decisions.
///
/// ## Colour groups
///
/// | Group        | Getters                                                         |
/// |--------------|------------------------------------------------------------------|
/// | Brand        | [primary], [secondary], [accent]                               |
/// | Semantic     | [success], [warning], [error], [info]                          |
/// | Text         | [textPrimary], [textSecondary], [muted]                        |
/// | Background   | [backgroundPrimary], [backgroundSecondary]                     |
/// | Score tiers  | [scoreExcellent], [scoreGood], [scoreFair], [scorePoor]         |
/// | Symbols      | [symbolSuccess], [symbolWarning], [symbolError], [symbolInfo]  |
/// | Progress bar | [barFilled], [barEmpty], [barPartial]                          |
/// | Metadata     | [name], [isDark]                                               |
///
/// ## Style helpers
///
/// Declared as abstract here; concrete defaults live in [BaseCuraTheme] so
/// the Dart analyser always sees them as explicitly implemented.
/// Use [BaseCuraTheme] as the base class for new themes.
abstract class CuraTheme {
  // ── Brand ─────────────────────────────────────────────────────────────────

  AnsiCode get primary;
  AnsiCode get secondary;
  AnsiCode get accent;

  // ── Semantic ──────────────────────────────────────────────────────────────

  AnsiCode get success;
  AnsiCode get warning;
  AnsiCode get error;
  AnsiCode get info;

  // ── Text ──────────────────────────────────────────────────────────────────

  /// Foreground colour for main body text.
  AnsiCode get textPrimary;

  /// Foreground colour for secondary / supporting text.
  AnsiCode get textSecondary;

  /// Foreground colour for muted / de-emphasised text.
  AnsiCode get muted;

  // ── Background ────────────────────────────────────────────────────────────

  AnsiCode get backgroundPrimary;
  AnsiCode get backgroundSecondary;

  // ── Score tier colours ────────────────────────────────────────────────────

  AnsiCode get scoreExcellent; // A+ / A  (90–100)
  AnsiCode get scoreGood; //       B    (70–89)
  AnsiCode get scoreFair; //       C    (50–69)
  AnsiCode get scorePoor; //       D/F  (< 50)

  // ── Symbols ───────────────────────────────────────────────────────────────

  String get symbolSuccess;
  String get symbolWarning;
  String get symbolError;
  String get symbolInfo;

  // ── Progress bar ──────────────────────────────────────────────────────────

  String get barFilled;
  String get barEmpty;
  String get barPartial;

  // ── Metadata ──────────────────────────────────────────────────────────────

  String get name;
  bool get isDark;

  // ── Style helpers ─────────────────────────────────────────────────────────

  String stylePrimary(String text);
  String styleSuccess(String text);
  String styleWarning(String text);
  String styleError(String text);
}

/// Abstract base class that provides [CuraTheme] style-helper defaults.
///
/// Extend this class instead of implementing [CuraTheme] directly so that
/// colour/symbol getters are the only members a concrete theme must declare.
/// Override any style method when non-standard formatting is required.
///
/// ```dart
/// class MyTheme extends BaseCuraTheme {
///   @override AnsiCode get primary => magenta;
///   // … other required getters …
/// }
/// ```
abstract class BaseCuraTheme implements CuraTheme {
  @override
  String stylePrimary(String text) => primary.wrap(text)!;

  @override
  String styleSuccess(String text) => success.wrap(text)!;

  @override
  String styleWarning(String text) => warning.wrap(text)!;

  @override
  String styleError(String text) => error.wrap(text)!;
}
