import 'dart:io';

import 'package:cura/src/core/error/exception.dart';
import 'package:cura/src/presentation/formatters/error_formatter.dart';
import 'package:http/http.dart' as http;
import 'package:mason_logger/mason_logger.dart';

class ErrorHandler {
  final ErrorFormatter formatter;

  ErrorHandler({
    Logger? logger,
    bool verbose = false,
  }) : formatter = ErrorFormatter(logger: logger, verbose: verbose);

  /// Executes a function with elegant error handling
  Future<T> handle<T>(
    Future<T> Function() fn, {
    String? context,
  }) async {
    try {
      return await fn();
    } on PackageNotFoundException catch (e) {
      formatter.format(e);
      exit(1);
    } on RateLimitException catch (e) {
      formatter.format(e);
      exit(1);
    } on NetworkException catch (e) {
      formatter.format(e);
      exit(1);
    } on CuraException catch (e) {
      formatter.format(e);
      exit(1);
    } on http.ClientException catch (e) {
      formatter.format(e);
      exit(1);
    } on SocketException catch (e) {
      formatter.format(e);
      exit(1);
    } catch (e, stackTrace) {
      formatter.format(e, stackTrace: stackTrace);
      exit(1);
    }
  }

  /// Synchronous version
  T handleSync<T>(
    T Function() fn, {
    String? context,
  }) {
    try {
      return fn();
    } on CuraException catch (e) {
      formatter.format(e);
      exit(1);
    } catch (e, stackTrace) {
      formatter.format(e, stackTrace: stackTrace);
      exit(1);
    }
  }
}
