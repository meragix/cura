import 'dart:io';
import 'package:cura/src/core/error/exception.dart';
import 'package:mason_logger/mason_logger.dart';
// import 'package:io/ansi.dart';
import 'package:http/http.dart' as http;

class ErrorFormatter {
  final Logger logger;
  final bool verbose;

  ErrorFormatter({
    Logger? logger,
    this.verbose = false,
  }) : logger = logger ?? Logger();

  /// Formate et affiche une erreur de manière élégante
  void format(dynamic error, {StackTrace? stackTrace}) {
    if (error is CuraException) {
      _formatCuraException(error);
    } else if (error is http.ClientException) {
      _formatHttpException(error);
    } else if (error is SocketException) {
      _formatSocketException(error);
    } else if (error is FormatException) {
      _formatFormatException(error);
    } else {
      _formatGenericException(error, stackTrace);
    }
  }

  /// Formate une CuraException personnalisée
  void _formatCuraException(CuraException error) {
    logger.info('');

    // Header avec emoji selon le type
    final emoji = _getErrorEmoji(error.code ?? 'ERROR');
    logger.info('');
    logger.err('${styleBold.wrap('$emoji Error')}');
    logger.err(red.wrap('─' * 60));

    // Message principal
    logger.err('');
    logger.err(styleBold.wrap(error.message));

    // Code d'erreur
    if (error.code != null) {
      logger.info('');
      logger.info('${darkGray.wrap('Code:')} ${error.code}');
    }

    // Contexte additionnel
    if (error.context != null) {
      logger.info('${darkGray.wrap('Context:')} ${error.context}');
    }

    // Suggestions selon le type d'erreur
    final suggestions = _getSuggestions(error);
    if (suggestions.isNotEmpty) {
      logger.info('');
      logger.info(yellow.wrap('💡 Suggestions:'));
      for (final suggestion in suggestions) {
        logger.info('   ${darkGray.wrap('•')} $suggestion');
      }
    }

    // Erreur originale en mode verbose
    if (verbose && error.originalError != null) {
      logger.info('');
      logger.info(darkGray.wrap('Original error:'));
      logger.info(darkGray.wrap('  ${error.originalError}'));
    }

    // Stack trace en mode verbose
    if (verbose && error.stackTrace != null) {
      logger.info('');
      logger.info(darkGray.wrap('Stack trace:'));
      final stackLines = error.stackTrace.toString().split('\n').take(5);
      for (final line in stackLines) {
        logger.info(darkGray.wrap('  $line'));
      }
    }

    logger.err(red.wrap('─' * 60));
    logger.info('');
  }

  /// Formate une erreur HTTP
  void _formatHttpException(http.ClientException error) {
    logger.info('');
    logger.err('${styleBold.wrap('🌐 Network Error')}');
    logger.err(red.wrap('─' * 60));
    logger.err('');
    logger.err('Failed to connect to the server');
    logger.info('');
    logger.info('${darkGray.wrap('Details:')} ${error.message}');
    logger.info('');
    logger.info(yellow.wrap('💡 Suggestions:'));
    logger.info('   ${darkGray.wrap('•')} Check your internet connection');
    logger
        .info('   ${darkGray.wrap('•')} Verify the API endpoint is accessible');
    logger.info('   ${darkGray.wrap('•')} Try again in a few moments');
    logger.err(red.wrap('─' * 60));
    logger.info('');
  }

  /// Formate une erreur de socket
  void _formatSocketException(SocketException error) {
    logger.info('');
    logger.err('${styleBold.wrap('🔌 Connection Error')}');
    logger.err(red.wrap('─' * 60));
    logger.err('');
    logger.err('Unable to connect to the network');
    logger.info('');
    logger
        .info('${darkGray.wrap('Host:')} ${error.address?.host ?? 'unknown'}');
    logger.info('${darkGray.wrap('Port:')} ${error.port ?? 'unknown'}');
    logger.info('');
    logger.info(yellow.wrap('💡 Suggestions:'));
    logger.info('   ${darkGray.wrap('•')} Check your internet connection');
    logger.info('   ${darkGray.wrap('•')} Verify DNS resolution is working');
    logger.info(
        '   ${darkGray.wrap('•')} Check if you\'re behind a proxy/firewall');
    logger.err(red.wrap('─' * 60));
    logger.info('');
  }

  /// Formate une erreur de format
  void _formatFormatException(FormatException error) {
    logger.info('');
    logger.err('${styleBold.wrap('📄 Format Error')}');
    logger.err(red.wrap('─' * 60));
    logger.err('');
    logger.err('Invalid data format detected');
    logger.info('');
    logger.info('${darkGray.wrap('Message:')} ${error.message}');
    if (error.source != null) {
      logger.info('${darkGray.wrap('Source:')} ${error.source}');
    }
    logger.err(red.wrap('─' * 60));
    logger.info('');
  }

  /// Formate une erreur générique
  void _formatGenericException(dynamic error, StackTrace? stackTrace) {
    logger.info('');
    logger.err('${styleBold.wrap('⚠️  Unexpected Error')}');
    logger.err(red.wrap('─' * 60));
    logger.err('');
    logger.err(error.toString());

    if (verbose && stackTrace != null) {
      logger.info('');
      logger.info(darkGray.wrap('Stack trace:'));
      final stackLines = stackTrace.toString().split('\n').take(10);
      for (final line in stackLines) {
        logger.info(darkGray.wrap('  $line'));
      }
    }

    logger.info('');
    logger.info(yellow.wrap('💡 This might be a bug. Please report it:'));
    logger.info('   ${cyan.wrap('https://github.com/meragix/cura/issues')}');
    logger.err(red.wrap('─' * 60));
    logger.info('');
  }

  /// Retourne l'emoji approprié selon le code d'erreur
  String _getErrorEmoji(String code) {
    switch (code) {
      case 'PACKAGE_NOT_FOUND':
        return '📦';
      case 'NETWORK_ERROR':
        return '🌐';
      case 'RATE_LIMIT':
        return '⏱️';
      case 'PARSE_ERROR':
        return '📄';
      case 'VALIDATION_ERROR':
        return '✖️';
      case 'CACHE_ERROR':
        return '💾';
      default:
        return '⚠️';
    }
  }

  /// Retourne des suggestions contextuelles selon le type d'erreur
  List<String> _getSuggestions(CuraException error) {
    if (error is PackageNotFoundException) {
      return [
        'Verify the package name is spelled correctly',
        'Check if the package exists on pub.dev',
        'Use ${cyan.wrap('cura search <keyword>')} to find similar packages',
      ];
    }

    if (error is RateLimitException) {
      final retryAfter = error.retryAfter;
      return [
        if (retryAfter != null)
          'Wait ${retryAfter.difference(DateTime.now()).inSeconds} seconds before retrying',
        'Use ${cyan.wrap('--use-cache')} to reduce API calls',
        'Consider using a GitHub token for higher rate limits',
      ];
    }

    if (error is NetworkException) {
      return [
        'Check your internet connection',
        'Verify pub.dev is accessible',
        'Try using ${cyan.wrap('--offline')} mode with cached data',
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
      return error.validationErrors.map((e) => e).toList();
    }

    return [];
  }
}
