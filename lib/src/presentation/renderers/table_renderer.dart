import 'package:cura/src/domain/models/cura_score.dart';
import 'package:cura/src/domain/models/package_health.dart';
import 'package:cura/src/presentation/loggers/cura_logger.dart';
import 'package:mason_logger/mason_logger.dart';

/// Renderer pour les tableaux ASCII
class TableRenderer {
  final CuraLogger logger;

  TableRenderer({required this.logger});

  void render(List<PackageHealth> data) {
    // Trier : critiques en bas pour visibilité
    final sorted = data.toList()..sort((a, b) => b.score.total.compareTo(a.score.total));

    _printHeader();

    // Rows (afficher les 10 premiers et derniers)
    final toShow = sorted.length <= 15
        ? sorted
        : [
            ...sorted.take(7),
            ...sorted.skip(sorted.length - 3),
          ];

    var previousIndex = -1;
    for (var i = 0; i < toShow.length; i++) {
      final result = toShow[i];
      final currentIndex = sorted.indexOf(result);

      // Afficher "..." si on a sauté des lignes
      if (previousIndex != -1 && currentIndex - previousIndex > 1) {
        _printEllipsisRow();
      }

      _printRow(result);
      previousIndex = currentIndex;
    }

    _printFooter();
  }

  void _printHeader() {
    final divider = '┌${'─' * 24}┬${'─' * 7}┬${'─' * 8}┬${'─' * 14}┐';
    logger.info(divider);

    //final header = '│ Package                │ Score │ Status │ Last Update  │';
    final header = '│ ${'Package'.padRight(22)} │ Score │ Status │ Last Update  │';
    logger.info(styleBold.wrap(header)!);

    final headerDivider = '├${'─' * 24}┼${'─' * 7}┼${'─' * 8}┼${'─' * 14}┤';
    logger.info(headerDivider);
  }

  void _printRow(PackageHealth item) {
    final name = _truncate(item.info.name, 22).padRight(22);
    final score = item.score.total.toString().padLeft(3);
    final statusEmoji = _getStatusEmoji(item.score.status).padRight(6);
    //final lastUpdate = DateFormatter.formatDaysAgo(item.info.published).padRight(12);
    final stableEmoji = item.info.isFlutterFavorite ? ' ⭐' : ''; // todo: change to isStable

    //final row = '│ $name │  $score  │ $statusEmoji │ $lastUpdate$stableEmoji │';

    // Colorer la ligne selon le status
    //final coloredRow = _colorizeRow(row, item.score.status);
    //logger.info(coloredRow);
  }

  void _printEllipsisRow() {
    logger.info('│ ...                    │  ...  │  ...   │ ...          │');
  }

  void _printFooter() {
    final divider = '└${'─' * 24}┴${'─' * 7}┴${'─' * 8}┴${'─' * 14}┘';
    logger.info(divider);

    // Légende
    final legend = '${styleItalic.wrap('Legend')}: ${yellow.wrap('⭐ Stable package')}  '
        '${yellow.wrap('! Needs review')}  '
        '${red.wrap('✗ Critical')}';
    logger.info(legend);
  }

  // String _truncate(String text, int max) {
  //   return text.length > max ? '${text.substring(0, max - 3)}...' : text;
  // }
  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  String _colorizeRow(String row, HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy:
        return row; // Pas de couleur pour healthy
      case HealthStatus.warning:
        return yellow.wrap(row)!;
      case HealthStatus.critical:
        return red.wrap(row)!;
    }
  }

  String _getStatusEmoji(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy:
        return '✓';
      case HealthStatus.warning:
        return '!';
      case HealthStatus.critical:
        return '✗';
    }
  }
}
