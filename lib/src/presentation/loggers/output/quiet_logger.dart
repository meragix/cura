// import 'package:cura/src/presentation/loggers/cura_logger.dart';

// /// Logger pour mode verbose (--verbose)
// class QuietLogger extends CuraLogger {
//   QuietLogger({super.logger}) : super(level: LogLevel.verbose);

//   @override
//   void section(String title) {
//     _logger.info(cyan.wrap('[$title]'));
//   }

//   // Méthodes spécifiques au mode verbose
//   void cacheStatus({required bool hit, String? age}) {
//     if (hit) {
//       _logger.info('${green.wrap('[CACHE]')} ✅ Hit${age != null ? ' ($age old)' : ''}');
//     } else {
//       _logger.info('${red.wrap('[CACHE]')} ❌ Miss, fetching...');
//     }
//   }

//   void data(String label, dynamic value, {bool warn = false}) {
//     final emoji = warn ? '⚠️' : '';
//     _logger.info('  ${label.padRight(15)} $value $emoji');
//   }

//   void executionTime(int ms, {int apiCalls = 0}) {
//     _logger.info(darkGray.wrap('⏱️  ${ms}ms ($apiCalls API calls)'));
//   }
// }
