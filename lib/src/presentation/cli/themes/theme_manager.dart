import 'package:cura/src/presentation/cli/themes/dark_theme.dart';
import 'package:cura/src/presentation/cli/themes/theme.dart';

/// Singleton : Theme manager
class ThemeManager {
  static CuraTheme _current = DarkTheme();

  static CuraTheme get current => _current;

  static void setTheme(String themeName) {
    _current = switch (themeName.toLowerCase()) {
      'dark' => DarkTheme(),
      // 'light' => LightTheme(),
      // 'minimal' => MinimalTheme(),
      _ => DarkTheme(),
    };
  }
}
