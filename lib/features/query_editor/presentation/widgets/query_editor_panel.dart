import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../workspace/domain/entities/workspace_session.dart';
import '../../../workspace/presentation/providers/workspace_provider.dart';
import '../../domain/entities/query_tab.dart';
import '../providers/query_editor_providers.dart';
import 'code_editor_widget.dart';
import 'editor_toolbar.dart';
import 'query_history_drawer.dart';

class QueryEditorPanel extends ConsumerWidget {
  final QueryTab tab;
  final WorkspaceSession session;

  const QueryEditorPanel({
    super.key,
    required this.tab,
    required this.session,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(queryExecutionProvider(tab.id));
    final isExecuting = executionState is AsyncLoading;

    return CallbackShortcuts(
      bindings: {
        // ── Execute ───────────────────────────────────────────────────────
        // F5 / F9 / Ctrl+Enter  Execute full query
        const SingleActivator(LogicalKeyboardKey.f5): () =>
            _runQuery(ref, tab),
        const SingleActivator(LogicalKeyboardKey.f9): () =>
            _runQuery(ref, tab),
        const SingleActivator(LogicalKeyboardKey.enter,
            control: true): () => _runQuery(ref, tab),

        // ── Format ────────────────────────────────────────────────────────
        // F12 / Ctrl+F12  Format SQL
        const SingleActivator(LogicalKeyboardKey.f12): () =>
            _formatSql(ref, tab.id),
        const SingleActivator(LogicalKeyboardKey.f12,
            control: true): () => _formatSql(ref, tab.id),

        // ── Case conversion ───────────────────────────────────────────────
        // Ctrl+Shift+U  Uppercase selection
        const SingleActivator(LogicalKeyboardKey.keyU,
            control: true, shift: true): () =>
            _transformCase(ref, tab.id, upper: true),
        // Ctrl+Shift+L  Lowercase selection
        const SingleActivator(LogicalKeyboardKey.keyL,
            control: true, shift: true): () =>
            _transformCase(ref, tab.id, upper: false),

        // ── Comment / uncomment ───────────────────────────────────────────
        // Ctrl+Shift+C  Comment selection
        const SingleActivator(LogicalKeyboardKey.keyC,
            control: true, shift: true): () =>
            _toggleComment(ref, tab.id, add: true),
        // Ctrl+Shift+R  Remove comment
        const SingleActivator(LogicalKeyboardKey.keyR,
            control: true, shift: true): () =>
            _toggleComment(ref, tab.id, add: false),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          endDrawer: QueryHistoryDrawer(
            connectionId: session.connection.id,
            onSelectQuery: (sql) =>
                ref.read(editorContentProvider(tab.id).notifier).update(sql),
          ),
          body: Column(
            children: [
              Builder(
                builder: (ctx) => EditorToolbar(
                  isExecuting: isExecuting,
                  activeDatabase: tab.activeDatabase,
                  onRun: () => _runQuery(ref, tab),
                  onStop: () {},
                  onFormat: () => _formatSql(ref, tab.id),
                  onHistory: () => Scaffold.of(ctx).openEndDrawer(),
                  onDatabaseChanged: (db) => ref
                      .read(workspaceProvider.notifier)
                      .updateTabDatabase(session.sessionId, tab.id, db),
                ),
              ),
              // SQLyog-style autocomplete hint bar
              _HintBar(),
              Expanded(
                child: CodeEditorWidget(
                  tabId: tab.id,
                  sessionId: session.sessionId,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _runQuery(WidgetRef ref, QueryTab tab) {
    final sql = ref.read(editorContentProvider(tab.id));
    if (sql.trim().isEmpty) return;
    ref.read(queryExecutionProvider(tab.id).notifier).execute(
          sql: sql,
          sessionId: session.sessionId,
          database: tab.activeDatabase,
        );
  }

  void _formatSql(WidgetRef ref, String tabId) {
    final sql = ref.read(editorContentProvider(tabId));
    const keywords = [
      'SELECT', 'FROM', 'WHERE', 'JOIN', 'LEFT', 'RIGHT', 'INNER',
      'OUTER', 'ON', 'AND', 'OR', 'NOT', 'IN', 'IS', 'NULL',
      'ORDER', 'BY', 'GROUP', 'HAVING', 'LIMIT', 'OFFSET',
      'INSERT', 'INTO', 'VALUES', 'UPDATE', 'SET', 'DELETE',
      'CREATE', 'ALTER', 'DROP', 'TABLE', 'INDEX', 'VIEW',
      'AS', 'DISTINCT', 'COUNT', 'SUM', 'AVG', 'MIN', 'MAX',
    ];
    var formatted = sql;
    for (final kw in keywords) {
      formatted = formatted.replaceAll(
        RegExp(r'\b' + kw + r'\b', caseSensitive: false),
        kw,
      );
    }
    ref.read(editorContentProvider(tabId).notifier).update(formatted);
  }

  void _transformCase(WidgetRef ref, String tabId, {required bool upper}) {
    final sql = ref.read(editorContentProvider(tabId));
    ref.read(editorContentProvider(tabId).notifier)
        .update(upper ? sql.toUpperCase() : sql.toLowerCase());
  }

  void _toggleComment(WidgetRef ref, String tabId, {required bool add}) {
    final sql = ref.read(editorContentProvider(tabId));
    final lines = sql.split('\n');
    final result = lines.map((line) {
      if (add) return '-- $line';
      if (line.startsWith('-- ')) return line.substring(3);
      if (line.startsWith('--')) return line.substring(2);
      return line;
    }).join('\n');
    ref.read(editorContentProvider(tabId).notifier).update(result);
  }
}

// ── Autocomplete hint bar (SQLyog-style) ──────────────────────────────────────

class _HintBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 20,
      color: cs.primaryContainer.withAlpha(80),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _Hint('Tab', 'Next tag'),
          _sep(),
          _Hint('Ctrl+Space', 'List matching tags'),
          _sep(),
          _Hint('Ctrl+Enter', 'List all tags'),
          _sep(),
          _Hint('F9', 'Execute'),
          _sep(),
          _Hint('F12', 'Format'),
          _sep(),
          _Hint('Ctrl+Shift+U/L', 'Case'),
          _sep(),
          _Hint('Ctrl+Shift+C/R', 'Comment'),
        ],
      ),
    );
  }

  Widget _sep() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: Text('·', style: TextStyle(fontSize: 10, color: Colors.grey)),
      );
}

class _Hint extends StatelessWidget {
  final String key_;
  final String label;
  const _Hint(this.key_, this.label);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Text(key_,
              style: TextStyle(
                  fontSize: 9,
                  fontFamily: 'monospace',
                  color: cs.onSurface.withAlpha(180))),
        ),
        const SizedBox(width: 3),
        Text(label,
            style:
                TextStyle(fontSize: 10, color: cs.onSurface.withAlpha(140))),
      ],
    );
  }
}
