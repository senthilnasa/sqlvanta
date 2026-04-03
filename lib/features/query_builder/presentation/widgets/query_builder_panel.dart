import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../mysql/mysql_schema_fetcher.dart';
import '../../../query_editor/presentation/providers/query_editor_providers.dart';
import '../../../workspace/domain/entities/workspace_session.dart';
import '../../../workspace/presentation/providers/workspace_provider.dart';

/// Visual query builder — picks table, columns, WHERE, ORDER BY, LIMIT
/// and sends the generated SQL to the active query editor tab.
class QueryBuilderPanel extends ConsumerStatefulWidget {
  final WorkspaceSession session;
  final String tabId;

  const QueryBuilderPanel({
    super.key,
    required this.session,
    required this.tabId,
  });

  @override
  ConsumerState<QueryBuilderPanel> createState() => _QueryBuilderPanelState();
}

class _QueryBuilderPanelState extends ConsumerState<QueryBuilderPanel> {
  final _fetcher = const MysqlSchemaFetcher();

  // ── Picker state ──────────────────────────────────────────────────────────
  List<String> _databases = [];
  List<String> _tables = [];
  String? _selectedDb;
  String? _selectedTable;

  // ── Column state ──────────────────────────────────────────────────────────
  List<ColumnInfo> _columns = [];
  final Set<String> _selectedCols = {};
  bool _selectAll = true;

  // ── WHERE conditions ──────────────────────────────────────────────────────
  final List<_WhereRow> _where = [];

  // ── ORDER BY ──────────────────────────────────────────────────────────────
  String? _orderByCol;
  bool _orderAsc = true;

  // ── LIMIT ─────────────────────────────────────────────────────────────────
  final _limitCtrl = TextEditingController(text: '1000');

  // ── Generated SQL ─────────────────────────────────────────────────────────
  String _generatedSql = '';

  @override
  void initState() {
    super.initState();
    _loadDatabases();
  }

