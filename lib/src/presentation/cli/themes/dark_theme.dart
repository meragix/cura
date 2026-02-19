import 'package:cura/src/presentation/cli/themes/theme.dart';
import 'package:mason_logger/mason_logger.dart';

/// Dark theme (default)
class DarkTheme implements CuraTheme {
  @override
  AnsiCode get primary => cyan;

  @override
  AnsiCode get success => green;

  @override
  AnsiCode get warning => yellow;

  @override
  AnsiCode get error => red;

  @override
  AnsiCode get info => white;

  @override
  AnsiCode get muted => darkGray;

  @override
  String get checkMark => '✓';

  @override
  String get crossMark => '✗';

  @override
  String get warningMark => '!';

  @override
  String styleError(String text) {
    throw UnimplementedError();
  }

  @override
  String stylePrimary(String text) {
    throw UnimplementedError();
  }

  @override
  String styleSuccess(String text) {
    throw UnimplementedError();
  }

  @override
  String styleWarning(String text) {
    throw UnimplementedError();
  }
}
