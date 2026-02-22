/// Terminal symbol sets used across Cura's CLI presentation layer.
///
/// Symbols are grouped by semantic category so renderers can swap entire sets
/// (e.g. swap [StatusSymbols] for [AsciiStatusSymbols] in CI mode) without
/// touching business logic.

// ── Spinner frames ───────────────────────────────────────────────────────────

class SpinnerSymbols {
  const SpinnerSymbols._();

  static List<String> get braille =>
      ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];

  static List<String> get dots => ['⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷'];

  static List<String> get arc => ['◜', '◠', '◝', '◞', '◡', '◟'];
}

// ── Status symbols ────────────────────────────────────────────────────────────

/// Unicode status indicators (U+2713 range — single-width, widely supported).
abstract class StatusSymbols {
  String get success => '✓'; // U+2713 Check Mark
  String get warning => '!'; // ASCII
  String get error => '✗'; // U+2717 Ballot X
  String get info => 'ℹ'; // U+2139 Information Source
  String get pending => '○'; // U+25CB White Circle
  String get skipped => '⊘'; // U+2298 Circled Division Slash
}

/// Pure ASCII fallback for CI/CD environments and basic terminals.
abstract class AsciiStatusSymbols {
  String get success => '+';
  String get warning => '!';
  String get error => 'x';
  String get info => 'i';
  String get pending => 'o';
  String get skipped => '-';
}

// ── Badge / priority symbols ──────────────────────────────────────────────────

abstract class BadgeSymbols {
  String get star => '☆'; // U+2606 White Star (avoid emoji ⭐)
  String get check => '✓';

  // Severity levels
  String get low => '▂'; // U+2582 Lower Two Eighths Block
  String get medium => '▅'; // U+2585 Lower Five Eighths Block
  String get high => '▇'; // U+2587 Lower Seven Eighths Block
  String get critical => '█'; // U+2588 Full Block

  // Status dots (apply ANSI colour at call site)
  String get dot => '●'; // U+25CF Black Circle
}

// ── List / tree symbols ───────────────────────────────────────────────────────

abstract class ListSymbols {
  String get bullet => '•'; // U+2022 Bullet
  String get arrow => '→'; // U+2192 Rightwards Arrow
  String get arrowRight => '▸'; // U+25B8 Black Right-Pointing Triangle
  String get dash => '–'; // U+2013 En Dash
  String get chevron => '›'; // U+203A Single Right-Pointing Quotation Mark

  // Tree connectors
  String get treeBranch => '├─';
  String get treeLast => '└─';
  String get treeVertical => '│';
  String get treeSpace => '  ';
}

// ── Box-drawing symbols ───────────────────────────────────────────────────────

abstract class BoxSymbols {
  // Single-line
  String get topLeft => '┌';
  String get topRight => '┐';
  String get bottomLeft => '└';
  String get bottomRight => '┘';
  String get horizontal => '─';
  String get vertical => '│';
  String get cross => '┼';
  String get teeLeft => '├';
  String get teeRight => '┤';
  String get teeTop => '┬';
  String get teeBottom => '┴';

  // Double-line (headers)
  String get doubleHorizontal => '═';
  String get doubleVertical => '║';

  // Rounded corners (modern style)
  String get roundTopLeft => '╭';
  String get roundTopRight => '╮';
  String get roundBottomLeft => '╰';
  String get roundBottomRight => '╯';
}

/// Pure ASCII fallback for box drawing.
abstract class AsciiBoxSymbols {
  String get topLeft => '+';
  String get topRight => '+';
  String get bottomLeft => '+';
  String get bottomRight => '+';
  String get horizontal => '-';
  String get vertical => '|';
  String get cross => '+';
}
