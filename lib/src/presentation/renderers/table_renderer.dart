import 'package:cli_table/cli_table.dart';
import 'package:cura/src/domain/entities/package_audit_result.dart';
import 'package:cura/src/presentation/formatters/date_formatter.dart';
import 'package:mason_logger/mason_logger.dart';

class TableRenderer {
  final bool _useColors;

  const TableRenderer({bool useColors = true}) : _useColors = useColors;

  /// Render audit results as table
  String renderAuditTable(List<PackageAuditResult> results) {
    // Sort: reviews at the bottom for visibility
    final sorted = results.toList()..sort((a, b) => b.score.total.compareTo(a.score.total));

    final table = Table(
      header: [
        'Package',
        'Score',
        'Status',
        'Last Update',
      ],
      columnWidths: [25, 7, 8, 15],
      // style: TableStyle(
      //   border: _useColors ? _coloredBorder() : _plainBorder(),
      // ),
    );

    // Rows (display the first and last 15)
    final showAll = sorted.length <= 15;

    final top = showAll ? sorted : sorted.take(7).toList();
    final bottom = showAll ? <PackageAuditResult>[] : sorted.skip(sorted.length - 3).toList();

    void _addRows(Table table, List<PackageAuditResult> list) {
      for (final result in list) {
        table.add([
          _formatPackageName(result),
          _formatScore(result.score.total),
          _formatStatus(result.status, result.packageInfo.isStable),
          _formatLastUpdate(result.packageInfo.daysSinceLastUpdate),
        ]);
      }
    }

    _addRows(table, top);

    if (!showAll) {
      table.add(['...', '...', '...', '...']);
      _addRows(table, bottom);
    }

    return table.toString();
  }

  /// Render summary table
  String renderSummaryTable({
    required int healthy,
    required int warning,
    required int critical,
    required int total,
    required int overallScore,
  }) {
    final healthyPct = (healthy / total * 100).round();
    final warningPct = (warning / total * 100).round();
    final criticalPct = (critical / total * 100).round();

    final table = Table(
      header: ['Category', 'Count', 'Percentage'],
      columnWidths: [15, 8, 12],
      //style: TableStyle(border: _plainBorder()),
    );

    table.add([
      _colorStatus('✅ Healthy', green),
      '$healthy packages',
      '$healthyPct%',
    ]);

    if (warning > 0) {
      table.add([
        _colorStatus('⚠️  Warning', yellow),
        '$warning packages',
        '$warningPct%',
      ]);
    }

    if (critical > 0) {
      table.add([
        _colorStatus('❌ Critical', red),
        '$critical packages',
        '$criticalPct%',
      ]);
    }

    return table.toString();
  }

  // ==========================================================================
  // FORMATTERS
  // ==========================================================================

  String _formatPackageName(PackageAuditResult result) {
    var name = result.name;

    // Truncate if too long
    if (name.length > 22) {
      name = '${name.substring(0, 19)}...';
    }

    return _useColors ? cyan.wrap(name)! : name;
  }

  String _formatScore(int score) {
    final scoreStr = score.toString().padLeft(3);

    if (!_useColors) return scoreStr;

    // Color based on score
    if (score >= 90) return green.wrap(scoreStr)!;
    if (score >= 70) return lightGreen.wrap(scoreStr)!;
    if (score >= 50) return yellow.wrap(scoreStr)!;
    return red.wrap(scoreStr)!;
  }

  String _formatStatus(AuditStatus status, bool isStable) {
    final icon = switch (status) {
      AuditStatus.excellent => '  ✓',
      AuditStatus.good => '  ✓',
      AuditStatus.warning => '  !',
      AuditStatus.critical => '  ✗',
      AuditStatus.discontinued => '  ✗',
    };

    // Add star for stable packages
    // final suffix = isStable ? ' ⭐' : '';

    if (!_useColors) return '$icon';

    final colored = switch (status) {
      AuditStatus.excellent || AuditStatus.good => green.wrap(icon),
      AuditStatus.warning => yellow.wrap(icon),
      AuditStatus.critical || AuditStatus.discontinued => red.wrap(icon),
    };

    return '$colored';
  }

  String _formatLastUpdate(int days) {
    final formatted = DateFormatter.formatCompactDays(days);

    if (!_useColors) return formatted;

    // Color based on age
    if (days <= 90) return green.wrap(formatted)!;
    if (days <= 365) return lightGreen.wrap(formatted)!;
    if (days <= 730) return yellow.wrap(formatted)!;
    return red.wrap(formatted)!;
  }

  String _colorStatus(String text, AnsiCode color) {
    return _useColors ? color.wrap(text)! : text;
  }
}
