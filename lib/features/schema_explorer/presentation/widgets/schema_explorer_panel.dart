import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../mysql/mysql_schema_fetcher.dart';
import '../../../workspace/domain/entities/workspace_session.dart';
import '../providers/schema_explorer_provider.dart';

/// A modern, interactive Schema Explorer panel.
///
/// Left sidebar: database/table tree with search + favorites
/// Right panel: table details, SQL preview, ER mini-view
class SchemaExplorerPanel extends StatefulWidget {
  final WorkspaceSession session;

  const SchemaExplorerPanel({super.key, required this.session});

  @override
  State<SchemaExplorerPanel> createState() => _SchemaExplorerPanelState();
}

class _SchemaExplorerPanelState extends State<SchemaExplorerPanel>
    with TickerProviderStateMixin {
  final _fetcher = const MysqlSchemaFetcher();
  final _searchController = TextEditingController();

  // State
  List<String> _databases = [];
  String? _selectedDb;
  List<TableInfo> _tables = [];
  String _searchQuery = '';
  bool _loadingDbs = true;
  bool _loadingTables = false;

  // Selected table detail
  TableDetail? _selectedDetail;
  bool _loadingDetail = false;

  // Favorites & Recents (in-memory)
  final Set<String> _favorites = {};
  final List<({String db, String table})> _recents = [];

  // Sidebar collapsed
  bool _sidebarCollapsed = false;

  // Tab controller for detail view
  late TabController _detailTabController;

  @override
  void initState() {
    super.initState();
    _detailTabController = TabController(length: 4, vsync: this);
    _loadDatabases();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _detailTabController.dispose();
    super.dispose();
  }

  Future<void> _loadDatabases() async {
    try {
      final dbs =
          await _fetcher.fetchAllDatabases(widget.session.mysqlConnection);
      if (!mounted) return;
      setState(() {
        _databases = dbs.map((d) => d.name).toList();
        _loadingDbs = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loadingDbs = false);
    }
  }

  Future<void> _selectDatabase(String db) async {
    setState(() {
      _selectedDb = db;
      _loadingTables = true;
      _selectedDetail = null;
    });
    try {
      final tables =
          await _fetcher.fetchTables(widget.session.mysqlConnection, db);
      if (!mounted) return;
      setState(() {
        _tables = tables;
        _loadingTables = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loadingTables = false);
    }
  }

  Future<void> _selectTable(String db, String tableName) async {
    setState(() => _loadingDetail = true);

    // Add to recents
    _recents.removeWhere((e) => e.db == db && e.table == tableName);
    _recents.insert(0, (db: db, table: tableName));
    if (_recents.length > 20) _recents.removeRange(20, _recents.length);

    try {
      final conn = widget.session.mysqlConnection;
      final results = await Future.wait([
        _fetcher.fetchColumns(conn, db, tableName),
        _fetcher.fetchConstraints(conn, db, tableName),
        _fetcher.fetchForeignKeys(conn, db),
        _fetcher.fetchReferencedBy(conn, db, tableName),
        _fetcher.fetchCreateTable(conn, db, tableName),
      ]);

      if (!mounted) return;

      final allFks = results[2] as List<ForeignKeyInfo>;
      final tableFks =
          allFks.where((fk) => fk.table == tableName).toList();

      setState(() {
        _selectedDetail = TableDetail(
          database: db,
          tableName: tableName,
          columns: results[0] as List<ColumnInfo>,
          constraints: results[1] as List<ConstraintInfo>,
          foreignKeys: tableFks,
          referencedBy: results[3] as List<ForeignKeyInfo>,
          createTableDdl: results[4] as String,
        );
        _loadingDetail = false;
        _detailTabController.index = 0;
      });
    } catch (e) {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  void _toggleFavorite(String db, String table) {
    final key = '$db.$table';
    setState(() {
      if (_favorites.contains(key)) {
        _favorites.remove(key);
      } else {
        _favorites.add(key);
      }
    });
  }

  bool _isFavorite(String db, String table) =>
      _favorites.contains('$db.$table');

  List<TableInfo> get _filteredTables {
    if (_searchQuery.isEmpty) return _tables;
    return _tables
        .where((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // ── Toolbar ──
        _buildToolbar(cs, isDark),
        const Divider(height: 1),
        // ── Main content ──
        Expanded(
          child: Row(
            children: [
              // Left sidebar
              if (!_sidebarCollapsed) ...[
                SizedBox(
                  width: 280,
                  child: _buildSidebar(theme, cs, isDark),
                ),
                _buildSidebarDivider(cs),
              ],
              // Main panel
              Expanded(
                child: _buildMainPanel(theme, cs, isDark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(ColorScheme cs, bool isDark) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withAlpha(60)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(Icons.explore_outlined, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Text(
            'Schema Explorer',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: cs.onSurface,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 16),
          const VerticalDivider(width: 1, indent: 8, endIndent: 8),
          const SizedBox(width: 8),
          // DB picker
          const Text('Database:', style: TextStyle(fontSize: 11)),
          const SizedBox(width: 6),
          _loadingDbs
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5))
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDb,
                    hint: const Text('Select…',
                        style: TextStyle(fontSize: 11)),
                    isDense: true,
                    style: TextStyle(fontSize: 11, color: cs.onSurface),
                    items: _databases
                        .map((db) => DropdownMenuItem(
                              value: db,
                              child: Text(db),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _selectDatabase(v);
                    },
                  ),
                ),
          const Spacer(),
          // Sidebar toggle
          _ToolbarBtn(
            icon: _sidebarCollapsed
                ? Icons.menu_open
                : Icons.view_sidebar_outlined,
            tooltip:
                _sidebarCollapsed ? 'Show sidebar' : 'Hide sidebar',
            onTap: () =>
                setState(() => _sidebarCollapsed = !_sidebarCollapsed),
          ),
          const SizedBox(width: 4),
          // Export
          _ToolbarBtn(
            icon: Icons.download_outlined,
            tooltip: 'Export schema as JSON',
            onTap: _selectedDb == null ? null : _exportSchemaJson,
          ),
          if (_tables.isNotEmpty) ...[
            const VerticalDivider(width: 1, indent: 8, endIndent: 8),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withAlpha(120),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_tables.where((t) => !t.isView).length} tables · ${_tables.where((t) => t.isView).length} views',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
          ],
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildSidebarDivider(ColorScheme cs) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: Container(
        width: 1,
        color: cs.outlineVariant.withAlpha(80),
      ),
    );
  }

  Widget _buildSidebar(ThemeData theme, ColorScheme cs, bool isDark) {
    return Container(
      color: isDark
          ? cs.surface.withAlpha(200)
          : cs.surfaceContainerLow,
      child: Column(
        children: [
          // Search
          Container(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tables & columns…',
                hintStyle: TextStyle(fontSize: 11, color: cs.onSurface.withAlpha(120)),
                prefixIcon:
                    Icon(Icons.search, size: 16, color: cs.primary),
                isDense: true,
                filled: true,
                fillColor: isDark
                    ? cs.surface
                    : cs.surfaceContainerHighest.withAlpha(180),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 10),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 14),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              style: const TextStyle(fontSize: 12),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // Favorites section
          if (_favorites.isNotEmpty) ...[
            _SidebarSection(
              title: 'FAVORITES',
              icon: Icons.star,
              iconColor: Colors.amber.shade600,
              child: Column(
                children: _favorites.map((key) {
                  final parts = key.split('.');
                  if (parts.length < 2) return const SizedBox.shrink();
                  final db = parts[0];
                  final table = parts.sublist(1).join('.');
                  final isSelected = _selectedDetail?.database == db &&
                      _selectedDetail?.tableName == table;
                  return _TableListTile(
                    tableName: table,
                    dbName: db,
                    isSelected: isSelected,
                    isFavorite: true,
                    onTap: () => _selectTable(db, table),
                    onFavorite: () => _toggleFavorite(db, table),
                  );
                }).toList(),
              ),
            ),
          ],

          // Recents section
          if (_recents.isNotEmpty) ...[
            _SidebarSection(
              title: 'RECENT',
              icon: Icons.history,
              iconColor: cs.tertiary,
              child: Column(
                children: _recents.take(5).map((entry) {
                  final isSelected =
                      _selectedDetail?.database == entry.db &&
                          _selectedDetail?.tableName == entry.table;
                  return _TableListTile(
                    tableName: entry.table,
                    dbName: entry.db,
                    isSelected: isSelected,
                    isFavorite: _isFavorite(entry.db, entry.table),
                    onTap: () => _selectTable(entry.db, entry.table),
                    onFavorite: () =>
                        _toggleFavorite(entry.db, entry.table),
                  );
                }).toList(),
              ),
            ),
          ],

          // Tables list
          Expanded(
            child: _loadingTables
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2))
                : _selectedDb == null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.storage_outlined,
                                size: 32,
                                color: cs.primary.withAlpha(80)),
                            const SizedBox(height: 8),
                            Text('Select a database',
                                style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        cs.onSurface.withAlpha(120))),
                          ],
                        ),
                      )
                    : _buildTablesList(theme, cs, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildTablesList(ThemeData theme, ColorScheme cs, bool isDark) {
    final tables = _filteredTables.where((t) => !t.isView).toList();
    final views = _filteredTables.where((t) => t.isView).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        // Tables
        _SidebarSection(
          title: 'TABLES (${tables.length})',
          icon: Icons.table_rows_outlined,
          iconColor: cs.secondary,
          child: Column(
            children: tables.map((t) {
              final isSelected =
                  _selectedDetail?.tableName == t.name &&
                      _selectedDetail?.database == _selectedDb;
              return _TableListTile(
                tableName: t.name,
                estimatedRows: t.estimatedRows,
                isSelected: isSelected,
                isFavorite: _isFavorite(_selectedDb!, t.name),
                onTap: () => _selectTable(_selectedDb!, t.name),
                onFavorite: () =>
                    _toggleFavorite(_selectedDb!, t.name),
              );
            }).toList(),
          ),
        ),
        // Views
        if (views.isNotEmpty)
          _SidebarSection(
            title: 'VIEWS (${views.length})',
            icon: Icons.remove_red_eye_outlined,
            iconColor: cs.tertiary,
            child: Column(
              children: views.map((v) {
                final isSelected =
                    _selectedDetail?.tableName == v.name &&
                        _selectedDetail?.database == _selectedDb;
                return _TableListTile(
                  tableName: v.name,
                  isView: true,
                  isSelected: isSelected,
                  isFavorite: _isFavorite(_selectedDb!, v.name),
                  onTap: () => _selectTable(_selectedDb!, v.name),
                  onFavorite: () =>
                      _toggleFavorite(_selectedDb!, v.name),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildMainPanel(ThemeData theme, ColorScheme cs, bool isDark) {
    if (_selectedDetail == null && !_loadingDetail) {
      return _EmptyMainPanel(cs: cs, isDark: isDark);
    }

    if (_loadingDetail) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: cs.primary),
            ),
            const SizedBox(height: 12),
            Text('Loading table details…',
                style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withAlpha(120))),
          ],
        ),
      );
    }

    final detail = _selectedDetail!;
    return Column(
      children: [
        // Table header
        _buildTableHeader(detail, cs, isDark),
        // Tab bar
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withAlpha(80),
            border: Border(
              bottom: BorderSide(color: cs.outlineVariant.withAlpha(60)),
            ),
          ),
          child: TabBar(
            controller: _detailTabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(
                height: 32,
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.view_column_outlined, size: 14),
                      SizedBox(width: 4),
                      Text('Columns'),
                    ]),
              ),
              Tab(
                height: 32,
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.link, size: 14),
                      SizedBox(width: 4),
                      Text('Relationships'),
                    ]),
              ),
              Tab(
                height: 32,
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.code, size: 14),
                      SizedBox(width: 4),
                      Text('SQL Preview'),
                    ]),
              ),
              Tab(
                height: 32,
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.security_outlined, size: 14),
                      SizedBox(width: 4),
                      Text('Constraints'),
                    ]),
              ),
            ],
          ),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _detailTabController,
            children: [
              _ColumnsTab(detail: detail, cs: cs, isDark: isDark,
                  onNavigateToTable: _navigateToFkTable),
              _RelationshipsTab(detail: detail, cs: cs, isDark: isDark,
                  onNavigateToTable: _navigateToFkTable),
              _SqlPreviewTab(detail: detail, cs: cs, isDark: isDark),
              _ConstraintsTab(detail: detail, cs: cs, isDark: isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(
      TableDetail detail, ColorScheme cs, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [cs.primary.withAlpha(30), cs.surface]
              : [cs.primary.withAlpha(15), cs.surface],
        ),
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withAlpha(60)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withAlpha(150),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.table_rows_outlined,
                size: 20, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      detail.tableName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        detail.database,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: cs.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.view_column_outlined,
                      label: '${detail.columns.length} columns',
                      color: cs.primary,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      icon: Icons.vpn_key_outlined,
                      label: '${detail.primaryKeyColumns.length} PK',
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      icon: Icons.link,
                      label: '${detail.foreignKeys.length} FK',
                      color: cs.tertiary,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      icon: Icons.call_made,
                      label:
                          '${detail.referencedBy.length} refs',
                      color: Colors.green.shade600,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Action buttons
          IconButton(
            icon: Icon(
              _isFavorite(detail.database, detail.tableName)
                  ? Icons.star
                  : Icons.star_border,
              color: _isFavorite(detail.database, detail.tableName)
                  ? Colors.amber.shade600
                  : cs.onSurface.withAlpha(100),
              size: 20,
            ),
            tooltip: 'Toggle favorite',
            onPressed: () =>
                _toggleFavorite(detail.database, detail.tableName),
          ),
          IconButton(
            icon:
                Icon(Icons.copy, size: 16, color: cs.onSurface.withAlpha(120)),
            tooltip: 'Copy table name',
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: detail.tableName)),
          ),
        ],
      ),
    );
  }

  void _navigateToFkTable(String refTable) {
    if (_selectedDb != null) {
      _selectTable(_selectedDb!, refTable);
    }
  }

  Future<void> _exportSchemaJson() async {
    if (_selectedDb == null) return;

    final conn = widget.session.mysqlConnection;
    final tables = await _fetcher.fetchTables(conn, _selectedDb!);
    final schema = <String, dynamic>{
      'database': _selectedDb,
      'exportedAt': DateTime.now().toIso8601String(),
      'tables': <Map<String, dynamic>>[],
    };

    for (final t in tables.where((t) => !t.isView)) {
      final cols = await _fetcher.fetchColumns(conn, _selectedDb!, t.name);
      final fks = await _fetcher.fetchForeignKeys(conn, _selectedDb!);
      final tableFks = fks.where((fk) => fk.table == t.name).toList();

      (schema['tables'] as List).add({
        'name': t.name,
        'type': t.type,
        'estimatedRows': t.estimatedRows,
        'columns': cols
            .map((c) => {
                  'name': c.name,
                  'dataType': c.dataType,
                  'columnType': c.columnType,
                  'isNullable': c.isNullable,
                  'default': c.columnDefault,
                  'extra': c.extra,
                  'key': c.columnKey,
                })
            .toList(),
        'foreignKeys': tableFks
            .map((fk) => {
                  'column': fk.column,
                  'refTable': fk.refTable,
                  'refColumn': fk.refColumn,
                })
            .toList(),
      });
    }

    final jsonStr =
        const JsonEncoder.withIndent('  ').convert(schema);
    await Clipboard.setData(ClipboardData(text: jsonStr));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Schema JSON copied to clipboard (${tables.length} tables)'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TABS
// ═══════════════════════════════════════════════════════════════════════════════

/// Columns tab — detailed column list with badges
class _ColumnsTab extends StatelessWidget {
  final TableDetail detail;
  final ColorScheme cs;
  final bool isDark;
  final void Function(String table) onNavigateToTable;

  const _ColumnsTab({
    required this.detail,
    required this.cs,
    required this.isDark,
    required this.onNavigateToTable,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: detail.columns.length,
      itemBuilder: (ctx, i) {
        final col = detail.columns[i];
        // Find FK info for this column
        final fkInfo = detail.foreignKeys
            .where((fk) => fk.column == col.name)
            .firstOrNull;

        return Container(
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: i.isEven
                ? (isDark
                    ? cs.surface.withAlpha(180)
                    : cs.surfaceContainerLowest)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: col.isPrimaryKey
                ? Border.all(
                    color: Colors.amber.shade600.withAlpha(50), width: 1)
                : null,
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Index
                SizedBox(
                  width: 28,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      color: cs.onSurface.withAlpha(80),
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                // Key icon
                SizedBox(
                  width: 24,
                  child: _buildKeyIcon(col),
                ),
                // Column name
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Text(
                        col.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: col.isPrimaryKey
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontFamily: 'monospace',
                          color: col.isPrimaryKey
                              ? Colors.amber.shade700
                              : cs.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Badges
                      ...(_buildBadges(col)),
                    ],
                  ),
                ),
                // Data type
                Expanded(
                  flex: 2,
                  child: Text(
                    col.columnType ?? col.dataType,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.primary.withAlpha(200),
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                // Nullable
                SizedBox(
                  width: 60,
                  child: col.isNullable
                      ? Text(
                          'NULL',
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurface.withAlpha(100),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.block,
                                size: 10,
                                color: cs.error.withAlpha(180)),
                            const SizedBox(width: 2),
                            Text(
                              'NOT NULL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: cs.error.withAlpha(180),
                              ),
                            ),
                          ],
                        ),
                ),
                // Default
                SizedBox(
                  width: 80,
                  child: Text(
                    col.columnDefault ?? '—',
                    style: TextStyle(
                      fontSize: 10,
                      color: cs.onSurface.withAlpha(100),
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // FK ref link
                if (fkInfo != null)
                  InkWell(
                    onTap: () => onNavigateToTable(fkInfo.refTable),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.tertiaryContainer.withAlpha(100),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_forward,
                              size: 10, color: cs.tertiary),
                          const SizedBox(width: 3),
                          Text(
                            '${fkInfo.refTable}.${fkInfo.refColumn}',
                            style: TextStyle(
                              fontSize: 10,
                              color: cs.tertiary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKeyIcon(ColumnInfo col) {
    if (col.isPrimaryKey) {
      return Icon(Icons.vpn_key, size: 13, color: Colors.amber.shade600);
    }
    if (col.isForeignKey) {
      return Icon(Icons.link, size: 13, color: cs.tertiary);
    }
    if (col.isUniqueKey) {
      return Icon(Icons.fingerprint, size: 13, color: cs.secondary);
    }
    return Icon(Icons.horizontal_rule,
        size: 13, color: cs.onSurface.withAlpha(40));
  }

  List<Widget> _buildBadges(ColumnInfo col) {
    final badges = <Widget>[];
    if (col.isPrimaryKey) {
      badges.add(_Badge(
          label: 'PK', color: Colors.amber.shade700, bgColor: Colors.amber.shade100));
    }
    if (col.isForeignKey) {
      badges.add(_Badge(label: 'FK', color: cs.tertiary, bgColor: cs.tertiaryContainer));
    }
    if (col.isUniqueKey) {
      badges.add(_Badge(label: 'UQ', color: cs.secondary, bgColor: cs.secondaryContainer));
    }
    if (col.extra?.contains('auto_increment') ?? false) {
      badges.add(_Badge(label: 'AI', color: cs.primary, bgColor: cs.primaryContainer));
    }
    return badges;
  }
}

/// Relationships tab — foreign keys and referenced-by
class _RelationshipsTab extends StatelessWidget {
  final TableDetail detail;
  final ColorScheme cs;
  final bool isDark;
  final void Function(String table) onNavigateToTable;

  const _RelationshipsTab({
    required this.detail,
    required this.cs,
    required this.isDark,
    required this.onNavigateToTable,
  });

  @override
  Widget build(BuildContext context) {
    if (detail.foreignKeys.isEmpty && detail.referencedBy.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_off, size: 40, color: cs.onSurface.withAlpha(60)),
            const SizedBox(height: 8),
            Text('No relationships found',
                style: TextStyle(
                    fontSize: 12, color: cs.onSurface.withAlpha(100))),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Foreign Keys (outgoing)
        if (detail.foreignKeys.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.arrow_forward,
            title: 'References (${detail.foreignKeys.length})',
            subtitle: 'This table references other tables',
            color: cs.tertiary,
          ),
          const SizedBox(height: 8),
          ...detail.foreignKeys.map((fk) => _RelationshipCard(
                fk: fk,
                isOutgoing: true,
                cs: cs,
                isDark: isDark,
                onNavigate: () => onNavigateToTable(fk.refTable),
              )),
          const SizedBox(height: 20),
        ],
        // Referenced By (incoming)
        if (detail.referencedBy.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.arrow_back,
            title: 'Referenced By (${detail.referencedBy.length})',
            subtitle: 'Other tables referencing this table',
            color: Colors.green.shade600,
          ),
          const SizedBox(height: 8),
          ...detail.referencedBy.map((fk) => _RelationshipCard(
                fk: fk,
                isOutgoing: false,
                cs: cs,
                isDark: isDark,
                onNavigate: () => onNavigateToTable(fk.table),
              )),
        ],
      ],
    );
  }
}

/// SQL Preview tab — CREATE TABLE DDL with syntax highlighting
class _SqlPreviewTab extends StatelessWidget {
  final TableDetail detail;
  final ColorScheme cs;
  final bool isDark;

  const _SqlPreviewTab({
    required this.detail,
    required this.cs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Copy bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withAlpha(60),
            border: Border(
              bottom: BorderSide(color: cs.outlineVariant.withAlpha(60)),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.code,
                  size: 14, color: cs.onSurface.withAlpha(120)),
              const SizedBox(width: 6),
              Text('CREATE TABLE — ${detail.tableName}',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withAlpha(160))),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.copy, size: 14),
                label: const Text('Copy DDL', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: detail.createTableDdl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('DDL copied to clipboard'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        // SQL content
        Expanded(
          child: Container(
            width: double.infinity,
            color: isDark
                ? const Color(0xFF1E1E2E)
                : const Color(0xFFFAFAFC),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                detail.createTableDdl,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  height: 1.6,
                  color: isDark
                      ? const Color(0xFFCDD6F4)
                      : const Color(0xFF1E1E2E),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Constraints tab — structured view of all constraints
class _ConstraintsTab extends StatelessWidget {
  final TableDetail detail;
  final ColorScheme cs;
  final bool isDark;

  const _ConstraintsTab({
    required this.detail,
    required this.cs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (detail.constraints.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.security_outlined,
                size: 40, color: cs.onSurface.withAlpha(60)),
            const SizedBox(height: 8),
            Text('No constraints found',
                style: TextStyle(
                    fontSize: 12, color: cs.onSurface.withAlpha(100))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: detail.constraints.length,
      itemBuilder: (ctx, i) {
        final c = detail.constraints[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark
                ? cs.surface.withAlpha(200)
                : cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _constraintColor(c.constraintType).withAlpha(60),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _constraintColor(c.constraintType)
                        .withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _constraintIcon(c.constraintType),
                    size: 16,
                    color: _constraintColor(c.constraintType),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            c.constraintName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color:
                                  _constraintColor(c.constraintType)
                                      .withAlpha(25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              c.constraintType,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: _constraintColor(
                                    c.constraintType),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Columns: ${c.columns.join(', ')}',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withAlpha(140),
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (c.refTable != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'References: ${c.refTable}.${c.refColumn}',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.tertiary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _constraintColor(String type) => switch (type) {
        'PRIMARY KEY' => Colors.amber.shade700,
        'FOREIGN KEY' => Colors.teal.shade500,
        'UNIQUE' => Colors.blue.shade500,
        _ => Colors.grey,
      };

  IconData _constraintIcon(String type) => switch (type) {
        'PRIMARY KEY' => Icons.vpn_key,
        'FOREIGN KEY' => Icons.link,
        'UNIQUE' => Icons.fingerprint,
        _ => Icons.security,
      };
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  const _ToolbarBtn({required this.icon, required this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Icon(icon,
              size: 15,
              color: onTap == null
                  ? Theme.of(context).colorScheme.onSurface.withAlpha(60)
                  : null),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  const _Badge(
      {required this.label, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: bgColor.withAlpha(180),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withAlpha(80), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color.withAlpha(180)),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: color.withAlpha(180),
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _SidebarSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _SidebarSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              Icon(icon, size: 12, color: iconColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface.withAlpha(120),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class _TableListTile extends StatefulWidget {
  final String tableName;
  final String? dbName;
  final int estimatedRows;
  final bool isView;
  final bool isSelected;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const _TableListTile({
    required this.tableName,
    this.dbName,
    this.estimatedRows = 0,
    this.isView = false,
    this.isSelected = false,
    this.isFavorite = false,
    required this.onTap,
    required this.onFavorite,
  });

  @override
  State<_TableListTile> createState() => _TableListTileState();
}

class _TableListTileState extends State<_TableListTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? cs.primaryContainer.withAlpha(150)
              : _hovered
                  ? cs.primary.withAlpha(20)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: widget.isSelected
              ? Border.all(color: cs.primary.withAlpha(100), width: 1)
              : null,
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              children: [
                Icon(
                  widget.isView
                      ? Icons.remove_red_eye_outlined
                      : Icons.table_rows_outlined,
                  size: 13,
                  color: widget.isSelected
                      ? cs.primary
                      : cs.onSurface.withAlpha(140),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.tableName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: widget.isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: cs.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.dbName != null)
                        Text(
                          widget.dbName!,
                          style: TextStyle(
                            fontSize: 9,
                            color: cs.onSurface.withAlpha(80),
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.estimatedRows > 0)
                  Text(
                    _fmtRows(widget.estimatedRows),
                    style: TextStyle(
                      fontSize: 9,
                      color: cs.onSurface.withAlpha(80),
                    ),
                  ),
                if (_hovered || widget.isFavorite)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: InkWell(
                      onTap: widget.onFavorite,
                      borderRadius: BorderRadius.circular(4),
                      child: Icon(
                        widget.isFavorite
                            ? Icons.star
                            : Icons.star_border,
                        size: 13,
                        color: widget.isFavorite
                            ? Colors.amber.shade600
                            : cs.onSurface.withAlpha(80),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _fmtRows(int n) {
    if (n >= 1000000) return '~${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '~${(n / 1000).toStringAsFixed(1)}K';
    return '~$n';
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface)),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(100))),
          ],
        ),
      ],
    );
  }
}

class _RelationshipCard extends StatelessWidget {
  final ForeignKeyInfo fk;
  final bool isOutgoing;
  final ColorScheme cs;
  final bool isDark;
  final VoidCallback onNavigate;

  const _RelationshipCard({
    required this.fk,
    required this.isOutgoing,
    required this.cs,
    required this.isDark,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOutgoing ? cs.tertiary : Colors.green.shade600;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isDark ? cs.surface.withAlpha(200) : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: InkWell(
        onTap: onNavigate,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isOutgoing ? Icons.arrow_forward : Icons.arrow_back,
                  size: 14,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isOutgoing ? fk.refTable : fk.table,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                            color: color,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.open_in_new, size: 10, color: color),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isOutgoing
                          ? '${fk.column} → ${fk.refTable}.${fk.refColumn}'
                          : '${fk.table}.${fk.column} → ${fk.refColumn}',
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurface.withAlpha(120),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 16, color: cs.onSurface.withAlpha(60)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMainPanel extends StatelessWidget {
  final ColorScheme cs;
  final bool isDark;
  const _EmptyMainPanel({required this.cs, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.explore_outlined,
                size: 48, color: cs.primary.withAlpha(100)),
          ),
          const SizedBox(height: 16),
          Text(
            'Select a table to explore',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withAlpha(160),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose a database and click on a table in the sidebar',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withAlpha(100),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FeatureChip(
                  icon: Icons.view_column_outlined, label: 'Column Details'),
              const SizedBox(width: 8),
              _FeatureChip(icon: Icons.link, label: 'Relationships'),
              const SizedBox(width: 8),
              _FeatureChip(icon: Icons.code, label: 'SQL Preview'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(120),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: cs.primary),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withAlpha(160))),
        ],
      ),
    );
  }
}
