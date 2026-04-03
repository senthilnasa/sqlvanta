import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/query_editor/domain/entities/query_history_entry.dart';
import '../../../../features/query_editor/presentation/providers/query_editor_providers.dart';
import '../../../../features/workspace/domain/entities/workspace_session.dart';
import '../../../../features/workspace/presentation/providers/workspace_provider.dart';
import '../providers/results_provider.dart';
import '../providers/table_data_tab_signal_provider.dart';
import 'results_data_grid.dart';
import 'results_info_tab.dart';
import 'results_messages_view.dart';
import 'results_table_data_tab.dart';

/// SQLyog-style results panel with numbered tabs:
///   1 Result  |  2 Messages  |  3 Table Data  |  4 Info  |  5 History
class ResultsPanel extends ConsumerWidget {
  final String tabId;
  final String sessionId;

  const ResultsPanel({
    super.key,
    required this.tabId,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(tabResultsProvider(tabId));
    final session = ref.watch(workspaceProvider)[sessionId];

    return resultAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (result) => _TabShell(
        result: result,
        tabId: tabId,
        sessionId: sessionId,
        session: session,
        sourceSql: ref.read(editorContentProvider(tabId)),
      ),
    );
  }
}

// ── Tab shell ────────────────────────────────────────────────────────────────

class _TabShell extends ConsumerStatefulWidget {
  final dynamic result;   // QueryResult?
  final String tabId;
  final String sessionId;
  final WorkspaceSession? session;
  final String sourceSql;

  const _TabShell({
    required this.result,
    required this.tabId,
    required this.sessionId,
    required this.session,
    required this.sourceSql,
  });

  @override
  ConsumerState<_TabShell> createState() => _TabShellState();
}

class _TabShellState extends ConsumerState<_TabShell>
    with SingleTickerProviderStateMixin {
  late final TabController _tc;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Switch to Table Data tab (index 2) when the object browser signals.
    ref.listen(tableDataTabSignalProvider(widget.sessionId), (prev, next) {
      if (_tc.index != 2) _tc.animateTo(2);
    });

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final result = widget.result;

    // ── SQLyog-style numbered tab bar ─────────────────────────────────────
    return Column(
      children: [
        // Tab bar
        Container(
          color: cs.surfaceContainerHighest,
          child: TabBar(
            controller: _tc,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            indicatorWeight: 2,
            labelPadding:
                const EdgeInsets.symmetric(horizontal: 4),
            tabs: [
              _SqlyogTab(
                n: 1,
                icon: Icons.grid_on_outlined,
                label: 'Result',
                hasData: result != null && result.hasData,
              ),
              _SqlyogTab(
                n: 2,
                icon: Icons.info_outline,
                label: 'Messages',
              ),
              _SqlyogTab(
                n: 3,
                icon: Icons.table_chart_outlined,
                label: 'Table Data',
              ),
              _SqlyogTab(
                n: 4,
                icon: Icons.query_stats,
                label: 'Info',
                hasData: result != null,
              ),
              _SqlyogTab(
                n: 5,
                icon: Icons.history_outlined,
                label: 'History',
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tc,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // ── 1 Result ─────────────────────────────────────────────────
              result != null && result.hasData
                  ? ResultsDataGrid(
                      result: result,
                      tabId: widget.tabId,
                      sessionId: widget.sessionId,
                    )
                  : _EmptyTab(
                      icon: Icons.grid_on_outlined,
                      message: result?.isError == true
                          ? 'Query returned an error — see Messages tab'
                          : 'Run a query to see results',
                    ),

              // ── 2 Messages ───────────────────────────────────────────────
              ResultsMessagesView(result: result),

              // ── 3 Table Data ──────────────────────────────────────────────
              widget.session != null
                  ? ResultsTableDataTab(session: widget.session!)
                  : const _EmptyTab(
                      icon: Icons.table_chart_outlined,
                      message: 'No active session'),

              // ── 4 Info ───────────────────────────────────────────────────
              ResultsInfoTab(
                result: result,
                sourceSql: widget.sourceSql.trim().isEmpty
                    ? null
                    : widget.sourceSql,
                session: widget.session,
              ),

              // ── 5 History ─────────────────────────────────────────────────
              _HistoryTab(
                sessionId: widget.sessionId,
                tabId: widget.tabId,
              ),
            ],
          ),
        ),

        // ── Status bar strip (like SQLyog bottom strip) ───────────────────
        _ResultsStatusBar(result: result),
      ],
    );
  }
}

