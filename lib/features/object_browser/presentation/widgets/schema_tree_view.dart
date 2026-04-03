import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../mysql/mysql_schema_fetcher.dart';
import '../../../query_editor/presentation/providers/query_editor_providers.dart';
import '../../../results_grid/presentation/providers/selected_table_provider.dart';
import '../../../workspace/domain/entities/workspace_session.dart';
import '../../../workspace/presentation/providers/workspace_provider.dart';
import '../providers/schema_tree_provider.dart';
import 'tree_node_tile.dart';

/// SQLyog-style tree: databases → grouped categories → objects.
///
/// Under each expanded database:
///   ▼ Tables  ▼ Views  ▶ Stored Procs  ▶ Functions  ▶ Triggers  ▶ Events
class SchemaTreeView extends ConsumerStatefulWidget {
  final WorkspaceSession session;
  final String filter;

  /// Called when the user double-taps a table — consumer can switch to Table Data tab.
  final VoidCallback? onTableDoubleClick;

  const SchemaTreeView({
    super.key,
    required this.session,
    this.filter = '',
    this.onTableDoubleClick,
  });

  @override
  ConsumerState<SchemaTreeView> createState() => _SchemaTreeViewState();
}

class _SchemaTreeViewState extends ConsumerState<SchemaTreeView> {
  final Set<String> _expandedDbs = {};
  // Keys: 'db::tables', 'db::views', 'db::procs', 'db::funcs', 'db::triggers', 'db::events'
  final Set<String> _expandedCats = {};
  final Set<String> _expandedTables = {};

