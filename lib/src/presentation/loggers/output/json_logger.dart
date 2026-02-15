// Logger pour output JSON (--json)
import 'dart:convert';

import 'package:cura/src/presentation/loggers/cura_logger.dart';

class JsonLogger extends CuraLogger {
  final Map _output = {};

  JsonLogger({super.logger}) : super(level: LogLevel.silent);

  @override
  void info(String message) {
    // Pas d'output texte en mode JSON
  }

  // API spécifique JSON
  void addData(String key, dynamic value) {
    _output[key] = value;
  }

  void flush() {
    print(jsonEncode(_output));
  }
}
