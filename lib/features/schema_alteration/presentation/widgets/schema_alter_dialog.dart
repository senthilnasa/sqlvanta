import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../mysql/mysql_query_executor.dart';
import '../../../../mysql/mysql_schema_fetcher.dart';
import '../../../workspace/domain/entities/workspace_session.dart';

/// ALTER TABLE dialog — add, drop, rename, and modify columns.
class SchemaAlterDialog extends StatefulWidget {
  final WorkspaceSession session;
  final String database;
  final String table;

  const SchemaAlterDialog({
    super.key,
    required this.session,
    required this.database,
    required this.table,
  });

  static Future<void> show(
    BuildContext context, {
    required WorkspaceSession session,
    required String database,
    required String table,
  }) {
    return showDialog<void>(
      context: context,
      builder:
          (_) => SchemaAlterDialog(
            session: session,
            database: database,
            table: table,
          ),
    );
  }

  @override
  State<SchemaAlterDialog> createState() => _SchemaAlterDialogState();
}

class _SchemaAlterDialogState extends State<SchemaAlterDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tc;
  final _fetcher = const MysqlSchemaFetcher();
  final _executor = const MysqlQueryExecutor();

  List<ColumnInfo> _columns = [];
  bool _loading = true;
  String? _error;

  // ── Add Column form ─────────────────────────────────────────────────────────
  final _addNameCtrl = TextEditingController();
  final _addTypeCtrl = TextEditingController(text: 'VARCHAR(255)');
  bool _addNullable = true;
  final _addDefaultCtrl = TextEditingController();
  String? _addAfterCol;

  // ── Modify Column form ─────────────────────────────────────────────────────
  ColumnInfo? _modifyTarget;
  final _modifyTypeCtrl = TextEditingController();
  bool _modifyNullable = true;
  final _modifyDefaultCtrl = TextEditingController();

  // ── Rename Column form ─────────────────────────────────────────────────────
  ColumnInfo? _renameTarget;
  final _renameNewCtrl = TextEditingController();

  bool _executing = false;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 4, vsync: this);
    _loadColumns();
  }

  @override
  void dispose() {
    _tc.dispose();
    _addNameCtrl.dispose();
    _addTypeCtrl.dispose();
    _addDefaultCtrl.dispose();
    _modifyTypeCtrl.dispose();
    _modifyDefaultCtrl.dispose();
    _renameNewCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadColumns() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cols = await _fetcher.fetchColumns(
        widget.session.mysqlConnection,
        widget.database,
        widget.table,
      );
      if (mounted) {
        setState(() {
          _columns = cols;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _execute(String sql) async {
    setState(() => _executing = true);
    try {
      final result = await _executor.execute(
        widget.session.mysqlConnection,
        sql,
      );
      if (!mounted) return;
      if (result.isError) {
        _showError(result.errorMessage ?? 'Unknown error');
      } else {
        BotToast.showSimpleNotification(title: '✓ Done', subTitle: sql);
        await _loadColumns();
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _executing = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 12)),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  // ── SQL builders ────────────────────────────────────────────────────────────

  String get _prefix => 'ALTER TABLE `${widget.database}`.`${widget.table}`';

  String _addColSql() {
    final name = _addNameCtrl.text.trim();
    final type = _addTypeCtrl.text.trim();
    if (name.isEmpty || type.isEmpty) return '';
    final nullPart = _addNullable ? 'NULL' : 'NOT NULL';
    final defPart =
        _addDefaultCtrl.text.trim().isEmpty
            ? ''
            : ' DEFAULT ${_quote(_addDefaultCtrl.text.trim())}';
    final afterPart = _addAfterCol != null ? ' AFTER `$_addAfterCol`' : '';
    return '$_prefix ADD COLUMN `$name` $type $nullPart$defPart$afterPart;';
  }

  String _modifyColSql() {
    if (_modifyTarget == null) return '';
    final type = _modifyTypeCtrl.text.trim();
    if (type.isEmpty) return '';
    final nullPart = _modifyNullable ? 'NULL' : 'NOT NULL';
    final defPart =
        _modifyDefaultCtrl.text.trim().isEmpty
            ? ''
            : ' DEFAULT ${_quote(_modifyDefaultCtrl.text.trim())}';
    return '$_prefix MODIFY COLUMN `${_modifyTarget!.name}` $type $nullPart$defPart;';
  }

  String _renameColSql() {
    if (_renameTarget == null || _renameNewCtrl.text.trim().isEmpty) return '';
    final type = _renameTarget!.columnType ?? _renameTarget!.dataType;
    return '$_prefix CHANGE COLUMN `${_renameTarget!.name}` `${_renameNewCtrl.text.trim()}` $type;';
  }

  String _dropColSql(ColumnInfo col) => '$_prefix DROP COLUMN `${col.name}`;';

  String _quote(String v) {
    if (v.toUpperCase() == 'NULL' || RegExp(r'^\d').hasMatch(v)) return v;
    return "'${v.replaceAll("'", "''")}'";
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: cs.surfaceContainerHighest,
              child: Row(
                children: [
                  const Icon(Icons.build_outlined, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Alter Table — `${widget.database}`.`${widget.table}`',
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
            TabBar(
              controller: _tc,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: const TextStyle(fontSize: 12),
              tabs: const [
                Tab(text: 'Columns'),
                Tab(text: 'Add Column'),
                Tab(text: 'Modify Column'),
                Tab(text: 'Rename Column'),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child:
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? Center(
                        child: Text(_error!, style: TextStyle(color: cs.error)),
                      )
                      : TabBarView(
                        controller: _tc,
                        children: [
                          _ColumnsTab(
                            columns: _columns,
                            onDrop: (col) => _confirmDrop(col),
                            onModify: (col) {
                              setState(() {
                                _modifyTarget = col;
                                _modifyTypeCtrl.text =
                                    col.columnType ?? col.dataType;
                                _modifyNullable = col.isNullable;
                                _modifyDefaultCtrl.text =
                                    col.columnDefault ?? '';
                              });
                              _tc.animateTo(2);
                            },
                            onRename: (col) {
                              setState(() {
                                _renameTarget = col;
                                _renameNewCtrl.text = col.name;
                              });
                              _tc.animateTo(3);
                            },
                          ),
                          _AddColumnTab(
                            columns: _columns,
                            nameCtrl: _addNameCtrl,
                            typeCtrl: _addTypeCtrl,
                            nullable: _addNullable,
                            defaultCtrl: _addDefaultCtrl,
                            afterCol: _addAfterCol,
                            onNullableChanged:
                                (v) => setState(() => _addNullable = v),
                            onAfterChanged:
                                (v) => setState(() => _addAfterCol = v),
                            preview: _addColSql(),
                            executing: _executing,
                            onExecute: () {
                              final sql = _addColSql();
                              if (sql.isNotEmpty) _execute(sql);
                            },
                          ),
                          _ModifyColumnTab(
                            target: _modifyTarget,
                            typeCtrl: _modifyTypeCtrl,
                            nullable: _modifyNullable,
                            defaultCtrl: _modifyDefaultCtrl,
                            onNullableChanged:
                                (v) => setState(() => _modifyNullable = v),
                            preview: _modifyColSql(),
                            executing: _executing,
                            onExecute: () {
                              final sql = _modifyColSql();
                              if (sql.isNotEmpty) _execute(sql);
                            },
                          ),
                          _RenameColumnTab(
                            target: _renameTarget,
                            newNameCtrl: _renameNewCtrl,
                            preview: _renameColSql(),
                            executing: _executing,
                            onExecute: () {
                              final sql = _renameColSql();
                              if (sql.isNotEmpty) _execute(sql);
                            },
                          ),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDrop(ColumnInfo col) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Drop Column', style: TextStyle(fontSize: 14)),
            content: Text(
              'Drop column `${col.name}` from `${widget.table}`?\n\nThis cannot be undone.',
              style: const TextStyle(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Drop'),
              ),
            ],
          ),
    );
    if (ok == true) _execute(_dropColSql(col));
  }
}

// ── Columns tab ───────────────────────────────────────────────────────────────

class _ColumnsTab extends StatelessWidget {
  final List<ColumnInfo> columns;
  final void Function(ColumnInfo) onDrop;
  final void Function(ColumnInfo) onModify;
  final void Function(ColumnInfo) onRename;

  const _ColumnsTab({
    required this.columns,
    required this.onDrop,
    required this.onModify,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.separated(
      itemCount: columns.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final col = columns[i];
        return ListTile(
          dense: true,
          leading: _badge(col, cs),
          title: Text(
            col.name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            [
              col.columnType ?? col.dataType,
              col.isNullable ? 'NULL' : 'NOT NULL',
              if (col.columnDefault != null) 'DEFAULT ${col.columnDefault}',
            ].join(' · '),
            style: const TextStyle(fontSize: 11),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconBtn(
                icon: Icons.edit_outlined,
                tooltip: 'Modify type',
                onTap: () => onModify(col),
              ),
              _IconBtn(
                icon: Icons.drive_file_rename_outline,
                tooltip: 'Rename',
                onTap: () => onRename(col),
              ),
              _IconBtn(
                icon: Icons.delete_outline,
                tooltip: 'Drop column',
                color: cs.error,
                onTap: col.isPrimaryKey ? null : () => onDrop(col),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _badge(ColumnInfo col, ColorScheme cs) {
    if (col.isPrimaryKey) {
      return Tooltip(
        message: 'Primary Key',
        child: Icon(Icons.key, size: 16, color: Colors.amber.shade600),
      );
    }
    if (col.isForeignKey) {
      return Tooltip(
        message: 'Foreign Key',
        child: Icon(Icons.link, size: 16, color: Colors.teal.shade400),
      );
    }
    return Icon(
      Icons.table_rows_outlined,
      size: 14,
      color: cs.onSurfaceVariant.withAlpha(120),
    );
  }
}

// ── Add Column tab ────────────────────────────────────────────────────────────

class _AddColumnTab extends StatelessWidget {
  final List<ColumnInfo> columns;
  final TextEditingController nameCtrl;
  final TextEditingController typeCtrl;
  final bool nullable;
  final TextEditingController defaultCtrl;
  final String? afterCol;
  final void Function(bool) onNullableChanged;
  final void Function(String?) onAfterChanged;
  final String preview;
  final bool executing;
  final VoidCallback onExecute;

  const _AddColumnTab({
    required this.columns,
    required this.nameCtrl,
    required this.typeCtrl,
    required this.nullable,
    required this.defaultCtrl,
    required this.afterCol,
    required this.onNullableChanged,
    required this.onAfterChanged,
    required this.preview,
    required this.executing,
    required this.onExecute,
  });

  static const _commonTypes = [
    'VARCHAR(255)',
    'TEXT',
    'INT',
    'BIGINT',
    'SMALLINT',
    'TINYINT',
    'DECIMAL(10,2)',
    'FLOAT',
    'DOUBLE',
    'BOOLEAN',
    'DATE',
    'DATETIME',
    'TIMESTAMP',
    'JSON',
    'BLOB',
    'CHAR(36)',
  ];

  @override
  Widget build(BuildContext context) {
    return _FormShell(
      children: [
        _Field(
          label: 'Column name',
          child: TextField(
            controller: nameCtrl,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
        _Field(
          label: 'Data type',
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: typeCtrl,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              PopupMenuButton<String>(
                tooltip: 'Common types',
                icon: const Icon(Icons.arrow_drop_down, size: 18),
                onSelected: (t) => typeCtrl.text = t,
                itemBuilder:
                    (_) =>
                        _commonTypes
                            .map(
                              (t) => PopupMenuItem(
                                value: t,
                                height: 32,
                                child: Text(
                                  t,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            )
                            .toList(),
              ),
            ],
          ),
        ),
        _Field(
          label: 'Nullable',
          child: Row(
            children: [
              Switch(value: nullable, onChanged: onNullableChanged),
              const SizedBox(width: 6),
              Text(
                nullable ? 'NULL' : 'NOT NULL',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        _Field(
          label: 'Default value',
          child: TextField(
            controller: defaultCtrl,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              hintText: 'Leave empty for no default',
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
        _Field(
          label: 'Add after column',
          child: DropdownButtonFormField<String>(
            initialValue: afterCol,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            style: const TextStyle(fontSize: 12),
            items: [
              const DropdownMenuItem(value: null, child: Text('End of table')),
              ...columns.map(
                (c) => DropdownMenuItem(value: c.name, child: Text(c.name)),
              ),
            ],
            onChanged: onAfterChanged,
          ),
        ),
        _PreviewAndExecute(
          preview: preview,
          executing: executing,
          onExecute: onExecute,
        ),
      ],
    );
  }
}

// ── Modify Column tab ─────────────────────────────────────────────────────────

class _ModifyColumnTab extends StatelessWidget {
  final ColumnInfo? target;
  final TextEditingController typeCtrl;
  final bool nullable;
  final TextEditingController defaultCtrl;
  final void Function(bool) onNullableChanged;
  final String preview;
  final bool executing;
  final VoidCallback onExecute;

  const _ModifyColumnTab({
    required this.target,
    required this.typeCtrl,
    required this.nullable,
    required this.defaultCtrl,
    required this.onNullableChanged,
    required this.preview,
    required this.executing,
    required this.onExecute,
  });

  @override
  Widget build(BuildContext context) {
    if (target == null) {
      return const Center(
        child: Text(
          'Select a column from the Columns tab to modify',
          style: TextStyle(fontSize: 12),
        ),
      );
    }
    return _FormShell(
      children: [
        _Field(
          label: 'Column',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              target!.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        _Field(
          label: 'New data type',
          child: TextField(
            controller: typeCtrl,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
        _Field(
          label: 'Nullable',
          child: Row(
            children: [
              Switch(value: nullable, onChanged: onNullableChanged),
              const SizedBox(width: 6),
              Text(
                nullable ? 'NULL' : 'NOT NULL',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        _Field(
          label: 'Default value',
          child: TextField(
            controller: defaultCtrl,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              hintText: 'Leave empty for no default',
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
        _PreviewAndExecute(
          preview: preview,
          executing: executing,
          onExecute: onExecute,
        ),
      ],
    );
  }
}

// ── Rename Column tab ─────────────────────────────────────────────────────────

class _RenameColumnTab extends StatelessWidget {
  final ColumnInfo? target;
  final TextEditingController newNameCtrl;
  final String preview;
  final bool executing;
  final VoidCallback onExecute;

  const _RenameColumnTab({
    required this.target,
    required this.newNameCtrl,
    required this.preview,
    required this.executing,
    required this.onExecute,
  });

  @override
  Widget build(BuildContext context) {
    if (target == null) {
      return const Center(
        child: Text(
          'Select a column from the Columns tab to rename',
          style: TextStyle(fontSize: 12),
        ),
      );
    }
    return _FormShell(
      children: [
        _Field(
          label: 'Current name',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              target!.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        _Field(
          label: 'New name',
          child: TextField(
            controller: newNameCtrl,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
        _PreviewAndExecute(
          preview: preview,
          executing: executing,
          onExecute: onExecute,
        ),
      ],
    );
  }
}

// ── Shared form helpers ───────────────────────────────────────────────────────

class _FormShell extends StatelessWidget {
  final List<Widget> children;
  const _FormShell({required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _PreviewAndExecute extends StatelessWidget {
  final String preview;
  final bool executing;
  final VoidCallback onExecute;

  const _PreviewAndExecute({
    required this.preview,
    required this.executing,
    required this.onExecute,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Row(
          children: [
            Text(
              'SQL Preview',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            if (preview.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.copy, size: 14),
                tooltip: 'Copy SQL',
                onPressed:
                    () => Clipboard.setData(ClipboardData(text: preview)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Text(
            preview.isEmpty ? '— fill in the form above —' : preview,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color:
                  preview.isEmpty ? cs.onSurface.withAlpha(80) : cs.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon:
                executing
                    ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.play_arrow, size: 16),
            label: Text(executing ? 'Executing…' : 'Execute ALTER TABLE'),
            onPressed: (preview.isEmpty || executing) ? null : onExecute,
          ),
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color? color;
  final VoidCallback? onTap;

  const _IconBtn({
    required this.icon,
    required this.tooltip,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 16,
            color: onTap == null ? c.withAlpha(60) : c,
          ),
        ),
      ),
    );
  }
}