  @override
  Widget build(BuildContext context) {
    final conn = widget.session.mysqlConnection;
    final dbAsync = ref.watch(schemaDatabasesProvider(conn));

    return dbAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text('Error: $e', style: const TextStyle(fontSize: 12)),
            ),
          ),
      data: (databases) {
        final filtered =
            widget.filter.isEmpty
                ? databases
                : databases
                    .where((d) => d.name.toLowerCase().contains(widget.filter))
                    .toList();

        if (filtered.isEmpty) {
          return const Center(
            child: Text('No databases found', style: TextStyle(fontSize: 12)),
          );
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (ctx, i) {
            final db = filtered[i];
            final isExpanded = _expandedDbs.contains(db.name);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Database node ───────────────────────────────────────────
                TreeNodeTile(
                  label: db.name,
                  type: TreeNodeType.database,
                  isExpanded: isExpanded,
                  onTap:
                      () => setState(
                        () =>
                            isExpanded
                                ? _expandedDbs.remove(db.name)
                                : _expandedDbs.add(db.name),
                      ),
                  contextMenuItems: [
                    const PopupMenuItem(
                      value: 'use_db',
                      child: Text('Use Database'),
                    ),
                    const PopupMenuItem(
                      value: 'copy_name',
                      child: Text('Copy Name'),
                    ),
                  ],
                  onContextMenuSelected:
                      (action) => _onDbAction(action, db.name),
                ),
                if (isExpanded)
                  _DbCategories(
                    session: widget.session,
                    database: db.name,
                    filter: widget.filter,
                    expandedCats: _expandedCats,
                    expandedTables: _expandedTables,
                    onToggleCat:
                        (key) => setState(
                          () =>
                              _expandedCats.contains(key)
                                  ? _expandedCats.remove(key)
                                  : _expandedCats.add(key),
                        ),
                    onToggleTable:
                        (key) => setState(
                          () =>
                              _expandedTables.contains(key)
                                  ? _expandedTables.remove(key)
                                  : _expandedTables.add(key),
                        ),
                    onTableAction: _onTableAction,
                    onTableDoubleClick: widget.onTableDoubleClick,
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _onDbAction(String action, String dbName) {
    switch (action) {
      case 'use_db':
        final session = widget.session;
        final activeTab =
            session.tabs.where((t) => t.id == session.activeTabId).firstOrNull;
        if (activeTab != null) {
          ref
              .read(workspaceProvider.notifier)
              .updateTabDatabase(session.sessionId, activeTab.id, dbName);
        }
      case 'copy_name':
        Clipboard.setData(ClipboardData(text: dbName));
    }
  }

  void _onTableAction(String action, String dbName, String tableName) {
    switch (action) {
      case 'select_1000':
        final sql = 'SELECT * FROM `$dbName`.`$tableName` LIMIT 1000;';
        final session = widget.session;
        final activeTab =
            session.tabs.where((t) => t.id == session.activeTabId).firstOrNull;
        if (activeTab != null) {
          ref.read(editorContentProvider(activeTab.id).notifier).update(sql);
          ref
              .read(workspaceProvider.notifier)
              .updateTabDatabase(session.sessionId, activeTab.id, dbName);
          ref
              .read(queryExecutionProvider(activeTab.id).notifier)
              .execute(
                sql: sql,
                sessionId: session.sessionId,
                database: dbName,
              );
        }
      case 'copy_name':
        Clipboard.setData(ClipboardData(text: tableName));
      case 'copy_qualified':
        Clipboard.setData(ClipboardData(text: '`$dbName`.`$tableName`'));
    }
  }
}

// ── Per-database category list ─────────────────────────────────────────────────

class _DbCategories extends ConsumerWidget {
  final WorkspaceSession session;
  final String database;
  final String filter;
  final Set<String> expandedCats;
  final Set<String> expandedTables;
  final void Function(String key) onToggleCat;
  final void Function(String key) onToggleTable;
  final void Function(String action, String db, String table) onTableAction;
  final VoidCallback? onTableDoubleClick;

  const _DbCategories({
    required this.session,
    required this.database,
    required this.filter,
    required this.expandedCats,
    required this.expandedTables,
    required this.onToggleCat,
    required this.onToggleTable,
    required this.onTableAction,
    this.onTableDoubleClick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(
      schemaTablesProvider(session.mysqlConnection, database),
    );

    return tablesAsync.when(
      loading:
          () => const Padding(
            padding: EdgeInsets.only(left: 24, top: 4, bottom: 4),
            child: SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
          ),
      error: (_, s) => const SizedBox.shrink(),
      data: (tableNodes) {
        final tables =
            tableNodes
                .where((t) => !t.isView)
                .where(
                  (t) =>
                      filter.isEmpty || t.name.toLowerCase().contains(filter),
                )
                .toList();
        final views =
            tableNodes
                .where((t) => t.isView)
                .where(
                  (t) =>
                      filter.isEmpty || t.name.toLowerCase().contains(filter),
                )
                .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tables category
            _CategorySection(
              catKey: '$database::tables',
              label: 'Tables',
              count: tables.length,
              type: TreeNodeType.table,
              isExpanded: expandedCats.contains('$database::tables'),
              onToggle: () => onToggleCat('$database::tables'),
              child: Column(
                children:
                    tables.map((t) {
                      final key = '$database.${t.name}';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 32),
                            child: TreeNodeTile(
                              label: t.name,
                              type: TreeNodeType.table,
                              isExpanded: expandedTables.contains(key),
                              subtitle:
                                  t.estimatedRows > 0
                                      ? _fmtRows(t.estimatedRows)
                                      : null,
                              onTap: () => onToggleTable(key),
                              onDoubleTap: () {
                                // Set selected table so Table Data tab auto-loads it.
                                ref
                                    .read(
                                      selectedTableProvider(
                                        session.sessionId,
                                      ).notifier,
                                    )
                                    .state = SelectedTable(
                                  database: database,
                                  table: t.name,
                                );
                                onTableDoubleClick?.call();
                              },
                              contextMenuItems: [
                                const PopupMenuItem(
                                  value: 'select_1000',
                                  child: Text('Select Top 1000 Rows'),
                                ),
                                const PopupMenuItem(
                                  value: 'open_table_data',
                                  child: Text('Open in Table Data'),
                                ),
                                const PopupMenuItem(
                                  value: 'copy_name',
                                  child: Text('Copy Table Name'),
                                ),
                                const PopupMenuItem(
                                  value: 'copy_qualified',
                                  child: Text('Copy Qualified Name'),
                                ),
                              ],
                              onContextMenuSelected: (action) {
                                if (action == 'open_table_data') {
                                  ref
                                      .read(
                                        selectedTableProvider(
                                          session.sessionId,
                                        ).notifier,
                                      )
                                      .state = SelectedTable(
                                    database: database,
                                    table: t.name,
                                  );
                                  onTableDoubleClick?.call();
                                } else {
                                  onTableAction(action, database, t.name);
                                }
                              },
                            ),
                          ),
                          if (expandedTables.contains(key))
                            _ColumnList(
                              session: session,
                              database: database,
                              table: t.name,
                            ),
                        ],
                      );
                    }).toList(),
              ),
            ),

            // Views category
            if (views.isNotEmpty)
              _CategorySection(
                catKey: '$database::views',
                label: 'Views',
                count: views.length,
                type: TreeNodeType.view,
                isExpanded: expandedCats.contains('$database::views'),
                onToggle: () => onToggleCat('$database::views'),
                child: Column(
                  children:
                      views
                          .map(
                            (v) => Padding(
                              padding: const EdgeInsets.only(left: 32),
                              child: TreeNodeTile(
                                label: v.name,
                                type: TreeNodeType.view,
                                isExpanded: false,
                                onTap:
                                    () => onTableAction(
                                      'select_1000',
                                      database,
                                      v.name,
                                    ),
                                contextMenuItems: [
                                  const PopupMenuItem(
                                    value: 'select_1000',
                                    child: Text('Select Top 1000 Rows'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'copy_name',
                                    child: Text('Copy Name'),
                                  ),
                                ],
                                onContextMenuSelected:
                                    (action) =>
                                        onTableAction(action, database, v.name),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),

            // Stored Procs
            _LazyCategory(
              catKey: '$database::procs',
              label: 'Stored Procs',
              type: TreeNodeType.storedProc,
              isExpanded: expandedCats.contains('$database::procs'),
              onToggle: () => onToggleCat('$database::procs'),
              future:
                  () => MysqlSchemaFetcher().fetchRoutines(
                    session.mysqlConnection,
                    database,
                    'PROCEDURE',
                  ),
              itemBuilder:
                  (name) => Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: TreeNodeTile(
                      label: name,
                      type: TreeNodeType.storedProc,
                      isExpanded: false,
                      onTap: () {},
                      contextMenuItems: [
                        PopupMenuItem(
                          value: 'copy_call',
                          child: Text('Copy: CALL $name()'),
                        ),
                      ],
                      onContextMenuSelected: (action) {
                        if (action == 'copy_call') {
                          Clipboard.setData(
                            ClipboardData(text: 'CALL $name()'),
                          );
                        }
                      },
                    ),
                  ),
            ),

            // Functions
            _LazyCategory(
              catKey: '$database::funcs',
              label: 'Functions',
              type: TreeNodeType.function,
              isExpanded: expandedCats.contains('$database::funcs'),
              onToggle: () => onToggleCat('$database::funcs'),
              future:
                  () => MysqlSchemaFetcher()
                      .fetchRoutines(
                        session.mysqlConnection,
                        database,
                        'FUNCTION',
                      )
                      .then((r) => r.map((x) => RoutineInfo(x.name)).toList()),
              itemBuilder:
                  (name) => Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: TreeNodeTile(
                      label: name,
                      type: TreeNodeType.function,
                      isExpanded: false,
                      onTap: () {},
                      contextMenuItems: [
                        PopupMenuItem(
                          value: 'copy',
                          child: Text('Copy: $name'),
                        ),
                      ],
                      onContextMenuSelected: (action) {
                        if (action == 'copy') {
                          Clipboard.setData(ClipboardData(text: name));
                        }
                      },
                    ),
                  ),
            ),

            // Triggers
            _LazyCategory(
              catKey: '$database::triggers',
              label: 'Triggers',
              type: TreeNodeType.trigger,
              isExpanded: expandedCats.contains('$database::triggers'),
              onToggle: () => onToggleCat('$database::triggers'),
              future:
                  () => MysqlSchemaFetcher()
                      .fetchTriggers(session.mysqlConnection, database)
                      .then((r) => r.map((x) => RoutineInfo(x.name)).toList()),
              itemBuilder:
                  (name) => Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: TreeNodeTile(
                      label: name,
                      type: TreeNodeType.trigger,
                      isExpanded: false,
                      onTap: () {},
                    ),
                  ),
            ),

            // Events
            _LazyCategory(
              catKey: '$database::events',
              label: 'Events',
              type: TreeNodeType.event,
              isExpanded: expandedCats.contains('$database::events'),
              onToggle: () => onToggleCat('$database::events'),
              future:
                  () => MysqlSchemaFetcher()
                      .fetchEvents(session.mysqlConnection, database)
                      .then((r) => r.map((x) => RoutineInfo(x.name)).toList()),
              itemBuilder:
                  (name) => Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: TreeNodeTile(
                      label: name,
                      type: TreeNodeType.event,
                      isExpanded: false,
                      onTap: () {},
                    ),
                  ),
            ),
          ],
        );
      },
    );
  }

  static String _fmtRows(int n) {
    if (n >= 1000000) return '~${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '~${(n / 1000).toStringAsFixed(1)}K';
    return '~$n';
  }
}

