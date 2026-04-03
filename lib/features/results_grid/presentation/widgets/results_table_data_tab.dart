import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';

import '../../../../mysql/mysql_query_executor.dart';
import '../../../../mysql/mysql_schema_fetcher.dart';
import '../../../workspace/domain/entities/workspace_session.dart';
import '../providers/selected_table_provider.dart';

/// SQLyog-style "Table Data" tab.
/// • Double-clicking a table in the object browser sets [selectedTableProvider],
///   which this tab watches to auto-load the data.
/// • Date/datetime columns show a date-picker on edit.
/// • FK columns show a row-picker popup to choose from the referenced table.
class ResultsTableDataTab extends ConsumerStatefulWidget {
  final WorkspaceSession session;

  const ResultsTableDataTab({super.key, required this.session});

  @override
  ConsumerState<ResultsTableDataTab> createState() =>
      _ResultsTableDataTabState();
}

class _ResultsTableDataTabState extends ConsumerState<ResultsTableDataTab> {
  final _fetcher = const MysqlSchemaFetcher();
  final _executor = const MysqlQueryExecutor(maxRows: 1000);

  // ── Picker state ──────────────────────────────────────────────────────────
  List<String> _databases = [];
  List<String> _tables = [];
  String? _selectedDb;
  String? _selectedTable;

  final _firstRowCtrl = TextEditingController(text: '0');
  final _numRowsCtrl = TextEditingController(text: '1000');

  // ── Schema cache for the current table ───────────────────────────────────
  List<ColumnInfo> _columnSchema = [];
  List<ForeignKeyInfo> _foreignKeys = [];

  // ── Grid state ────────────────────────────────────────────────────────────
  QueryResult? _result;
  bool _loading = false;
  String? _error;
  PlutoGridStateManager? _stateManager;

  @override
  void initState() {
    super.initState();
    _loadDatabases();
  }

