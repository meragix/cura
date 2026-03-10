import 'package:cli_table/cli_table.dart';
import 'package:cura/src/domain/entities/package_audit_result.dart';
import 'package:cura/src/presentation/formatters/date_formatter.dart';
import 'package:cura/src/presentation/themes/theme_manager.dart';

class TableRenderer {
  final bool _useColors;

  const TableRenderer({bool useColors = true}) : _useColors = useColors;

  /// Render audit results as table
  String renderAuditTable(List<PackageAuditResult> results) {
    // Sort: reviews at the bottom for visibility
    final sorted = results.toList()
      ..sort((a, b) => b.score.total.compareTo(a.score.total));

    final table = Table(
      header: [
        'Package',
        'Score',
        'Status',
        'Last Update',
      ],
      columnWidths: [25, 7, 8, 15],
    );

    // Rows (display the first and last 15)
    final showAll = sorted.length <= 15;

    final top = showAll ? sorted : sorted.take(7).toList();
    final bottom = showAll
        ? <PackageAuditResult>[]
        : sorted.skip(sorted.length - 3).toList();

    void addRows(Table table, List<PackageAuditResult> list) {
      for (final result in list) {
        table.add([
          _formatPackageName(result),
          _formatScore(result.score.total),
          _formatStatus(result.status, result.packageInfo.isStable),
          _formatLastUpdate(result.packageInfo.daysSinceLastUpdate),
        ]);
      }
    }

    addRows(table, top);

    if (!showAll) {
      table.add(['...', '...', '...', '...']);
      addRows(table, bottom);
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
    final theme = ThemeManager.current;
    final healthyPct = (healthy / total * 100).round();
    final warningPct = (warning / total * 100).round();
    final criticalPct = (critical / total * 100).round();

    final table = Table(
      header: ['Category', 'Count', 'Percentage'],
      columnWidths: [15, 8, 12],
    );

    table.add([
      _useColors ? theme.success.wrap('✅ Healthy')! : '✅ Healthy',
      '$healthy packages',
      '$healthyPct%',
    ]);

    if (warning > 0) {
      table.add([
        _useColors ? theme.warning.wrap('⚠️  Warning')! : '⚠️  Warning',
        '$warning packages',
        '$warningPct%',
      ]);
    }

    if (critical > 0) {
      table.add([
        _useColors ? theme.error.wrap('❌ Critical')! : '❌ Critical',
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
    final theme = ThemeManager.current;
    var name = result.name;

    // Truncate if too long
    if (name.length > 22) {
      name = '${name.substring(0, 19)}...';
    }

    return _useColors ? theme.primary.wrap(name)! : name;
  }

  String _formatScore(int score) {
    final theme = ThemeManager.current;
    final scoreStr = score.toString().padLeft(3);

    if (!_useColors) return scoreStr;

    if (score >= 90) return theme.scoreExcellent.wrap(scoreStr)!;
    if (score >= 70) return theme.scoreGood.wrap(scoreStr)!;
    if (score >= 50) return theme.scoreFair.wrap(scoreStr)!;
    return theme.scorePoor.wrap(scoreStr)!;
  }

  String _formatStatus(AuditStatus status, bool isStable) {
    final theme = ThemeManager.current;
    final icon = switch (status) {
      AuditStatus.excellent => '  ✓',
      AuditStatus.good => '  ✓',
      AuditStatus.warning => '  !',
      AuditStatus.critical => '  ✗',
      AuditStatus.discontinued => '  ✗',
    };

    if (!_useColors) return icon;

    final colored = switch (status) {
      AuditStatus.excellent || AuditStatus.good => theme.success.wrap(icon),
      AuditStatus.warning => theme.warning.wrap(icon),
      AuditStatus.critical || AuditStatus.discontinued =>
        theme.error.wrap(icon),
    };

    return colored ?? icon;
  }

  String _formatLastUpdate(int days) {
    final theme = ThemeManager.current;
    final formatted = DateFormatter.formatCompactDays(days);

    if (!_useColors) return formatted;

    if (days <= 90) return theme.scoreExcellent.wrap(formatted)!;
    if (days <= 365) return theme.scoreGood.wrap(formatted)!;
    if (days <= 730) return theme.scoreFair.wrap(formatted)!;
    return theme.scorePoor.wrap(formatted)!;
  }
}