// ── Category section (always shown, collapsible) ──────────────────────────────

class _CategorySection extends StatelessWidget {
  final String catKey;
  final String label;
  final int count;
  final TreeNodeType type;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  const _CategorySection({
    required this.catKey,
    required this.label,
    required this.count,
    required this.type,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: TreeNodeTile(
            label: label,
            type: TreeNodeType.category,
            isExpanded: isExpanded,
            subtitle: '($count)',
            onTap: onToggle,
          ),
        ),
        if (isExpanded) child,
      ],
    );
  }
}

// ── Lazy-loaded category (fetches on first expand) ────────────────────────────

class _LazyCategory extends StatefulWidget {
  final String catKey;
  final String label;
  final TreeNodeType type;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Future<List<RoutineInfo>> Function() future;
  final Widget Function(String name) itemBuilder;

  const _LazyCategory({
    required this.catKey,
    required this.label,
    required this.type,
    required this.isExpanded,
    required this.onToggle,
    required this.future,
    required this.itemBuilder,
  });

  @override
  State<_LazyCategory> createState() => _LazyCategoryState();
}

class _LazyCategoryState extends State<_LazyCategory> {
  Future<List<RoutineInfo>>? _future;

  @override
  void didUpdateWidget(_LazyCategory old) {
    super.didUpdateWidget(old);
    if (widget.isExpanded && _future == null) {
      _future = widget.future();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isExpanded && _future == null) {
      _future = widget.future();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: TreeNodeTile(
            label: widget.label,
            type: TreeNodeType.category,
            isExpanded: widget.isExpanded,
            onTap: widget.onToggle,
          ),
        ),
        if (widget.isExpanded && _future != null)
          FutureBuilder<List<RoutineInfo>>(
            future: _future,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(left: 48, top: 4, bottom: 4),
                  child: SizedBox(
                    height: 12,
                    width: 12,
                    child: CircularProgressIndicator(strokeWidth: 1),
                  ),
                );
              }
              final items = snap.data ?? [];
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(left: 48, top: 2, bottom: 4),
                  child: Text(
                    '(none)',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                );
              }
              return Column(
                children: items.map((r) => widget.itemBuilder(r.name)).toList(),
              );
            },
          ),
      ],
    );
  }
}

