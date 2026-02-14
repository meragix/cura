import 'dart:io';

import 'package:cura/src/presentation/themes/dark_theme.dart';
import 'package:cura/src/presentation/themes/light_theme.dart';
import 'package:cura/src/presentation/themes/minimal_theme.dart';
import 'package:cura/src/presentation/themes/theme.dart';

class ThemeManager {
  static CuraTheme _currentTheme = DarkTheme();

  /// Thème actuel
  static CuraTheme get current => _currentTheme;

  /// Thèmes disponibles
  static final Map<String, CuraTheme> _themes = {
    'dark': DarkTheme(),
    'light': LightTheme(),
    'minimal': MinimalTheme(),
  };

  /// Change le thème
  static void setTheme(String themeName) {
    final theme = _themes[themeName.toLowerCase()];
    if (theme != null) {
      _currentTheme = theme;
    } else {
      throw ArgumentError('Theme "$themeName" not found. Available: ${_themes.keys.join(", ")}');
    }
  }

  /// Auto-détecte le thème depuis l'environnement
  static void autoDetect() {
    // 1. Vérifier variable d'environnement CURA_THEME
    final envTheme = Platform.environment['CURA_THEME'];
    if (envTheme != null && _themes.containsKey(envTheme.toLowerCase())) {
      setTheme(envTheme);
      return;
    }

    // 2. Détecter si on est dans un CI/CD (pas de couleurs)
    if (_isCIEnvironment()) {
      setTheme('minimal');
      return;
    }

    // 3. Essayer de détecter le thème du terminal (macOS/Linux)
    final detectedTheme = _detectTerminalTheme();
    if (detectedTheme != null) {
      setTheme(detectedTheme);
      return;
    }

    // 4. Fallback: dark par défaut
    setTheme('dark');
  }

  /// Détecte si on est dans un environnement CI/CD
  static bool _isCIEnvironment() {
    final ciEnvVars = ['CI', 'GITHUB_ACTIONS', 'GITLAB_CI', 'CIRCLECI', 'TRAVIS'];
    return ciEnvVars.any((v) => Platform.environment.containsKey(v));
  }

  /// Tente de détecter le thème du terminal
  static String? _detectTerminalTheme() {
    // Sur macOS, on peut lire les préférences du terminal
    if (Platform.isMacOS) {
      try {
        final result = Process.runSync('defaults', [
          'read',
          '-g',
          'AppleInterfaceStyle',
        ]);

        if (result.exitCode == 0 && result.stdout.toString().contains('Dark')) {
          return 'dark';
        } else {
          return 'light';
        }
      } catch (e) {
        // Échec de détection, utiliser dark par défaut
      }
    }

    // Linux: vérifier GTK theme
    if (Platform.isLinux) {
      final gtkTheme = Platform.environment['GTK_THEME'];
      if (gtkTheme != null && gtkTheme.toLowerCase().contains('dark')) {
        return 'dark';
      }
    }

    return null;
  }

  /// Liste tous les thèmes disponibles
  static List<String> availableThemes() => _themes.keys.toList();

  /// Enregistre un thème personnalisé
  static void registerTheme(String name, CuraTheme theme) {
    _themes[name.toLowerCase()] = theme;
  }
}
