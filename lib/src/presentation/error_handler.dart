import 'dart:io';

import 'package:cura/src/domain/value_objects/exception.dart';
import 'package:cura/src/presentation/formatters/error_formatter.dart';
import 'package:cura/src/presentation/loggers/console_logger.dart';
import 'package:dio/dio.dart';

/// Top-level exception boundary for the Cura CLI.
///
/// Wraps any async or sync operation, intercepts every known exception type,
/// delegates formatting to [ErrorFormatter], and terminates the process with
/// exit code `1`.
///
/// ## Usage
///
/// ```dart
/// final handler = ErrorHandler(logger);
///
/// // Wrap a command runner call:
/// final code = await handler.handle(() => runner.run(args));
/// exit(code ?? 0);
/// ```
///
/// ## Exception hierarchy handled
///
/// | Exception              | Source                         |
/// |------------------------|--------------------------------|
/// | [PackageNotFoundException] | Domain — package not on pub.dev |
/// | [RateLimitException]   | Domain — API rate limit hit    |
/// | [NetworkException]     | Domain — HTTP-level failure    |
/// | [CuraException]        | Domain — any other domain error|
/// | [DioException]         | Infrastructure — Dio HTTP error|
/// | [SocketException]      | Infrastructure — connection error|
/// | Anything else          | Unexpected / bug               |
class ErrorHandler {
  final ErrorFormatter _formatter;

  /// Creates an [ErrorHandler] backed by [logger].
  ///
  /// Verbose output (stack traces, original errors) is enabled automatically
  /// when [ConsoleLogger.isVerbose] is `true`.
  ErrorHandler(ConsoleLogger logger) : _formatter = ErrorFormatter(logger);

  // ===========================================================================
  // Async handler
  // ===========================================================================

  /// Executes [fn] and returns its result.
  ///
  /// On any exception, formats the error via [ErrorFormatter] and calls
  /// `exit(1)`.  The optional [context] label is reserved for future use
  /// (e.g. attaching the originating command name to error reports).
  Future<T> handle<T>(
    Future<T> Function() fn, {
    String? context,
  }) async {
    try {
      return await fn();
    } on PackageNotFoundException catch (e) {
      _formatter.format(e);
      exit(1);
    } on RateLimitException catch (e) {
      _formatter.format(e);
      exit(1);
    } on NetworkException catch (e) {
      _formatter.format(e);
      exit(1);
    } on CuraException catch (e) {
      _formatter.format(e);
      exit(1);
    } on DioException catch (e) {
      _formatter.format(e);
      exit(1);
    } on SocketException catch (e) {
      _formatter.format(e);
      exit(1);
    } catch (e, stackTrace) {
      _formatter.format(e, stackTrace: stackTrace);
      exit(1);
    }
  }

  // ===========================================================================
  // Sync handler
  // ===========================================================================

  /// Synchronous variant of [handle] for operations that cannot be async.
  T handleSync<T>(
    T Function() fn, {
    String? context,
  }) {
    try {
      return fn();
    } on CuraException catch (e) {
      _formatter.format(e);
      exit(1);
    } catch (e, stackTrace) {
      _formatter.format(e, stackTrace: stackTrace);
      exit(1);
    }
  }
}
