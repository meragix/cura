import 'package:io/ansi.dart';

/// Interface : Thème CLI
abstract class CuraTheme {
  // Colors
  AnsiCode get primary;
  AnsiCode get success;
  AnsiCode get warning;
  AnsiCode get error;
  AnsiCode get info;
  AnsiCode get muted;

  // Symbols
  String get checkMark;
  String get crossMark;
  String get warningMark;

  // Styles
  String stylePrimary(String text) => primary.wrap(text)!;
  String styleSuccess(String text) => success.wrap(text)!;
  String styleWarning(String text) => warning.wrap(text)!;
  String styleError(String text) => error.wrap(text)!;
}