// ── SQLyog-style tab label ────────────────────────────────────────────────────

class _SqlyogTab extends StatelessWidget {
  final int n;
  final IconData icon;
  final String label;
  final bool hasData;

  const _SqlyogTab({
    required this.n,
    required this.icon,
    required this.label,
    this.hasData = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tab(
      height: 30,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13),
          const SizedBox(width: 5),
          Text(
            '$n $label',
            style: const TextStyle(fontSize: 12),
          ),
          if (hasData) ...[
            const SizedBox(width: 4),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Status bar at bottom ──────────────────────────────────────────────────────

class _ResultsStatusBar extends StatelessWidget {
  final dynamic result; // QueryResult?

  const _ResultsStatusBar({this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final style = TextStyle(
      fontSize: 11,
      color: cs.onSurface.withAlpha(160),
    );

    if (result == null) {
      return Container(
        height: 22,
        color: cs.surfaceContainerHighest,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerLeft,
        child: Text('Ready', style: style),
      );
    }

    final r = result!;
    final bool isError = r.isError as bool;
    final int ms = r.duration.inMilliseconds as int;
    final String msg;

    if (isError) {
      msg = 'Error  ·  ${ms}ms';
    } else if (r.hasData as bool) {
      final rows = r.rowCount as int;
      final cap = rows >= 1000 ? '  (limit)' : '';
      msg = '$rows row${rows == 1 ? '' : 's'}$cap  ·  ${ms}ms';
    } else {
      final aff = (r.affectedRows as int?) ?? 0;
      msg = '$aff row${aff == 1 ? '' : 's'} affected  ·  ${ms}ms';
    }

    return Container(
      height: 22,
      color: cs.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 12,
            color: isError ? cs.error : Colors.green.shade500,
          ),
          const SizedBox(width: 6),
          Text(msg, style: style),
          const Spacer(),
          Text('Ln 1, Col 1', style: style),
          const SizedBox(width: 8),
          Text('Connections: 1', style: style),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ── Empty placeholder ─────────────────────────────────────────────────────────

class _EmptyTab extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyTab({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: cs.onSurface.withAlpha(40)),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
                fontSize: 12, color: cs.onSurface.withAlpha(120)),
          ),
        ],
      ),
    );
  }
}

// ── History tab ───────────────────────────────────────────────────────────────

class _HistoryTab extends ConsumerStatefulWidget {
  final String sessionId;
  final String tabId;
  const _HistoryTab({required this.sessionId, required this.tabId});

  @override
  ConsumerState<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<_HistoryTab> {
  late Future<List<QueryHistoryEntry>> _future;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final session = ref.read(workspaceProvider)[widget.sessionId];
    if (session == null) {
      _future = Future.value([]);
      return;
    }
    final ds = ref.read(queryHistoryDatasourceProvider);
    _future = ds.getRecent(connectionId: session.connection.id);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          height: 32,
          color: cs.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Text('Query History',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface)),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 13),
                label: const Text('Refresh', style: TextStyle(fontSize: 11)),
                onPressed: () => setState(_loadHistory),
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
        const Divider(height: 1),
        Expanded(
          child: FutureBuilder<List<QueryHistoryEntry>>(
            future: _future,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final entries = snap.data ?? [];
              if (entries.isEmpty) {
                return _EmptyTab(
                    icon: Icons.history_outlined,
                    message: 'No history yet');
              }
              return ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (context, i) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final e = entries[i];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      e.hadError
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      size: 15,
                      color: e.hadError
                          ? Colors.red.shade400
                          : Colors.green.shade500,
                    ),
                    title: Text(
                      e.sqlText.replaceAll('\n', ' '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, fontFamily: 'monospace'),
                    ),
                    subtitle: Text(
                      '${e.durationMs}ms · ${_fmt(e.executedAt)}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    trailing: e.isFavorite
                        ? Icon(Icons.star,
                            size: 13, color: Colors.amber.shade400)
                        : null,
                    onTap: () => ref
                        .read(editorContentProvider(widget.tabId).notifier)
                        .update(e.sqlText),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.month}/${dt.day} '
      '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
}
