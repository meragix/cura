import 'dart:io';

import 'package:cura/src/domain/value_objects/exception.dart';
import 'package:cura/src/presentation/loggers/console_logger.dart';
import 'package:dio/dio.dart';
import 'package:mason_logger/mason_logger.dart';

/// Formats domain and infrastructure exceptions into structured, human-readable
/// CLI output.
///
/// Each exception type is dispatched to a dedicated private method that emits:
/// - A colour-coded header with an appropriate symbol
/// - The primary error message in bold
/// - Contextual metadata (error code, URL, host, etc.)
/// - Actionable suggestions tailored to the error category
/// - Stack-trace detail when verbose mode is active
///
/// This class is an internal collaborator of [ErrorHandler] — callers should
/// not invoke [format] directly.
class ErrorFormatter {
  /// Underlying mason_logger used for raw ANSI-formatted output.
  final Logger _logger;

  /// When `true`, prints original errors and stack traces.
  /// Derived automatically from the injected [ConsoleLogger.isVerbose].
  final bool verbose;

  ErrorFormatter(ConsoleLogger logger)
      : _logger = logger.raw,
        verbose = logger.isVerbose;

  // ===========================================================================
  // Public API
  // ===========================================================================

  /// Dispatches [error] to the appropriate formatter and writes to stderr/stdout.
  void format(dynamic error, {StackTrace? stackTrace}) {
    if (error is CuraException) {
      _formatCuraException(error);
    } else if (error is DioException) {
      _formatDioException(error);
    } else if (error is SocketException) {
      _formatSocketException(error);
    } else if (error is FormatException) {
      _formatFormatException(error);
    } else {
      _formatGenericException(error, stackTrace);
    }
  }

  // ===========================================================================
  // CuraException hierarchy
  // ===========================================================================

  void _formatCuraException(CuraException error) {
    _logger.info('');
    final emoji = _getErrorEmoji(error.code ?? 'ERROR');
    _logger.err('${styleBold.wrap('$emoji Error')}');
    _logger.err(red.wrap('─' * 60));
    _logger.err('');
    _logger.err(styleBold.wrap(error.message));

    if (error.code != null) {
      _logger.info('');
      _logger.info('${darkGray.wrap('Code:')} ${error.code}');
    }

    if (error.context != null) {
      _logger.info('${darkGray.wrap('Context:')} ${error.context}');
    }

    final suggestions = _getSuggestions(error);
    if (suggestions.isNotEmpty) {
      _logger.info('');
      _logger.info(yellow.wrap('💡 Suggestions:'));
      for (final s in suggestions) {
        _logger.info('   ${darkGray.wrap('•')} $s');
      }
    }

    if (verbose && error.originalError != null) {
      _logger.info('');
      _logger.info(darkGray.wrap('Original error:'));
      _logger.info(darkGray.wrap('  ${error.originalError}'));
    }

    if (verbose && error.stackTrace != null) {
      _logger.info('');
      _logger.info(darkGray.wrap('Stack trace:'));
      for (final line in error.stackTrace.toString().split('\n').take(5)) {
        _logger.info(darkGray.wrap('  $line'));
      }
    }

    _logger.err(red.wrap('─' * 60));
    _logger.info('');
  }

  // ===========================================================================
  // Infrastructure exceptions
  // ===========================================================================

  void _formatDioException(DioException error) {
    _logger.info('');
    _logger.err('${styleBold.wrap('🌐 Network Error')}');
    _logger.err(red.wrap('─' * 60));
    _logger.err('');
    _logger.err('Failed to reach the server');
    _logger.info('');
    if (error.response?.statusCode != null) {
      _logger.info('${darkGray.wrap('Status:')} ${error.response!.statusCode}');
    }
    _logger.info('${darkGray.wrap('Details:')} ${error.message}');
    _logger.info('');
    _logger.info(yellow.wrap('💡 Suggestions:'));
    _logger.info('   ${darkGray.wrap('•')} Check your internet connection');
    _logger
        .info('   ${darkGray.wrap('•')} Verify the API endpoint is accessible');
    _logger.info('   ${darkGray.wrap('•')} Try again in a few moments');
    _logger.err(red.wrap('─' * 60));
    _logger.info('');
  }

