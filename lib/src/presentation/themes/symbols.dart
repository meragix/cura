class BadgeSymbols {
  String get star => '⭐'; // U+2B50 (emoji, éviter)
  String get starOutline => '☆'; // U+2606 White Star
  String get check => '✓';
  String get lock => '🔒'; // U+1F512 (emoji, éviter)
  String get lockSimple => '⚿'; // U+26BF (alternative)

  // Levels/Priority
  String get low => '▂'; // U+2582 Lower Block
  String get medium => '▅'; // U+2585 Medium Block
  String get high => '▇'; // U+2587 High Block
  String get critical => '█'; // U+2588 Full Block

  // Status dots
  String get dotGreen => '●'; // Colorier en vert
  String get dotRed => '●'; // Colorier en rouge
  String get dotYellow => '●'; // Colorier en jaune
}

class SpinnerSymbols {
  const SpinnerSymbols._();

  static List<String> get braille =>
      ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];

  static List<String> get dots => ['⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷'];

  static List<String> get arc => ['◜', '◠', '◝', '◞', '◡', '◟'];

  static List<String> get dots2 => ['.  ', '.. ', '...', ' ..', '  .', '   '];
}

// abstract class SymbolSet {
//   // ... existing

//   // Search/Analysis
//   String get search => '◉';      // Ou '○' pour light theme
//   String get package => '📦';    // ❌ Emoji - utilise '▣' à la place
//   String get analyze => '●';
//   String get metrics => '◆';
// }

// class UnicodeSymbolSet implements SymbolSet {
//   @override
//   String get search => '◉';     // U+25C9 Fisheye

//   @override
//   String get package => '▣';    // U+25A3 Square with horizontal fill

//   @override
//   String get analyze => '◆';    // U+25C6 Black Diamond
// }

// class AsciiSymbolSet implements SymbolSet {
//   @override
//   String get search => 'o';

//   @override
//   String get package => '[pkg]';

//   @override
//   String get analyze => '*';
// }

// @override
// String get symbolSuccess => '✓';     // Pas ✅
// @override
// String get symbolWarning => '!';     // Pas ⚠️
// @override
// String get symbolError => '✗';       // Pas ❌
// @override
// String get symbolInfo => 'ℹ';        // Ou 'i' pour max compat

// @override
// String get barFilled => '█';
// @override
// String get barEmpty => '░';
//List<String> get barBlocks => [' ', '▏', '▎', '▍', '▌', '▋', '▊', '▉', '█'];

abstract class ListSymbols {
  String get bullet => '•'; // U+2022 Bullet
  String get arrow => '→'; // U+2192 Rightwards Arrow
  String get arrowRight => '▸'; // U+25B8 Right-Pointing Triangle
  String get dash => '–'; // U+2013 En Dash
  String get chevron =>
      '›'; // U+203A Single Right-Pointing Angle Quotation Mark

  // Tree structure
  String get treeBranch => '├─';
  String get treeLast => '└─';
  String get treeVertical => '│';
  String get treeSpace => '  ';
}

abstract class BoxSymbols {
  // Single-line box
  String get topLeft => '┌'; // U+250C
  String get topRight => '┐'; // U+2510
  String get bottomLeft => '└'; // U+2514
  String get bottomRight => '┘'; // U+2518
  String get horizontal => '─'; // U+2500
  String get vertical => '│'; // U+2502
  String get cross => '┼'; // U+253C
  String get teeLeft => '├'; // U+251C
  String get teeRight => '┤'; // U+2524
  String get teeTop => '┬'; // U+252C
  String get teeBottom => '┴'; // U+2534

  // Double-line box (headers)
  String get doubleHorizontal => '═'; // U+2550
  String get doubleVertical => '║'; // U+2551

  // Round corners (modern look)
  String get roundTopLeft => '╭'; // U+256D
  String get roundTopRight => '╮'; // U+256E
  String get roundBottomLeft => '╰'; // U+2570
  String get roundBottomRight => '╯'; // U+256F
}

// ASCII Fallback
abstract class AsciiBoxSymbols {
  String get topLeft => '+';
  String get topRight => '+';
  String get bottomLeft => '+';
  String get bottomRight => '+';
  String get horizontal => '-';
  String get vertical => '|';
  String get cross => '+';
}

// GOOD - Unicode simple, 1 char width garantie
abstract class StatusSymbols {
  String get success => '✓'; // U+2713 Check Mark
  String get warning => '!'; // ASCII
  String get error => '✗'; // U+2717 Ballot X
  String get info => 'ℹ'; // U+2139 Info (ou 'i' en ASCII)
  String get pending => '○'; // U+25CB White Circle
  String get skipped => '⊘'; // U+2298 Circled Division Slash
}

// FALLBACK - Pure ASCII (CI, vieux terminaux)
abstract class AsciiStatusSymbols {
  String get success => '+';
  String get warning => '!';
  String get error => 'x';
  String get info => 'i';
  String get pending => 'o';
  String get skipped => '-';
}
