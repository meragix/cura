import 'dart:io';

import 'package:cura/src/domain/value_objects/errors.dart';
import 'package:cura/src/domain/value_objects/exception.dart';
import 'package:cura/src/presentation/loggers/console_logger.dart';
import 'package:dio/dio.dart';
import 'package:mason_logger/mason_logger.dart';

/// Formats domain and infrastructure exceptions into structured, human-readable
/// CLI output.
///
/// All rendering funnels through [_renderBlock], a single primitive that
/// handles the consistent header / separator / message / metadata /
/// suggestions / verbose-detail layout. Each `_formatXxx` method is
/// responsible only for extracting the data; it never touches the logger
/// directly.
///
/// Adding support for a new error type requires:
/// 1. A `_formatXxx` method that calls [_renderBlock].
/// 2. A new branch in [format].
///
/// This class is an internal collaborator of [ErrorHandler] and the two CLI
/// presenters — callers should not invoke [format] directly.
class ErrorFormatter {
  final Logger _logger;
  final bool _verbose;

  static const _kSeparator =
      '────────────────────────────────────────────────────────────';

  ErrorFormatter(ConsoleLogger logger)
      : _logger = logger.raw,
        _verbose = logger.isVerbose;

  // ===========================================================================
  // Public API
  // ===========================================================================

  /// Dispatches [error] to the appropriate formatter and writes to the console.
  void format(dynamic error, {StackTrace? stackTrace}) {
    if (error is PackageProviderError) {
      _formatProviderError(error);
    } else if (error is CuraException) {
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
  // Error-specific formatters — data extraction only, no direct logger calls
  // ===========================================================================

  void _formatProviderError(PackageProviderError error) {
    final (emoji, title, message, suggestions) = switch (error) {
      NetworkError(:final message) => (
          '🌐',
          'Network Error',
          message,
          <String>[
            'Check your internet connection',
            'Verify pub.dev is accessible',
            "Try using ${cyan.wrap('--offline')} mode with cached data",
          ],
        ),
      NotFoundError(:final packageName) => (
          '📦',
          'Package Not Found',
          'Package "$packageName" not found on pub.dev',
          <String>[
            'Verify the package name is spelled correctly',
            'Check if the package exists on pub.dev',
          ],
        ),
      RateLimitError(:final retryAfter) => (
          '⏱️',
          'Rate Limit Exceeded',
          'The upstream API enforced a rate limit',
          <String>[
            'Wait ${retryAfter.inSeconds}s before retrying',
            "Use ${cyan.wrap('--use-cache')} to reduce API calls",
            'Consider adding a GitHub token for higher rate limits',
          ],
        ),
      TimeoutError(:final packageName) => (
          '⏳',
          'Request Timeout',
          'Timeout while fetching "$packageName"',
          <String>[
            'Check your internet connection',
            'Try again in a few moments',
          ],
        ),
    };

    _renderBlock(
      header: '$emoji  $title',
      message: message,
      suggestions: suggestions,
    );
  }

  void _formatCuraException(CuraException error) {
    _renderBlock(
      header: '${_getErrorEmoji(error.code ?? 'ERROR')}  Error',
      message: error.message,
      metadata: {
        if (error.code != null) 'Code': error.code!,
        if (error.context != null) 'Context': error.context!,
      },
      suggestions: _getSuggestions(error),
      verboseLines: [
        if (error.originalError != null) ...[
          'Original error:',
          '  ${error.originalError}',
        ],
        if (error.stackTrace != null) ...[
          'Stack trace:',
          ...error.stackTrace.toString().split('\n').take(5).map((l) => '  $l'),
        ],
      ],
    );
  }

  void _formatDioException(DioException error) {
    _renderBlock(
      header: '🌐  Network Error',
      message: 'Failed to reach the server',
      metadata: {
        if (error.response?.statusCode != null)
          'Status': '${error.response!.statusCode}',
        if (error.message != null) 'Details': error.message!,
      },
      suggestions: [
        'Check your internet connection',
        'Verify the API endpoint is accessible',
        'Try again in a few moments',
      ],
    );
  }

  void _formatSocketException(SocketException error) {
    _renderBlock(
      header: '🔌  Connection Error',
      message: 'Unable to connect to the network',
      metadata: {
        'Host': error.address?.host ?? 'unknown',
        'Port': '${error.port ?? 'unknown'}',
      },
      suggestions: [
        'Check your internet connection',
        'Verify DNS resolution is working',
        "Check if you're behind a proxy or firewall",
      ],
    );
  }

  void _formatFormatException(FormatException error) {
    _renderBlock(
      header: '📄  Format Error',
      message: 'Invalid data format received',
      metadata: {
        'Message': error.message,
        if (error.source != null) 'Source': '${error.source}',
      },
    );
  }

  void _formatGenericException(dynamic error, StackTrace? stackTrace) {
    _renderBlock(
      header: '⚠️   Unexpected Error',
      message: error.toString(),
      suggestions: [
        "This might be a bug — please report it: ${cyan.wrap('https://github.com/meragix/cura/issues')}",
      ],
      verboseLines: [
        if (stackTrace != null) ...[
          'Stack trace:',
          ...stackTrace.toString().split('\n').take(10).map((l) => '  $l'),
        ],
      ],
    );
  }

  // ===========================================================================
  // Shared rendering primitive
  // ===========================================================================

  /// Renders a consistent error block: header, separator, message, optional
  /// metadata, optional suggestions, optional verbose lines, closing separator.
  ///
  /// This is the single source of truth for the visual layout — all
  /// `_formatXxx` methods delegate here.
  void _renderBlock({
    required String header,
    required String message,
    Map<String, String> metadata = const {},
    List<String> suggestions = const [],
    List<String> verboseLines = const [],
  }) {
    _logger.info('');
    _logger.err('${styleBold.wrap(header)}');
    _logger.err(red.wrap(_kSeparator));
    _logger.err('');
    _logger.err(styleBold.wrap(message));

    if (metadata.isNotEmpty) {
      _logger.info('');
      for (final MapEntry(:key, :value) in metadata.entries) {
        _logger.info('${darkGray.wrap('$key:')} $value');
      }
    }

    if (suggestions.isNotEmpty) {
      _logger.info('');
      _logger.info(yellow.wrap('💡 Suggestions:'));
      for (final s in suggestions) {
        _logger.info('   ${darkGray.wrap('•')} $s');
      }
    }

    if (_verbose && verboseLines.isNotEmpty) {
      _logger.info('');
      for (final line in verboseLines) {
        _logger.info(darkGray.wrap(line));
      }
    }

    _logger.err(red.wrap(_kSeparator));
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
    return switch (error) {
      PackageNotFoundException() => [
          'Verify the package name is spelled correctly',
          'Check if the package exists on pub.dev',
          "Use ${cyan.wrap('cura search <keyword>')} to find similar packages",
        ],
      RateLimitException(:final retryAfter) => [
          if (retryAfter != null) 'Wait $retryAfter before retrying',
          "Use ${cyan.wrap('--use-cache')} to reduce API calls",
          'Consider adding a GitHub token for higher rate limits',
        ],
      NetworkException() => [
          'Check your internet connection',
          'Verify pub.dev is accessible',
          "Try using ${cyan.wrap('--offline')} mode with cached data",
        ],
      ParseException() => [
          'This might be a temporary API issue',
          'Try again in a few moments',
          'Report this if it persists',
        ],
      ValidationException(:final validationErrors) => validationErrors,
      _ => const [],
    };
  }
}