  @override
  void dispose() {
    _firstRowCtrl.dispose();
    _numRowsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDatabases() async {
    try {
      final dbs = await _fetcher.fetchAllDatabases(
        widget.session.mysqlConnection,
      );
      if (mounted) {
        setState(() => _databases = dbs.map((d) => d.name).toList());
      }
    } catch (_) {}
  }

  Future<void> _loadTables(String db) async {
    setState(() {
      _tables = [];
      _selectedTable = null;
      _result = null;
      _error = null;
      _columnSchema = [];
      _foreignKeys = [];
    });
    try {
      final tables = await _fetcher.fetchTables(
        widget.session.mysqlConnection,
        db,
      );
      if (mounted) {
        setState(() => _tables = tables.map((t) => t.name).toList());
      }
    } catch (_) {}
  }

  Future<void> _loadSchema(String db, String table) async {
    try {
      final cols = await _fetcher.fetchColumns(
        widget.session.mysqlConnection,
        db,
        table,
      );
      final fks = await _fetcher.fetchForeignKeys(
        widget.session.mysqlConnection,
        db,
      );
      if (mounted) {
        setState(() {
          _columnSchema = cols;
          _foreignKeys = fks.where((fk) => fk.table == table).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    if (_selectedDb == null || _selectedTable == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    await _loadSchema(_selectedDb!, _selectedTable!);

    final offset = int.tryParse(_firstRowCtrl.text) ?? 0;
    final limit = int.tryParse(_numRowsCtrl.text) ?? 1000;
    final sql =
        'SELECT * FROM `$_selectedDb`.`$_selectedTable` LIMIT $limit OFFSET $offset';

    final result = await _executor.execute(widget.session.mysqlConnection, sql);

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.isError) {
        _error = result.errorMessage;
      } else {
        _result = result;
      }
    });
  }

  // ── Helper: is this column a date/datetime type? ──────────────────────────
  bool _isDateCol(String colName) {
    final info =
        _columnSchema
            .where((c) => c.name.toLowerCase() == colName.toLowerCase())
            .firstOrNull;
    if (info == null) return false;
    final dt = info.dataType.toLowerCase();
    return dt == 'date' || dt == 'datetime' || dt == 'timestamp';
  }

  // ── Helper: does this column have a FK? ──────────────────────────────────
  ForeignKeyInfo? _fkFor(String colName) =>
      _foreignKeys
          .where((fk) => fk.column.toLowerCase() == colName.toLowerCase())
          .firstOrNull;

  // ── Date picker ───────────────────────────────────────────────────────────
  Future<String?> _pickDate(BuildContext ctx, String current) async {
    DateTime initial;
    try {
      initial = DateTime.parse(current);
    } catch (_) {
      initial = DateTime.now();
    }
    final picked = await showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked == null) return null;
    return '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
  }

  // ── FK row-picker popup ───────────────────────────────────────────────────
  Future<String?> _pickFkValue(
    BuildContext ctx,
    ForeignKeyInfo fk,
    String current,
  ) async {
    return showDialog<String>(
      context: ctx,
      builder:
          (dctx) => _FkPickerDialog(
            session: widget.session,
            fk: fk,
            currentValue: current,
          ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Watch for selection pushed from the object browser.
    ref.listen(selectedTableProvider(widget.session.sessionId), (prev, next) {
      if (next == null) return;
      final newDb = next.database;
      final newTable = next.table;
      // Skip if already showing this exact table with data.
      if (newDb == _selectedDb &&
          newTable == _selectedTable &&
          _result != null) {
        return;
      }

      // Ensure DB appears in the dropdown.
      if (!_databases.contains(newDb)) {
        setState(() => _databases = [..._databases, newDb]);
      }

      if (newDb != _selectedDb) {
        // DB changed — load tables first, then set both pickers and execute.
        setState(() {
          _selectedDb = newDb;
          _selectedTable = newTable; // Set immediately
          _tables = [];
        });
        _fetcher.fetchTables(widget.session.mysqlConnection, newDb).then((
          tables,
        ) {
          if (!mounted) return;
          setState(() {
            _tables = tables.map((t) => t.name).toList();
          });
          _loadData();
        });
      } else {
        // Same DB — just switch the table picker and load.
        setState(() => _selectedTable = newTable);
        _loadData();
      }
    });

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        // ── Picker toolbar ─────────────────────────────────────────────────
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          color: cs.surfaceContainerHighest,
          child: Row(
            children: [
              _PickerDropdown(
                hint: 'Database',
                value: _selectedDb,
                items: _databases,
                icon: Icons.storage_outlined,
                onChanged: (v) {
                  setState(() => _selectedDb = v);
                  if (v != null) _loadTables(v);
                },
              ),
              const SizedBox(width: 6),
              _PickerDropdown(
                hint: 'Table / View',
                value: _selectedTable,
                items: _tables,
                icon: Icons.table_rows_outlined,
                onChanged: (v) => setState(() => _selectedTable = v),
              ),
              const SizedBox(width: 8),
              const VerticalDivider(width: 1, indent: 6, endIndent: 6),
              const SizedBox(width: 8),
              const Text('First row', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 4),
              SizedBox(
                width: 52,
                child: TextField(
                  controller: _firstRowCtrl,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              const Text('# of rows', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 4),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: _numRowsCtrl,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                icon:
                    _loading
                        ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.play_circle_filled, size: 14),
                label: const Text('Load', style: TextStyle(fontSize: 12)),
                onPressed:
                    (_loading || _selectedDb == null || _selectedTable == null)
                        ? null
                        : _loadData,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const Spacer(),
              if (_result != null)
                Text(
                  '${_result!.rowCount} row${_result!.rowCount == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
            ],
          ),
        ),

        // ── Content ────────────────────────────────────────────────────────
        Expanded(child: _buildContent(context, cs)),
      ],
    );
  }

  Widget _buildContent(BuildContext ctx, ColorScheme cs) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _error!,
            style: TextStyle(
              color: cs.error,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
      );
    }

    if (_result == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.table_rows_outlined,
              size: 40,
              color: cs.onSurface.withAlpha(40),
            ),
            const SizedBox(height: 12),
            Text(
              'Double-click a table in the Object Browser\nor select one above and press Load',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withAlpha(100),
              ),
            ),
          ],
        ),
      );
    }

    final result = _result!;
    if (!result.hasData || result.columns.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(fontSize: 12)),
      );
    }

    // Build PlutoGrid columns with smart types.
    final columns =
        result.columns.map((col) {
          final fk = _fkFor(col);
          return PlutoColumn(
            title: col,
            field: col,
            type: PlutoColumnType.text(),
            readOnly: true,
            enableSorting: true,
            enableContextMenu: false,
            width: 130,
            // Show icon in header for date/FK columns
            titleSpan: TextSpan(
              children: [
                if (_isDateCol(col))
                  const WidgetSpan(
                    child: Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.calendar_today,
                        size: 11,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                if (fk != null)
                  const WidgetSpan(
                    child: Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.link, size: 11, color: Colors.teal),
                    ),
                  ),
                TextSpan(text: col),
              ],
            ),
          );
        }).toList();

    final rows =
        result.rows.map((row) {
          final cells = <String, PlutoCell>{};
          for (var i = 0; i < result.columns.length; i++) {
            cells[result.columns[i]] = PlutoCell(
              value: row.length > i ? (row[i]?.toString() ?? '') : '',
            );
          }
          return PlutoRow(cells: cells);
        }).toList();

    return PlutoGrid(
      columns: columns,
      rows: rows,
      onLoaded: (e) {
        _stateManager = e.stateManager;
        e.stateManager.setShowColumnFilter(false);
      },
      onSelected: (e) async {
        if (e.cell == null) return;
        final colName = e.cell!.column.field;
        final current = e.cell!.value?.toString() ?? '';

        // Date picker
        if (_isDateCol(colName)) {
          final picked = await _pickDate(ctx, current);
          if (picked != null && picked != current) {
            _stateManager?.changeCellValue(e.cell!, picked);
          }
          return;
        }

        // FK picker
        final fk = _fkFor(colName);
        if (fk != null) {
          final picked = await _pickFkValue(ctx, fk, current);
          if (picked != null && picked != current) {
            _stateManager?.changeCellValue(e.cell!, picked);
          }
        }
      },
      configuration: PlutoGridConfiguration(
        style:
            Theme.of(ctx).brightness == Brightness.dark
                ? const PlutoGridStyleConfig.dark()
                : const PlutoGridStyleConfig(),
      ),
    );
  }
}

