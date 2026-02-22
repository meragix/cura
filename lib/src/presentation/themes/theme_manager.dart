import 'dart:io';

import 'package:cura/src/presentation/themes/dark_theme.dart';
import 'package:cura/src/presentation/themes/light_theme.dart';
import 'package:cura/src/presentation/themes/minimal_theme.dart';
import 'package:cura/src/presentation/themes/theme.dart';

/// Singleton registry and resolver for [CuraTheme] instances.
///
/// ## Usage
///
/// ```dart
/// // Select a named theme explicitly:
/// ThemeManager.setTheme('light');
///
/// // Or let the manager pick based on the environment:
/// ThemeManager.autoDetect();
///
/// // Retrieve the active theme anywhere in the presentation layer:
/// final theme = ThemeManager.current;
/// ```
///
/// ## Custom themes
///
/// Register third-party or user-defined themes at startup:
///
/// ```dart
/// ThemeManager.registerTheme('dracula', DraculaTheme());
/// ThemeManager.setTheme('dracula');
/// ```
class ThemeManager {
  static CuraTheme _current = DarkTheme();

  /// Built-in theme registry.  Mutable so custom themes can be added via
  /// [registerTheme].
  static final Map<String, CuraTheme> _themes = {
    'dark': DarkTheme(),
    'light': LightTheme(),
    'minimal': MinimalTheme(),
  };

  /// The currently active theme.
  static CuraTheme get current => _current;

  /// Switches to [themeName] (case-insensitive).
  ///
  /// Throws [ArgumentError] if [themeName] is not found in the registry.
  /// Call [availableThemes] to enumerate valid names.
  static void setTheme(String themeName) {
    final theme = _themes[themeName.toLowerCase()];
    if (theme == null) {
      throw ArgumentError(
        'Theme "$themeName" not found. '
        'Available: ${_themes.keys.join(", ")}',
      );
    }
    _current = theme;
  }

  /// Detects the most appropriate theme from the runtime environment.
  ///
  /// Resolution order:
  /// 1. `CURA_THEME` environment variable.
  /// 2. CI/CD environment → `minimal` (no colours, ASCII symbols).
  /// 3. macOS system appearance via `defaults read -g AppleInterfaceStyle`.
  /// 4. Linux GTK theme (`GTK_THEME` environment variable).
  /// 5. Fallback: `dark`.
  static void autoDetect() {
    // 1. Explicit override via environment variable.
    final envTheme = Platform.environment['CURA_THEME'];
    if (envTheme != null && _themes.containsKey(envTheme.toLowerCase())) {
      setTheme(envTheme);
      return;
    }

    // 2. CI/CD: suppress colours for log readability.
    if (_isCIEnvironment()) {
      setTheme('minimal');
      return;
    }

    // 3–4. Terminal appearance detection.
    final detected = _detectTerminalTheme();
    if (detected != null) {
      setTheme(detected);
      return;
    }

    // 5. Fallback.
    setTheme('dark');
  }

  /// Returns the names of all registered themes.
  static List<String> availableThemes() => List.unmodifiable(_themes.keys);

  /// Registers a custom [theme] under [name].
  ///
  /// If [name] matches an existing theme it will be replaced.
  /// Use this to add community or project-specific themes at startup.
  static void registerTheme(String name, CuraTheme theme) {
    _themes[name.toLowerCase()] = theme;
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static bool _isCIEnvironment() {
    const ciVars = ['CI', 'GITHUB_ACTIONS', 'GITLAB_CI', 'CIRCLECI', 'TRAVIS'];
    return ciVars.any((v) => Platform.environment.containsKey(v));
  }

  static String? _detectTerminalTheme() {
    if (Platform.isMacOS) {
      try {
        final result = Process.runSync(
          'defaults',
          ['read', '-g', 'AppleInterfaceStyle'],
        );
        if (result.exitCode == 0 && result.stdout.toString().contains('Dark')) {
          return 'dark';
        }
        return 'light';
      } catch (_) {
        // Detection failed; fall through.
      }
    }

    if (Platform.isLinux) {
      final gtkTheme = Platform.environment['GTK_THEME'];
      if (gtkTheme != null && gtkTheme.toLowerCase().contains('dark')) {
        return 'dark';
      }
    }

    return null;
  }
}
