import 'package:flutter/material.dart';

import '../../../../mysql/mysql_query_executor.dart';
import '../../../../mysql/mysql_schema_fetcher.dart';
import '../../../workspace/domain/entities/workspace_session.dart';

/// SQLyog-style "Info" tab — shows query stats when a result is present,
/// plus table structure when a table name can be inferred from the SQL.
class ResultsInfoTab extends StatefulWidget {
  final QueryResult? result;
  final String? sourceSql;        // the SQL that produced the result
  final WorkspaceSession? session;

  const ResultsInfoTab({
    super.key,
    this.result,
    this.sourceSql,
    this.session,
  });

  @override
  State<ResultsInfoTab> createState() => _ResultsInfoTabState();
}

class _ResultsInfoTabState extends State<ResultsInfoTab> {
  final _fetcher = const MysqlSchemaFetcher();
  List<ColumnInfo>? _columns;
  bool _loadingCols = false;

  @override
  void didUpdateWidget(ResultsInfoTab old) {
    super.didUpdateWidget(old);
    if (old.sourceSql != widget.sourceSql) _columns = null;
    if (_columns == null && widget.sourceSql != null) _loadColumns();
  }

  @override
  void initState() {
    super.initState();
    if (widget.sourceSql != null) _loadColumns();
  }

  String? get _detectedDb => _extractDb(widget.sourceSql);
  String? get _detectedTable => _extractTable(widget.sourceSql);

  Future<void> _loadColumns() async {
    final db = _detectedDb;
    final table = _detectedTable;
    if (db == null || table == null || widget.session == null) return;
    setState(() => _loadingCols = true);
    try {
      final cols = await _fetcher.fetchColumns(
          widget.session!.mysqlConnection, db, table);
      if (mounted) setState(() { _columns = cols; _loadingCols = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingCols = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final result = widget.result;

    if (result == null) {
      return Center(
        child: Text('Run a query to see info.',
            style: TextStyle(fontSize: 12, color: cs.onSurface.withAlpha(120))),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // ── Query Statistics ───────────────────────────────────────────────
        _SectionHeader(title: 'Query Statistics', icon: Icons.query_stats),
        const SizedBox(height: 6),
        _StatCard(children: [
          _StatRow(
            icon: result.isError ? Icons.error_outline : Icons.check_circle_outline,
            iconColor: result.isError ? cs.error : Colors.green.shade500,
            label: 'Status',
            value: result.isError ? 'Error' : 'Success',
          ),
          _StatRow(
            icon: Icons.timer_outlined,
            label: 'Execution time',
            value: '${result.duration.inMilliseconds} ms',
          ),
          if (result.hasData) ...[
            _StatRow(
              icon: Icons.table_rows_outlined,
              label: 'Rows returned',
              value: '${result.rowCount}'
                  '${result.rowCount >= 1000 ? '  (limit reached)' : ''}',
            ),
            _StatRow(
              icon: Icons.view_column_outlined,
              label: 'Columns',
              value: '${result.columns.length}',
            ),
          ] else ...[
            _StatRow(
              icon: Icons.edit_outlined,
              label: 'Rows affected',
              value: '${result.affectedRows ?? 0}',
            ),
          ],
        ]),

        // ── Error detail ────────────────────────────────────────────────────
        if (result.isError) ...[
          const SizedBox(height: 12),
          _SectionHeader(title: 'Error Detail', icon: Icons.bug_report_outlined),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.errorContainer.withAlpha(60),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: cs.error.withAlpha(60)),
            ),
            child: SelectableText(
              result.errorMessage ?? '',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: cs.error,
                height: 1.5,
              ),
            ),
          ),
        ],

        // ── Table structure ─────────────────────────────────────────────────
        if (_detectedTable != null) ...[
          const SizedBox(height: 12),
          _SectionHeader(
            title: 'Table Structure'
                '${_detectedDb != null ? '  (`$_detectedDb`.`$_detectedTable`)' : '  (`$_detectedTable`)'}',
            icon: Icons.schema_outlined,
          ),
          const SizedBox(height: 6),
          if (_loadingCols)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_columns != null && _columns!.isNotEmpty)
            _ColumnsTable(columns: _columns!, cs: cs)
          else
            Text('Could not load columns.',
                style: TextStyle(fontSize: 11, color: cs.onSurface.withAlpha(120))),
        ],
      ],
    );
  }

  static String? _extractDb(String? sql) {
    if (sql == null) return null;
    final m = RegExp(r'\bFROM\b\s+`?(\w+)`?\.`?\w+`?',
        caseSensitive: false).firstMatch(sql);
    return m?.group(1);
  }

  static String? _extractTable(String? sql) {
    if (sql == null) return null;
    final m = RegExp(r'\bFROM\b\s+(?:`?\w+`?\.)?`?(\w+)`?',
        caseSensitive: false).firstMatch(sql);
    return m?.group(1);
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: cs.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: cs.outlineVariant)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final List<Widget> children;
  const _StatCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(children: children),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;
  const _StatRow({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor ?? cs.onSurfaceVariant),
          const SizedBox(width: 8),
          SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12, color: cs.onSurface.withAlpha(160))),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _ColumnsTable extends StatelessWidget {
  final List<ColumnInfo> columns;
  final ColorScheme cs;
  const _ColumnsTable({required this.columns, required this.cs});

  @override
  Widget build(BuildContext context) {
    final header = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: cs.onSurface.withAlpha(160),
    );
    final cell = const TextStyle(fontSize: 11, fontFamily: 'monospace');

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(2),
          2: FixedColumnWidth(60),
          3: FlexColumnWidth(2),
          4: FlexColumnWidth(2),
        },
        border: TableBorder.symmetric(
          inside: BorderSide(color: cs.outlineVariant),
        ),
        children: [
          // Header
          TableRow(
            decoration: BoxDecoration(color: cs.surfaceContainerHighest),
            children: [
              _Cell('Column', style: header),
              _Cell('Type', style: header),
              _Cell('Null', style: header),
              _Cell('Default', style: header),
              _Cell('Extra', style: header),
            ],
          ),
          // Rows
          ...columns.map((col) {
            final isPk = col.extra?.toLowerCase().contains('auto_increment') ?? false;
            return TableRow(
              children: [
                _Cell(
                  col.name,
                  style: cell.copyWith(
                    fontWeight: isPk ? FontWeight.w700 : FontWeight.normal,
                    color: isPk ? cs.primary : null,
                  ),
                  leading: isPk
                      ? Icon(Icons.vpn_key_outlined,
                          size: 10, color: Colors.amber.shade600)
                      : null,
                ),
                _Cell(col.dataType, style: cell.copyWith(color: cs.secondary)),
                _Cell(col.isNullable ? 'YES' : 'NO',
                    style: cell.copyWith(
                        color: col.isNullable ? null : cs.error)),
                _Cell(col.columnDefault ?? '', style: cell),
                _Cell(col.extra ?? '', style: cell),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Widget? leading;
  const _Cell(this.text, {this.style, this.leading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 4)],
          Expanded(
            child: Text(text, style: style, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