// ── Column sub-nodes ──────────────────────────────────────────────────────────

class _ColumnList extends StatefulWidget {
  final WorkspaceSession session;
  final String database;
  final String table;

  const _ColumnList({
    required this.session,
    required this.database,
    required this.table,
  });

  @override
  State<_ColumnList> createState() => _ColumnListState();
}

class _ColumnListState extends State<_ColumnList> {
  late Future<List<ColumnInfo>> _future;

  @override
  void initState() {
    super.initState();
    _future = MysqlSchemaFetcher().fetchColumns(
      widget.session.mysqlConnection,
      widget.database,
      widget.table,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return FutureBuilder<List<ColumnInfo>>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(left: 48, top: 4, bottom: 4),
            child: SizedBox(
              height: 12,
              width: 12,
              child: CircularProgressIndicator(strokeWidth: 1),
            ),
          );
        }
        final cols = snap.data ?? [];
        return Column(
          children:
              cols.map((col) {
                return Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: GestureDetector(
                    onSecondaryTapUp: (details) async {
                      final result = await showMenu<String>(
                        context: ctx,
                        position: RelativeRect.fromLTRB(
                          details.globalPosition.dx,
                          details.globalPosition.dy,
                          details.globalPosition.dx,
                          details.globalPosition.dy,
                        ),
                        items: [
                          PopupMenuItem(
                            value: 'copy',
                            child: Text('Copy: ${col.name}'),
                          ),
                        ],
                      );
                      if (result == 'copy') {
                        Clipboard.setData(ClipboardData(text: col.name));
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            col.isPrimaryKey
                                ? Icons.vpn_key_outlined
                                : col.isForeignKey
                                ? Icons.link
                                : col.isUniqueKey
                                ? Icons.fingerprint
                                : Icons.horizontal_rule,
                            size: 12,
                            color:
                                col.isPrimaryKey
                                    ? Colors.amber.shade600
                                    : col.isForeignKey
                                    ? cs.tertiary
                                    : col.isUniqueKey
                                    ? cs.secondary
                                    : cs.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              col.name,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                fontWeight:
                                    col.isPrimaryKey
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                color:
                                    col.isPrimaryKey
                                        ? Colors.amber.shade700
                                        : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Badges
                          if (col.isPrimaryKey)
                            _keyBadge('PK', Colors.amber.shade700),
                          if (col.isForeignKey) _keyBadge('FK', cs.tertiary),
                          if (col.isUniqueKey) _keyBadge('UQ', cs.secondary),
                          const SizedBox(width: 4),
                          Text(
                            col.columnType ?? col.dataType,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              color: cs.onSurface.withValues(alpha: 0.5),
                              fontFamily: 'monospace',
                            ),
                          ),
                          if (!col.isNullable) ...[
                            const SizedBox(width: 3),
                            Icon(
                              Icons.block,
                              size: 9,
                              color: cs.error.withValues(alpha: 0.6),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  Widget _keyBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 3),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color.withAlpha(80), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 7,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