  @override
  void dispose() {
    _limitCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDatabases() async {
    try {
      final dbs =
          await _fetcher.fetchAllDatabases(widget.session.mysqlConnection);
      if (!mounted) return;
      setState(() => _databases = dbs.map((d) => d.name).toList());
    } catch (_) {}
  }

  Future<void> _loadTables(String db) async {
    setState(() {
      _tables = [];
      _selectedTable = null;
      _columns = [];
      _selectedCols.clear();
      _where.clear();
      _orderByCol = null;
      _generatedSql = '';
    });
    try {
      final tables =
          await _fetcher.fetchTables(widget.session.mysqlConnection, db);
      if (!mounted) return;
      setState(() => _tables = tables.map((t) => t.name).toList());
    } catch (_) {}
  }

  Future<void> _loadColumns(String db, String table) async {
    setState(() {
      _columns = [];
      _selectedCols.clear();
      _where.clear();
      _orderByCol = null;
      _generatedSql = '';
    });
    try {
      final cols = await _fetcher.fetchColumns(
          widget.session.mysqlConnection, db, table);
      if (!mounted) return;
      setState(() {
        _columns = cols;
        _selectedCols.addAll(cols.map((c) => c.name));
        _selectAll = true;
      });
      _rebuild();
    } catch (_) {}
  }

  void _rebuild() {
    if (_selectedDb == null || _selectedTable == null) return;
    final db = _selectedDb!;
    final table = _selectedTable!;

    // SELECT clause
    final cols = _selectAll
        ? '*'
        : _selectedCols.isEmpty
            ? '*'
            : _selectedCols.map((c) => '`$c`').join(', ');

    // WHERE clause
    final whereRows = _where
        .where((r) => r.column.isNotEmpty && r.value.text.isNotEmpty)
        .toList();
    final whereLines = whereRows
        .asMap()
        .entries
        .map((e) {
          final prefix = e.key == 0 ? '' : '${e.value.logic} ';
          return '$prefix`${e.value.column}` ${e.value.op} \'${e.value.value.text}\'';
        })
        .join('\n  ');
    final whereClause = whereRows.isEmpty ? '' : '\nWHERE $whereLines';

    // ORDER BY
    final orderClause = _orderByCol == null
        ? ''
        : '\nORDER BY `$_orderByCol` ${_orderAsc ? 'ASC' : 'DESC'}';

    // LIMIT
    final limit = int.tryParse(_limitCtrl.text) ?? 1000;
    final limitClause = '\nLIMIT $limit';

    setState(() {
      _generatedSql =
          'SELECT $cols\nFROM `$db`.`$table`$whereClause$orderClause$limitClause;';
    });
  }

  void _sendToEditor() {
    if (_generatedSql.isEmpty) return;
    // Find the nearest query tab to send the SQL to
    final session = ref.read(workspaceProvider)[widget.session.sessionId];
    if (session == null) return;
    // Use the first query-type tab, or the active tab
    final queryTab = session.tabs
        .where((t) => t.type.name == 'query')
        .firstOrNull;
    final targetTabId = queryTab?.id ?? session.activeTabId;
    if (targetTabId == null) return;
    ref.read(editorContentProvider(targetTabId).notifier).update(_generatedSql);
    // Also switch to that tab
    ref.read(workspaceProvider.notifier)
        .setActiveTab(widget.session.sessionId, targetTabId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        // ── Left: pickers + columns ──────────────────────────────────────────
        SizedBox(
          width: 260,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionBar(label: 'Table', icon: Icons.table_rows_outlined),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SmallDropdown(
                      hint: 'Database',
                      value: _selectedDb,
                      items: _databases,
                      icon: Icons.storage_outlined,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _selectedDb = v);
                        _loadTables(v);
                      },
                    ),
                    const SizedBox(height: 6),
                    _SmallDropdown(
                      hint: 'Table / View',
                      value: _selectedTable,
                      items: _tables,
                      icon: Icons.table_rows_outlined,
                      onChanged: (v) {
                        if (v == null || _selectedDb == null) return;
                        setState(() => _selectedTable = v);
                        _loadColumns(_selectedDb!, v);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _SectionBar(label: 'Columns (SELECT)', icon: Icons.view_column_outlined),
              Expanded(
                child: _columns.isEmpty
                    ? Center(
                        child: Text('Select a table',
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withAlpha(100))),
                      )
                    : ListView(
                        children: [
                          CheckboxListTile(
                            dense: true,
                            value: _selectAll,
                            title: const Text('* (all columns)',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (v) {
                              setState(() {
                                _selectAll = v ?? true;
                                if (_selectAll) {
                                  _selectedCols.addAll(
                                      _columns.map((c) => c.name));
                                } else {
                                  _selectedCols.clear();
                                }
                              });
                              _rebuild();
                            },
                          ),
                          ..._columns.map((col) {
                            final isPk = col.extra
                                    ?.toLowerCase()
                                    .contains('auto_increment') ??
                                false;
                            return CheckboxListTile(
                              dense: true,
                              value: _selectedCols.contains(col.name),
                              title: Row(
                                children: [
                                  if (isPk)
                                    Icon(Icons.vpn_key,
                                        size: 11,
                                        color: Colors.amber.shade600),
                                  if (isPk) const SizedBox(width: 4),
                                  Text(col.name,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'monospace')),
                                  const SizedBox(width: 6),
                                  Text(col.dataType,
                                      style: TextStyle(
                                          fontSize: 9,
                                          color:
                                              cs.onSurface.withAlpha(100))),
                                ],
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selectedCols.add(col.name);
                                  } else {
                                    _selectedCols.remove(col.name);
                                    _selectAll = false;
                                  }
                                });
                                _rebuild();
                              },
                            );
                          }),
                        ],
                      ),
              ),
            ],
          ),
        ),

        const VerticalDivider(width: 1),

        // ── Right: WHERE / ORDER / LIMIT / SQL ───────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // WHERE
              _SectionBar(
                label: 'WHERE Conditions',
                icon: Icons.filter_alt_outlined,
                trailing: _columns.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.add, size: 16),
                        tooltip: 'Add condition',
                        onPressed: () {
                          setState(() => _where.add(_WhereRow(
                              column: _columns.first.name)));
                          _rebuild();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 28, minHeight: 28),
                      ),
              ),
              if (_where.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('No conditions — returns all rows',
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withAlpha(100))),
                )
              else
                ..._where.asMap().entries.map((entry) {
                  final i = entry.key;
                  final row = entry.value;
                  return _WhereRowWidget(
                    row: row,
                    index: i,
                    columns: _columns.map((c) => c.name).toList(),
                    onChanged: () => _rebuild(),
                    onRemove: () {
                      setState(() => _where.removeAt(i));
                      _rebuild();
                    },
                  );
                }),

              const Divider(height: 1),

              // ORDER BY + LIMIT
              _SectionBar(
                  label: 'Sort & Limit', icon: Icons.sort_outlined),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    const Text('ORDER BY',
                        style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SmallDropdown(
                        hint: '(none)',
                        value: _orderByCol,
                        items: ['', ..._columns.map((c) => c.name)],
                        icon: Icons.swap_vert,
                        onChanged: (v) {
                          setState(
                              () => _orderByCol = v?.isEmpty == true ? null : v);
                          _rebuild();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                            value: true,
                            label: Text('ASC',
                                style: TextStyle(fontSize: 10))),
                        ButtonSegment(
                            value: false,
                            label: Text('DESC',
                                style: TextStyle(fontSize: 10))),
                      ],
                      selected: {_orderAsc},
                      onSelectionChanged: (v) {
                        setState(() => _orderAsc = v.first);
                        _rebuild();
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text('LIMIT',
                        style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 70,
                      child: TextField(
                        controller: _limitCtrl,
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _rebuild(),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Generated SQL
              _SectionBar(
                label: 'Generated SQL',
                icon: Icons.code,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.send_outlined, size: 14),
                      label: const Text('Send to Editor',
                          style: TextStyle(fontSize: 11)),
                      onPressed: _generatedSql.isEmpty ? null : _sendToEditor,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF1E1E1E)
                        : const Color(0xFFFCFCFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: SelectableText(
                    _generatedSql.isEmpty
                        ? '-- Select a database and table to build a query'
                        : _generatedSql,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.6,
                      color: _generatedSql.isEmpty
                          ? cs.onSurface.withAlpha(80)
                          : cs.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── WHERE row model ───────────────────────────────────────────────────────────

class _WhereRow {
  String column;
  String op = '=';
  String logic = 'AND';
  final TextEditingController value;

  _WhereRow({required this.column}) : value = TextEditingController();

  void dispose() => value.dispose();
}

// ── WHERE row widget ──────────────────────────────────────────────────────────

class _WhereRowWidget extends StatelessWidget {
  final _WhereRow row;
  final int index;
  final List<String> columns;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  static const _ops = ['=', '!=', '<', '>', '<=', '>=', 'LIKE', 'NOT LIKE',
      'IS NULL', 'IS NOT NULL'];

  const _WhereRowWidget({
    required this.row,
    required this.index,
    required this.columns,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Row(
        children: [
          // AND/OR toggle (not shown for first row)
          if (index > 0)
            SizedBox(
              width: 52,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: row.logic,
                  isDense: true,
                  style: const TextStyle(fontSize: 11),
                  items: ['AND', 'OR']
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (v) {
                    row.logic = v ?? 'AND';
                    onChanged();
                  },
                ),
              ),
            )
          else
            const SizedBox(width: 52),
          const SizedBox(width: 6),
          // Column
          Expanded(
            flex: 3,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: columns.contains(row.column) ? row.column : null,
                isDense: true,
                isExpanded: true,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                hint: const Text('Column', style: TextStyle(fontSize: 11)),
                items: columns
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  row.column = v ?? '';
                  onChanged();
                },
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Operator
          SizedBox(
            width: 90,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: row.op,
                isDense: true,
                style: const TextStyle(fontSize: 11),
                items: _ops
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                onChanged: (v) {
                  row.op = v ?? '=';
                  onChanged();
                },
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Value
          Expanded(
            flex: 2,
            child: TextField(
              controller: row.value,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'value',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close, size: 14),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _SectionBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget? trailing;

  const _SectionBar(
      {required this.label, required this.icon, this.trailing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 28,
      color: cs.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(icon, size: 13, color: cs.primary),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _SmallDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final IconData icon;
  final void Function(String?) onChanged;

  const _SmallDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: (value != null && items.contains(value)) ? value : null,
        hint: Row(
          children: [
            Icon(icon, size: 12, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(hint,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ],
        ),
        isDense: true,
        isExpanded: true,
        style: const TextStyle(fontSize: 11),
        borderRadius: BorderRadius.circular(6),
        items: items
            .map((s) => DropdownMenuItem(
                value: s,
                child: Text(s, overflow: TextOverflow.ellipsis)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
