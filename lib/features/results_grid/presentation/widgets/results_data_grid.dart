import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pluto_grid/pluto_grid.dart';

import '../../../../mysql/mysql_query_executor.dart';
import '../../../query_editor/presentation/providers/query_editor_providers.dart';
import '../../../workspace/presentation/providers/workspace_provider.dart';

class ResultsDataGrid extends ConsumerStatefulWidget {
  final QueryResult result;
  final String? tabId; // to read the source SQL for table name extraction
  final String? sessionId; // to execute UPDATE statements

  const ResultsDataGrid({
    super.key,
    required this.result,
    this.tabId,
    this.sessionId,
  });

  @override
  ConsumerState<ResultsDataGrid> createState() => _ResultsDataGridState();
}

class _ResultsDataGridState extends ConsumerState<ResultsDataGrid> {
  late List<PlutoColumn> _columns;
  late List<PlutoRow> _rows;

  /// Original row data snapshot (used to build WHERE clauses for UPDATEs).
  late final List<Map<String, String>> _originalData;

  PlutoGridStateManager? _stateManager;
  bool _editMode = false;
  bool _saving = false;

  /// rowIndex → {columnField → newValue}
  final Map<int, Map<String, String>> _changes = {};

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _buildGrid();
  }

  void _buildGrid() {
    _originalData =
        widget.result.rows.map((row) {
          final m = <String, String>{};
          for (var i = 0; i < widget.result.columns.length; i++) {
            m[widget.result.columns[i]] =
                row.length > i ? (row[i]?.toString() ?? '') : '';
          }
          return m;
        }).toList();

    _columns =
        widget.result.columns
            .map(
              (col) => PlutoColumn(
                title: col,
                field: col,
                type: PlutoColumnType.text(),
                readOnly: true,
                enableSorting: true,
                enableContextMenu: false,
                width: 120,
              ),
            )
            .toList();

    _rows =
        widget.result.rows.map((row) {
          final cells = <String, PlutoCell>{};
          for (var i = 0; i < widget.result.columns.length; i++) {
            final col = widget.result.columns[i];
            final val = row.length > i ? row[i] : null;
            cells[col] = PlutoCell(value: val?.toString() ?? '');
          }
          return PlutoRow(cells: cells);
        }).toList();
  }

  // ── Edit mode ────────────────────────────────────────────────────────────

  void _toggleEditMode() {
    final entering = !_editMode;
    setState(() {
      _editMode = entering;
      if (!entering) _changes.clear();
    });
    _stateManager?.refColumns.originalList.forEach(
      (col) => col.readOnly = !entering,
    );
    _stateManager?.notifyListeners();
  }

  void _discardChanges() {
    setState(() {
      _changes.clear();
      _editMode = false;
      _buildGrid(); // rebuild to restore original values
    });
    _stateManager?.refColumns.originalList.forEach(
      (col) => col.readOnly = true,
    );
    _stateManager?.notifyListeners();
  }

  void _onCellChanged(PlutoGridOnChangedEvent event) {
    if (!_editMode) return;
    final rowIdx = _rows.indexOf(event.row);
    if (rowIdx < 0) return;
    // Defer setState — PlutoGrid can fire this during dispose (tree locked).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _changes.putIfAbsent(rowIdx, () => {});
        _changes[rowIdx]![event.column.field] = event.value?.toString() ?? '';
      });
    });
  }

  // ── SQL helpers ───────────────────────────────────────────────────────────

  String? get _sourceSql =>
      widget.tabId != null
          ? ref.read(editorContentProvider(widget.tabId!))
          : null;

  /// Extracts database name from `SELECT … FROM \`db\`.\`table\``.
  String? get _sourceDatabase {
    final sql = _sourceSql;
    if (sql == null) return null;
    final m = RegExp(
      r'\bFROM\b\s+`?(\w+)`?\.`?\w+`?',
      caseSensitive: false,
    ).firstMatch(sql);
    return m?.group(1);
  }

  /// Extracts table name from `SELECT … FROM \`table\``.
  String? get _sourceTable {
    final sql = _sourceSql;
    if (sql == null) return null;
    final m = RegExp(
      r'\bFROM\b\s+(?:`?(\w+)`?\.)?`?(\w+)`?',
      caseSensitive: false,
    ).firstMatch(sql);
    return m?.group(2) ?? m?.group(1);
  }

  // ── Save changes ──────────────────────────────────────────────────────────

  Future<void> _saveChanges() async {
    final table = _sourceTable;
    if (table == null || _changes.isEmpty) {
      BotToast.showSimpleNotification(
        title: 'Cannot save',
        subTitle: 'Table name could not be detected from SQL',
      );
      return;
    }
    final session =
        widget.sessionId != null
            ? ref.read(workspaceProvider)[widget.sessionId!]
            : null;
    if (session == null) {
      BotToast.showSimpleNotification(title: 'No connection');
      return;
    }

    setState(() => _saving = true);

    final dbPrefix = _sourceDatabase != null ? '`$_sourceDatabase`.' : '';
    final pkField =
        widget.result.columns.isNotEmpty ? widget.result.columns.first : null;

    int saved = 0, failed = 0;
    for (final entry in _changes.entries) {
      final rowIdx = entry.key;
      final changedCols = entry.value;
      if (rowIdx >= _originalData.length || pkField == null) {
        failed++;
        continue;
      }
      final pkVal = _originalData[rowIdx][pkField];
      if (pkVal == null) {
        failed++;
        continue;
      }

      final setClauses = changedCols.entries
          .map((e) {
            final v = e.value;
            if (v.isEmpty || v.toUpperCase() == 'NULL') {
              return '`${e.key}` = NULL';
            }
            return '`${e.key}` = \'${v.replaceAll("'", "''")}\'';
          })
          .join(', ');

      final whereVal = pkVal.replaceAll("'", "''");
      final sql =
          'UPDATE $dbPrefix`$table` SET $setClauses WHERE `$pkField` = \'$whereVal\' LIMIT 1';

      try {
        await session.mysqlConnection.execute(sql);
        saved++;
      } catch (_) {
        failed++;
      }
    }

    setState(() {
      _saving = false;
      _changes.clear();
      _editMode = false;
    });
    _stateManager?.refColumns.originalList.forEach(
      (col) => col.readOnly = true,
    );
    _stateManager?.notifyListeners();

    BotToast.showSimpleNotification(
      title: failed == 0 ? '✓ Saved' : 'Partial save',
      subTitle: '$saved saved${failed > 0 ? ', $failed failed' : ''}',
    );
  }

  // ── Export CSV ────────────────────────────────────────────────────────────

  Future<void> _exportCsv() async {
    try {
      final dir =
          await getDownloadsDirectory() ?? await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/sqlvanta_$ts.csv');

      final buf = StringBuffer();
      buf.writeln(widget.result.columns.map((c) => '"$c"').join(','));
      for (final row in widget.result.rows) {
        buf.writeln(
          row
              .map((v) => '"${(v?.toString() ?? '').replaceAll('"', '""')}"')
              .join(','),
        );
      }
      await file.writeAsString(buf.toString());
      BotToast.showSimpleNotification(title: 'Exported', subTitle: file.path);
    } catch (e) {
      BotToast.showSimpleNotification(
        title: 'Export failed',
        subTitle: e.toString(),
      );
    }
  }

  // ── Row context menu ──────────────────────────────────────────────────────

  void _showRowMenu(PlutoRow row, Offset offset) {
    final rowIdx = _rows.indexOf(row);
    if (rowIdx < 0 || rowIdx >= _originalData.length) return;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy,
        offset.dx + 1,
        offset.dy + 1,
      ),
      items: [
        _menuItem('copy_insert', Icons.content_copy, 'Copy row as INSERT'),
        _menuItem('copy_update', Icons.edit_outlined, 'Copy row as UPDATE'),
        _menuItem(
          'copy_values',
          Icons.format_list_bulleted,
          'Copy cell values',
        ),
      ],
    ).then((action) {
      if (action == null) return;
      switch (action) {
        case 'copy_insert':
          _copyAsInsert(rowIdx);
        case 'copy_update':
          _copyAsUpdate(rowIdx);
        case 'copy_values':
          _copyCellValues(rowIdx);
      }
    });
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) =>
      PopupMenuItem(
        value: value,
        height: 36,
        child: Row(
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      );

  void _copyAsInsert(int rowIdx) {
    final table = _sourceTable ?? 'table_name';
    final dbPrefix = _sourceDatabase != null ? '`$_sourceDatabase`.' : '';
    final cols = widget.result.columns.map((c) => '`$c`').join(', ');
    final vals = _originalData[rowIdx].values
        .map((v) {
          if (v.isEmpty) return 'NULL';
          return "'${v.replaceAll("'", "''")}'";
        })
        .join(', ');
    Clipboard.setData(
      ClipboardData(
        text: 'INSERT INTO $dbPrefix`$table` ($cols) VALUES ($vals);',
      ),
    );
    BotToast.showSimpleNotification(title: 'Copied as INSERT');
  }

  void _copyAsUpdate(int rowIdx) {
    final table = _sourceTable ?? 'table_name';
    final dbPrefix = _sourceDatabase != null ? '`$_sourceDatabase`.' : '';
    final data = _originalData[rowIdx];
    final pkField =
        widget.result.columns.isNotEmpty ? widget.result.columns.first : null;
    if (pkField == null) return;

    final setClauses = data.entries
        .where((e) => e.key != pkField)
        .map((e) {
          final v =
              e.value.isEmpty ? 'NULL' : "'${e.value.replaceAll("'", "''")}'";
          return '`${e.key}` = $v';
        })
        .join(', ');
    final pkVal = "'${(data[pkField] ?? '').replaceAll("'", "''")}'";
    Clipboard.setData(
      ClipboardData(
        text:
            'UPDATE $dbPrefix`$table` SET $setClauses WHERE `$pkField` = $pkVal LIMIT 1;',
      ),
    );
    BotToast.showSimpleNotification(title: 'Copied as UPDATE');
  }

  void _copyCellValues(int rowIdx) {
    final text = _originalData[rowIdx].values.join('\t');
    Clipboard.setData(ClipboardData(text: text));
    BotToast.showSimpleNotification(title: 'Copied cell values');
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_columns.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(fontSize: 12)),
      );
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // ── Grid toolbar ───────────────────────────────────────────────────
        _GridToolbar(
          editMode: _editMode,
          changeCount: _changes.length,
          saving: _saving,
          tableName: _sourceTable,
          rowCount: widget.result.rowCount,
          onToggleEdit: _toggleEditMode,
          onSave: _saveChanges,
          onDiscard: _discardChanges,
          onExport: _exportCsv,
          onToggleFilter:
              () => _stateManager?.setShowColumnFilter(
                !(_stateManager?.showColumnFilter ?? false),
              ),
        ),

        // ── PlutoGrid ──────────────────────────────────────────────────────
        Expanded(
          child: PlutoGrid(
            columns: _columns,
            rows: _rows,
            onLoaded: (event) {
              _stateManager = event.stateManager;
              event.stateManager.setShowColumnFilter(false);
            },
            onChanged: _onCellChanged,
            onRowSecondaryTap: (event) => _showRowMenu(event.row, event.offset),
            configuration: PlutoGridConfiguration(
              style:
                  isDark
                      ? const PlutoGridStyleConfig.dark()
                      : PlutoGridStyleConfig(
                        gridBorderColor: cs.outlineVariant,
                        gridBorderRadius: BorderRadius.zero,
                        activatedColor: cs.primaryContainer.withAlpha(80),
                        activatedBorderColor: cs.primary,
                        cellColorInEditState: cs.primaryContainer.withAlpha(50),
                        oddRowColor: cs.surfaceContainerLowest,
                      ),
              columnFilter: const PlutoGridColumnFilterConfig(
                filters: [...FilterHelper.defaultFilters],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Grid toolbar ──────────────────────────────────────────────────────────────

class _GridToolbar extends StatelessWidget {
  final bool editMode;
  final int changeCount;
  final bool saving;
  final String? tableName;
  final int rowCount;
  final VoidCallback onToggleEdit;
  final VoidCallback onSave;
  final VoidCallback onDiscard;
  final VoidCallback onExport;
  final VoidCallback onToggleFilter;

  const _GridToolbar({
    required this.editMode,
    required this.changeCount,
    required this.saving,
    required this.tableName,
    required this.rowCount,
    required this.onToggleEdit,
    required this.onSave,
    required this.onDiscard,
    required this.onExport,
    required this.onToggleFilter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          // Edit toggle (only if we know the table)
          _Btn(
            icon: editMode ? Icons.edit_off_outlined : Icons.edit_outlined,
            label: editMode ? 'Exit Edit' : 'Edit',
            color: editMode ? cs.error : cs.primary,
            onPressed: onToggleEdit,
          ),

          // Save / Discard (visible only when there are changes)
          if (editMode && changeCount > 0) ...[
            const SizedBox(width: 4),
            _SaveButton(saving: saving, count: changeCount, onPressed: onSave),
            const SizedBox(width: 4),
            _Btn(icon: Icons.undo, label: 'Discard', onPressed: onDiscard),
          ],

          // Table name pill
          if (tableName != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.table_rows_outlined,
                    size: 11,
                    color: cs.onSecondaryContainer,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    tableName!,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Spacer(),

          // Filter toggle
          _Btn(
            icon: Icons.filter_list,
            label: 'Filter',
            tooltip: 'Toggle column filter',
            onPressed: onToggleFilter,
          ),
          const SizedBox(width: 4),

          // Row count
          Text(
            '$rowCount row${rowCount == 1 ? '' : 's'}',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 8),

          // Export CSV
          _Btn(
            icon: Icons.download_outlined,
            label: 'CSV',
            tooltip: 'Export to CSV',
            onPressed: onExport,
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool saving;
  final int count;
  final VoidCallback onPressed;
  const _SaveButton({
    required this.saving,
    required this.count,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      icon:
          saving
              ? const SizedBox(
                width: 11,
                height: 11,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
              : const Icon(Icons.save_outlined, size: 13),
      label: Text(
        'Save $count change${count > 1 ? 's' : ''}',
        style: const TextStyle(fontSize: 11),
      ),
      onPressed: saving ? null : onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? tooltip;
  final Color? color;
  final VoidCallback onPressed;

  const _Btn({
    required this.icon,
    required this.label,
    this.tooltip,
    this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Tooltip(
      message: tooltip ?? label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: c),
              const SizedBox(width: 3),
              Text(label, style: TextStyle(fontSize: 11, color: c)),
            ],
          ),
        ),
      ),
    );
  }
}