  void _formatSocketException(SocketException error) {
    _logger.info('');
    _logger.err('${styleBold.wrap('🔌 Connection Error')}');
    _logger.err(red.wrap('─' * 60));
    _logger.err('');
    _logger.err('Unable to connect to the network');
    _logger.info('');
    _logger
        .info('${darkGray.wrap('Host:')} ${error.address?.host ?? 'unknown'}');
    _logger.info('${darkGray.wrap('Port:')} ${error.port ?? 'unknown'}');
    _logger.info('');
    _logger.info(yellow.wrap('💡 Suggestions:'));
    _logger.info('   ${darkGray.wrap('•')} Check your internet connection');
    _logger.info('   ${darkGray.wrap('•')} Verify DNS resolution is working');
    _logger.info(
        "   ${darkGray.wrap('•')} Check if you're behind a proxy or firewall");
    _logger.err(red.wrap('─' * 60));
    _logger.info('');
  }

  void _formatFormatException(FormatException error) {
    _logger.info('');
    _logger.err('${styleBold.wrap('📄 Format Error')}');
    _logger.err(red.wrap('─' * 60));
    _logger.err('');
    _logger.err('Invalid data format received');
    _logger.info('');
    _logger.info('${darkGray.wrap('Message:')} ${error.message}');
    if (error.source != null) {
      _logger.info('${darkGray.wrap('Source:')} ${error.source}');
    }
    _logger.err(red.wrap('─' * 60));
    _logger.info('');
  }

  void _formatGenericException(dynamic error, StackTrace? stackTrace) {
    _logger.info('');
    _logger.err('${styleBold.wrap('⚠️  Unexpected Error')}');
    _logger.err(red.wrap('─' * 60));
    _logger.err('');
    _logger.err(error.toString());

    if (verbose && stackTrace != null) {
      _logger.info('');
      _logger.info(darkGray.wrap('Stack trace:'));
      for (final line in stackTrace.toString().split('\n').take(10)) {
        _logger.info(darkGray.wrap('  $line'));
      }
    }

    _logger.info('');
    _logger.info(yellow.wrap('💡 This might be a bug. Please report it:'));
    _logger.info('   ${cyan.wrap('https://github.com/meragix/cura/issues')}');
    _logger.err(red.wrap('─' * 60));
    _logger.info('');
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  String _getErrorEmoji(String code) {
    return switch (code) {
      'PACKAGE_NOT_FOUND' => '📦',
      'NETWORK_ERROR' => '🌐',
      'RATE_LIMIT' => '⏱️',
      'PARSE_ERROR' => '📄',
      'VALIDATION_ERROR' => '✖️',
      'CACHE_ERROR' => '💾',
      _ => '⚠️',
    };
  }

  List<String> _getSuggestions(CuraException error) {
    if (error is PackageNotFoundException) {
      return [
        'Verify the package name is spelled correctly',
        'Check if the package exists on pub.dev',
        "Use ${cyan.wrap('cura search <keyword>')} to find similar packages",
      ];
    }

    if (error is RateLimitException) {
      return [
        if (error.retryAfter != null)
          'Wait ${error.retryAfter} before retrying',
        "Use ${cyan.wrap('--use-cache')} to reduce API calls",
        'Consider adding a GitHub token for higher rate limits',
      ];
    }

    if (error is NetworkException) {
      return [
        'Check your internet connection',
        'Verify pub.dev is accessible',
        "Try using ${cyan.wrap('--offline')} mode with cached data",
      ];
    }

    if (error is ParseException) {
      return [
        'This might be a temporary API issue',
        'Try again in a few moments',
        'Report this if it persists',
      ];
    }

    if (error is ValidationException) {
      return error.validationErrors;
    }

    return const [];
  }
}
