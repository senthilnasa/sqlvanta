import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../mysql/mysql_query_executor.dart';

/// Renders MySQL EXPLAIN output with color-coded `type` column,
/// a relative "rows scanned" bar, and key/extra highlighting.
class ResultsExplainTab extends StatelessWidget {
  final AsyncValue<QueryResult?> explainAsync;

  const ResultsExplainTab({super.key, required this.explainAsync});

  @override
  Widget build(BuildContext context) {
    return explainAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error: $e',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
      data: (result) {
        if (result == null) {
          return _EmptyExplain();
        }
        if (result.isError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                result.errorMessage ?? 'Unknown error',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          );
        }
        return _ExplainTable(result: result);
      },
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyExplain extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schema_outlined,
            size: 40,
            color: cs.onSurface.withAlpha(40),
          ),
          const SizedBox(height: 12),
          Text(
            'Press Ctrl+Shift+E or click Explain to analyse a query',
            style: TextStyle(fontSize: 13, color: cs.onSurface.withAlpha(100)),
          ),
        ],
      ),
    );
  }
}

// ── EXPLAIN table ─────────────────────────────────────────────────────────────

class _ExplainTable extends StatelessWidget {
  final QueryResult result;
  const _ExplainTable({required this.result});

  // EXPLAIN access type → color + description
  static const _typeInfo = {
    'all': (
      label: 'ALL',
      color: Color(0xFFE53935),
      tip: 'Full table scan — worst',
    ),
    'index': (label: 'index', color: Color(0xFFFF7043), tip: 'Full index scan'),
    'range': (
      label: 'range',
      color: Color(0xFFFB8C00),
      tip: 'Index range scan',
    ),
    'ref': (
      label: 'ref',
      color: Color(0xFF7CB342),
      tip: 'Non-unique index lookup',
    ),
    'ref_or_null': (
      label: 'ref_or_null',
      color: Color(0xFF7CB342),
      tip: 'ref including NULL rows',
    ),
    'fulltext': (
      label: 'FULLTEXT',
      color: Color(0xFF00897B),
      tip: 'FULLTEXT index',
    ),
    'eq_ref': (
      label: 'eq_ref',
      color: Color(0xFF43A047),
      tip: 'Unique index lookup per row',
    ),
    'const': (
      label: 'const',
      color: Color(0xFF1E88E5),
      tip: 'Single row (PK/UNIQUE)',
    ),
    'system': (
      label: 'system',
      color: Color(0xFF1E88E5),
      tip: 'Single row table',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (result.columns.isEmpty || result.rows.isEmpty) {
      return const Center(
        child: Text('No EXPLAIN output', style: TextStyle(fontSize: 12)),
      );
    }

    // Find max rows value for the bar chart
    final rowsColIdx = result.columns.indexWhere(
      (c) => c.toLowerCase() == 'rows',
    );
    final maxRows =
        rowsColIdx >= 0
            ? result.rows
                .map((r) => int.tryParse(r[rowsColIdx]?.toString() ?? '') ?? 0)
                .fold<int>(1, (a, b) => a > b ? a : b)
            : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Legend ────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: cs.surfaceContainerHighest,
          child: Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _LegendItem(color: const Color(0xFFE53935), label: 'ALL (worst)'),
              _LegendItem(color: const Color(0xFFFF7043), label: 'index'),
              _LegendItem(color: const Color(0xFFFB8C00), label: 'range'),
              _LegendItem(color: const Color(0xFF7CB342), label: 'ref'),
              _LegendItem(color: const Color(0xFF43A047), label: 'eq_ref'),
              _LegendItem(
                color: const Color(0xFF1E88E5),
                label: 'const/system (best)',
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── Data table ────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                headingRowHeight: 32,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 36,
                headingRowColor: WidgetStateProperty.all(
                  cs.surfaceContainerHighest,
                ),
                columns:
                    result.columns
                        .map(
                          (col) => DataColumn(
                            label: Text(
                              col,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                rows:
                    result.rows.map((row) {
                      return DataRow(
                        cells: List.generate(result.columns.length, (i) {
                          final colName = result.columns[i].toLowerCase();
                          final val =
                              i < row.length ? (row[i]?.toString() ?? '') : '';

                          if (colName == 'type') {
                            return DataCell(_TypeBadge(type: val));
                          }

                          if (colName == 'rows' && rowsColIdx >= 0) {
                            final n = int.tryParse(val) ?? 0;
                            return DataCell(
                              _RowsBar(
                                value: n,
                                max: maxRows,
                                isDark: isDark,
                                cs: cs,
                              ),
                            );
                          }

                          if (colName == 'key' &&
                              val.isNotEmpty &&
                              val != 'null') {
                            return DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.vpn_key_outlined,
                                    size: 11,
                                    color: Colors.amber.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    val,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      color: Colors.amber.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (colName == 'extra' && val.isNotEmpty) {
                            return DataCell(
                              Tooltip(
                                message: val,
                                child: Text(
                                  val.length > 30
                                      ? '${val.substring(0, 30)}…'
                                      : val,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    color:
                                        val.toLowerCase().contains(
                                                  'filesort',
                                                ) ||
                                                val.toLowerCase().contains(
                                                  'temporary',
                                                )
                                            ? Colors.orange.shade700
                                            : cs.onSurface.withAlpha(200),
                                  ),
                                ),
                              ),
                            );
                          }

                          return DataCell(
                            Text(
                              val.isEmpty || val == 'null' ? '—' : val,
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color:
                                    val.isEmpty || val == 'null'
                                        ? cs.onSurface.withAlpha(80)
                                        : null,
                              ),
                            ),
                          );
                        }),
                      );
                    }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final info = _ExplainTable._typeInfo[type.toLowerCase()];
    final color = info?.color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    final tip = info?.tip ?? type;

    return Tooltip(
      message: tip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withAlpha(120)),
        ),
        child: Text(
          type.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _RowsBar extends StatelessWidget {
  final int value;
  final int max;
  final bool isDark;
  final ColorScheme cs;

  const _RowsBar({
    required this.value,
    required this.max,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    final barColor =
        ratio > 0.7
            ? Colors.red.shade400
            : ratio > 0.3
            ? Colors.orange.shade400
            : Colors.green.shade500;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 60,
          height: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: cs.surfaceContainerHighest,
              color: barColor,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          _fmt(value),
          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
        ),
      ],
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withAlpha(60),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