// ── FK row-picker dialog ──────────────────────────────────────────────────────

class _FkPickerDialog extends StatefulWidget {
  final WorkspaceSession session;
  final ForeignKeyInfo fk;
  final String currentValue;

  const _FkPickerDialog({
    required this.session,
    required this.fk,
    required this.currentValue,
  });

  @override
  State<_FkPickerDialog> createState() => _FkPickerDialogState();
}

class _FkPickerDialogState extends State<_FkPickerDialog> {
  final _executor = const MysqlQueryExecutor(maxRows: 500);
  final _search = TextEditingController();
  List<List<dynamic>> _rows = [];
  List<String> _cols = [];
  bool _loading = true;
  String? _error;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final result = await _executor.execute(
        widget.session.mysqlConnection,
        'SELECT * FROM `${widget.fk.refTable}` LIMIT 500',
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (result.isError) {
          _error = result.errorMessage;
        } else {
          _cols = result.columns;
          _rows = result.rows;
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final refCol = widget.fk.refColumn;

    // Filter rows by search text.
    final filtered =
        _filter.isEmpty
            ? _rows
            : _rows
                .where(
                  (row) => row.any(
                    (cell) => (cell?.toString() ?? '').toLowerCase().contains(
                      _filter,
                    ),
                  ),
                )
                .toList();

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: cs.surfaceContainerHighest,
              child: Row(
                children: [
                  const Icon(Icons.link, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pick from `${widget.fk.refTable}` → ${widget.fk.refColumn}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Search bar
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _search,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search…',
                  prefixIcon: const Icon(Icons.search, size: 16),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                ),
                onChanged: (v) => setState(() => _filter = v.toLowerCase()),
              ),
            ),
            // Content
            Expanded(
              child:
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? Center(
                        child: Text(
                          _error!,
                          style: TextStyle(color: cs.error, fontSize: 12),
                        ),
                      )
                      : filtered.isEmpty
                      ? const Center(
                        child: Text(
                          'No rows found',
                          style: TextStyle(fontSize: 12),
                        ),
                      )
                      : _buildTable(cs, filtered, refCol),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(ColorScheme cs, List<List<dynamic>> rows, String refCol) {
    final refColIdx = _cols.indexWhere(
      (c) => c.toLowerCase() == refCol.toLowerCase(),
    );

    return SingleChildScrollView(
      child: DataTable(
        columnSpacing: 12,
        headingRowHeight: 30,
        dataRowMinHeight: 28,
        dataRowMaxHeight: 28,
        headingRowColor: WidgetStateProperty.all(cs.surfaceContainerHighest),
        columns:
            _cols
                .map(
                  (c) => DataColumn(
                    label: Text(
                      c,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
        rows:
            rows.map((row) {
              final pkVal =
                  refColIdx >= 0 && refColIdx < row.length
                      ? row[refColIdx]?.toString() ?? ''
                      : '';
              final isSelected = pkVal == widget.currentValue;
              return DataRow(
                selected: isSelected,
                color:
                    isSelected
                        ? WidgetStateProperty.all(
                          cs.primaryContainer.withAlpha(120),
                        )
                        : null,
                onSelectChanged: (_) => Navigator.pop(context, pkVal),
                cells: List.generate(
                  _cols.length,
                  (i) => DataCell(
                    Text(
                      i < row.length ? (row[i]?.toString() ?? '') : '',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

// ── Dropdown picker ───────────────────────────────────────────────────────────

class _PickerDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final IconData icon;
  final void Function(String?) onChanged;

  const _PickerDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 160),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: (value != null && items.contains(value)) ? value : null,
          hint: Row(
            children: [
              Icon(icon, size: 12, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                hint,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          isDense: true,
          isExpanded: true,
          style: const TextStyle(fontSize: 12),
          borderRadius: BorderRadius.circular(6),
          items:
              items
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
