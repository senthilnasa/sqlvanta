import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/empty_state_widget.dart';
import '../../../connections/presentation/widgets/connection_dialog.dart';
import '../providers/workspace_provider.dart';
import '../widgets/server_tab_bar.dart';
import '../widgets/workspace_layout.dart';

/// Top-level IDE shell — SQLyog-style layout:
/// ┌──────────────────────────────────────┐
/// │  Menu bar (File, Query, Tools…)      │
/// ├──────────────────────────────────────┤
/// │  Server tabs  [Prod][Dev][+]         │
/// ├──────────────────────────────────────┤
/// │  WorkspaceLayout for active session  │
/// └──────────────────────────────────────┘
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  bool _autoShowedDialog = false;

  @override
  void initState() {
    super.initState();
    // Show the connection dialog automatically when no sessions are open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _autoShowedDialog) return;
      _autoShowedDialog = true;
      if (ref.read(workspaceProvider).isEmpty) {
        ConnectionDialog.show(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(workspaceProvider);
    final activeId = ref.watch(activeSessionIdProvider);

    final effectiveId = (activeId != null && sessions.containsKey(activeId))
        ? activeId
        : sessions.keys.firstOrNull;

    if (effectiveId != activeId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeSessionIdProvider.notifier).select(effectiveId);
      });
    }

    return CallbackShortcuts(
      bindings: {
        // ── Connection ────────────────────────────────────────────────────
        // Ctrl+M  New connection
        const SingleActivator(LogicalKeyboardKey.keyM, control: true): () =>
            ConnectionDialog.show(context),
        // Ctrl+Shift+C  Connection manager (alias)
        const SingleActivator(LogicalKeyboardKey.keyC,
            control: true, shift: true): () =>
            ConnectionDialog.show(context),
        // Ctrl+F4 / Ctrl+W  Disconnect active
        const SingleActivator(LogicalKeyboardKey.f4, control: true): () async {
          if (effectiveId != null) {
            await ref.read(workspaceProvider.notifier).closeSession(effectiveId);
            final rem = ref.read(workspaceProvider);
            ref.read(activeSessionIdProvider.notifier).select(rem.keys.firstOrNull);
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyW, control: true): () async {
          if (effectiveId != null) {
            await ref.read(workspaceProvider.notifier).closeSession(effectiveId);
            final rem = ref.read(workspaceProvider);
            ref.read(activeSessionIdProvider.notifier).select(rem.keys.firstOrNull);
          }
        },
        // Ctrl+Tab  Next connection
        const SingleActivator(LogicalKeyboardKey.tab, control: true): () {
          final keys = ref.read(workspaceProvider).keys.toList();
          if (keys.length < 2 || effectiveId == null) return;
          final idx = keys.indexOf(effectiveId);
          final next = keys[(idx + 1) % keys.length];
          ref.read(activeSessionIdProvider.notifier).select(next);
        },
        // Ctrl+Shift+Tab  Previous connection
        const SingleActivator(LogicalKeyboardKey.tab,
            control: true, shift: true): () {
          final keys = ref.read(workspaceProvider).keys.toList();
          if (keys.length < 2 || effectiveId == null) return;
          final idx = keys.indexOf(effectiveId);
          final prev = keys[(idx - 1 + keys.length) % keys.length];
          ref.read(activeSessionIdProvider.notifier).select(prev);
        },
        // Ctrl+1..9  Select connection by index
        for (final entry in {
          LogicalKeyboardKey.digit1: 0,
          LogicalKeyboardKey.digit2: 1,
          LogicalKeyboardKey.digit3: 2,
          LogicalKeyboardKey.digit4: 3,
          LogicalKeyboardKey.digit5: 4,
          LogicalKeyboardKey.digit6: 5,
          LogicalKeyboardKey.digit7: 6,
          LogicalKeyboardKey.digit8: 7,
          LogicalKeyboardKey.digit9: -1, // last
        }.entries)
          SingleActivator(entry.key, control: true): () {
            final keys = ref.read(workspaceProvider).keys.toList();
            if (keys.isEmpty) return;
            final idx = entry.value < 0 ? keys.length - 1 : entry.value;
            if (idx < keys.length) {
              ref.read(activeSessionIdProvider.notifier).select(keys[idx]);
            }
          },

        // ── Query tabs ────────────────────────────────────────────────────
        // Ctrl+T  New query tab
        const SingleActivator(LogicalKeyboardKey.keyT, control: true): () {
          if (effectiveId != null) {
            ref.read(workspaceProvider.notifier).addTab(effectiveId);
          }
        },
        // Ctrl+Alt+D  New schema designer tab
        const SingleActivator(LogicalKeyboardKey.keyD,
            control: true, alt: true): () {
          if (effectiveId != null) {
            ref.read(workspaceProvider.notifier)
                .addSchemaDesignerTab(effectiveId);
          }
        },
        // Ctrl+E  New schema explorer tab
        const SingleActivator(LogicalKeyboardKey.keyE, control: true): () {
          if (effectiveId != null) {
            ref.read(workspaceProvider.notifier)
                .addSchemaExplorerTab(effectiveId);
          }
        },
        // Ctrl+K  New query builder tab
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
          if (effectiveId != null) {
            ref.read(workspaceProvider.notifier)
                .addQueryBuilderTab(effectiveId);
          }
        },
        // Ctrl+PgUp  Previous tab
        const SingleActivator(LogicalKeyboardKey.pageUp, control: true): () {
          if (effectiveId == null) return;
          final session = ref.read(workspaceProvider)[effectiveId];
          if (session == null || session.tabs.length < 2) return;
          final idx = session.tabs.indexWhere((t) => t.id == session.activeTabId);
          final prev = (idx - 1 + session.tabs.length) % session.tabs.length;
          ref.read(workspaceProvider.notifier)
              .setActiveTab(effectiveId, session.tabs[prev].id);
        },
        // Ctrl+PgDn  Next tab
        const SingleActivator(LogicalKeyboardKey.pageDown, control: true): () {
          if (effectiveId == null) return;
          final session = ref.read(workspaceProvider)[effectiveId];
          if (session == null || session.tabs.length < 2) return;
          final idx = session.tabs.indexWhere((t) => t.id == session.activeTabId);
          final next = (idx + 1) % session.tabs.length;
          ref.read(workspaceProvider.notifier)
              .setActiveTab(effectiveId, session.tabs[next].id);
        },
        // Alt+L  Close active tab
        const SingleActivator(LogicalKeyboardKey.keyL, alt: true): () {
          if (effectiveId == null) return;
          final session = ref.read(workspaceProvider)[effectiveId];
          if (session?.activeTabId != null) {
            ref.read(workspaceProvider.notifier)
                .closeTab(effectiveId, session!.activeTabId!);
          }
        },

        // ── Settings / other ──────────────────────────────────────────────
        // Ctrl+, Preferences
        const SingleActivator(LogicalKeyboardKey.comma, control: true): () =>
            context.push('/settings'),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Column(
            children: [
              _MenuBar(activeSessionId: effectiveId),
              ServerTabBar(
                sessions: sessions,
                activeSessionId: effectiveId,
                onSelect: (id) =>
                    ref.read(activeSessionIdProvider.notifier).select(id),
                onClose: (id) async {
                  await ref.read(workspaceProvider.notifier).closeSession(id);
                  final remaining = ref.read(workspaceProvider);
                  ref
                      .read(activeSessionIdProvider.notifier)
                      .select(remaining.keys.firstOrNull);
                },
                onAdd: () => ConnectionDialog.show(context),
              ),
              const Divider(height: 1),
              Expanded(
                child: effectiveId != null && sessions.containsKey(effectiveId)
                    ? WorkspaceLayout(session: sessions[effectiveId]!)
                    : EmptyStateWidget(
                        icon: Icons.storage_outlined,
                        title: 'No active connection',
                        subtitle: 'Connect to a MySQL server to get started',
                        action: FilledButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Connect…'),
                          onPressed: () => ConnectionDialog.show(context),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Menu bar ──────────────────────────────────────────────────────────────────

class _MenuBar extends ConsumerWidget {
  final String? activeSessionId;
  const _MenuBar({this.activeSessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sessionCount = ref.watch(workspaceProvider).length;

    return Container(
      height: 30,
      color: cs.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'SQLvanta',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: cs.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const VerticalDivider(width: 1, indent: 4, endIndent: 4),
          _MenuButton(
            label: 'File',
            items: [
              _MenuItem(
                icon: Icons.add_circle_outline,
                label: 'New Connection…',
                shortcut: 'Ctrl+Shift+C',
                onTap: () => ConnectionDialog.show(context),
              ),
              _MenuItem(
                icon: Icons.close,
                label: 'Close Active Connection',
                onTap: activeSessionId == null
                    ? null
                    : () async {
                        await ref
                            .read(workspaceProvider.notifier)
                            .closeSession(activeSessionId!);
                        final remaining = ref.read(workspaceProvider);
                        ref
                            .read(activeSessionIdProvider.notifier)
                            .select(remaining.keys.firstOrNull);
                      },
              ),
            ],
          ),
          _MenuButton(
            label: 'Query',
            items: [
              _MenuItem(
                icon: Icons.play_arrow,
                label: 'Execute',
                shortcut: 'F5',
                onTap: null,
              ),
              _MenuItem(
                icon: Icons.code,
                label: 'New Query Editor',
                shortcut: 'Ctrl+T',
                onTap: activeSessionId == null
                    ? null
                    : () => ref
                        .read(workspaceProvider.notifier)
                        .addTab(activeSessionId!),
              ),
              _MenuItem(
                icon: Icons.build_outlined,
                label: 'New Query Builder',
                shortcut: 'Ctrl+K',
                onTap: activeSessionId == null
                    ? null
                    : () => ref
                        .read(workspaceProvider.notifier)
                        .addQueryBuilderTab(activeSessionId!),
              ),
              _MenuItem(
                icon: Icons.schema_outlined,
                label: 'New Schema Designer',
                shortcut: 'Ctrl+Alt+D',
                onTap: activeSessionId == null
                    ? null
                    : () => ref
                        .read(workspaceProvider.notifier)
                        .addSchemaDesignerTab(activeSessionId!),
              ),
              _MenuItem(
                icon: Icons.explore_outlined,
                label: 'New Schema Explorer',
                shortcut: 'Ctrl+E',
                onTap: activeSessionId == null
                    ? null
                    : () => ref
                        .read(workspaceProvider.notifier)
                        .addSchemaExplorerTab(activeSessionId!),
              ),
            ],
          ),
          _MenuButton(
            label: 'Tools',
            items: [
              _MenuItem(
                icon: Icons.compare_arrows,
                label: 'Copy Database…',
                onTap: activeSessionId == null
                    ? null
                    : () => _showDbCopyDialog(context, ref, activeSessionId!),
              ),
              _MenuItem(
                icon: Icons.settings_outlined,
                label: 'Preferences…',
                shortcut: 'Ctrl+,',
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
          const Spacer(),
          if (sessionCount > 0)
            _ConnectionsBadge(count: sessionCount),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  void _showDbCopyDialog(
      BuildContext context, WidgetRef ref, String sessionId) {
    showDialog<void>(
      context: context,
      builder: (_) => DbCopyDialog(sourceSessionId: sessionId),
    );
  }
}

// ── Menu components ───────────────────────────────────────────────────────────

class _MenuButton extends StatelessWidget {
  final String label;
  final List<_MenuItem> items;
  const _MenuButton({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MenuItem>(
      tooltip: '',
      offset: const Offset(0, 26),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
      itemBuilder: (_) => items.map((item) {
        return PopupMenuItem<_MenuItem>(
          value: item,
          enabled: item.onTap != null,
          height: 36,
          child: Row(
            children: [
              Icon(item.icon, size: 15),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(item.label, style: const TextStyle(fontSize: 12))),
              if (item.shortcut != null) ...[
                const SizedBox(width: 16),
                Text(
                  item.shortcut!,
                  style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(100)),
                ),
              ],
            ],
          ),
        );
      }).toList(),
      onSelected: (item) => item.onTap?.call(),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String? shortcut;
  final VoidCallback? onTap;
  const _MenuItem(
      {required this.icon, required this.label, this.shortcut, this.onTap});
}

class _ConnectionsBadge extends StatelessWidget {
  final int count;
  const _ConnectionsBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 7, color: Colors.green),
          const SizedBox(width: 4),
          Text(
            '$count connected',
            style: TextStyle(fontSize: 10, color: cs.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

// ── DB Copy Dialog ────────────────────────────────────────────────────────────

class DbCopyDialog extends ConsumerStatefulWidget {
  final String sourceSessionId;
  const DbCopyDialog({super.key, required this.sourceSessionId});

  @override
  ConsumerState<DbCopyDialog> createState() => _DbCopyDialogState();
}

class _DbCopyDialogState extends ConsumerState<DbCopyDialog> {
  String? _sourceDb;
  String? _targetSessionId;
  String? _targetDb;
  bool _copying = false;
  String? _status;

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(workspaceProvider);
    final otherSessions = sessions.entries
        .where((e) => e.key != widget.sourceSessionId)
        .toList();

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.compare_arrows, size: 20),
          SizedBox(width: 8),
          Text('Copy Database', style: TextStyle(fontSize: 15)),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Source',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: Text(
                  sessions[widget.sourceSessionId]?.connection.name ?? '—',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DatabaseDropdown(
                  sessionId: widget.sourceSessionId,
                  value: _sourceDb,
                  hint: 'Select database',
                  onChanged: (v) => setState(() => _sourceDb = v),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            const Text('Target',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 6),
            if (otherSessions.isEmpty)
              const Text('Open another connection to copy to.',
                  style: TextStyle(fontSize: 12, color: Colors.orange))
            else
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _targetSessionId,
                    hint: const Text('Target server',
                        style: TextStyle(fontSize: 12)),
                    decoration: const InputDecoration(
                        isDense: true, border: OutlineInputBorder()),
                    items: otherSessions
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value.connection.name,
                                  style: const TextStyle(fontSize: 12)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _targetSessionId = v;
                      _targetDb = null;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _targetSessionId == null
                      ? const SizedBox.shrink()
                      : _DatabaseDropdown(
                          sessionId: _targetSessionId!,
                          value: _targetDb,
                          hint: 'Target DB',
                          onChanged: (v) => setState(() => _targetDb = v),
                        ),
                ),
              ]),
            if (_status != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _status!.startsWith('✓')
                      ? Colors.green.withAlpha(20)
                      : Colors.red.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_status!, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton.icon(
          icon: _copying
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.copy, size: 16),
          label: const Text('Copy'),
          onPressed: (_copying || _sourceDb == null || _targetSessionId == null)
              ? null
              : _startCopy,
        ),
      ],
    );
  }

  Future<void> _startCopy() async {
    setState(() {
      _copying = true;
      _status = null;
    });
    try {
      final sessions = ref.read(workspaceProvider);
      final src = sessions[widget.sourceSessionId]!;
      final tgt = sessions[_targetSessionId!]!;
      final targetDb = _targetDb ?? _sourceDb!;

      final tables = await src.mysqlConnection.execute(
        'SELECT TABLE_NAME FROM information_schema.TABLES '
        'WHERE TABLE_SCHEMA = :db AND TABLE_TYPE = \'BASE TABLE\' '
        'ORDER BY TABLE_NAME',
        {'db': _sourceDb},
      );
      final tableNames = tables.rows
          .map((r) => r.colByName('TABLE_NAME') ?? '')
          .where((n) => n.isNotEmpty)
          .toList();

      await tgt.mysqlConnection
          .execute('CREATE DATABASE IF NOT EXISTS `$targetDb`');

      int copied = 0;
      for (final table in tableNames) {
        final ddlRes = await src.mysqlConnection
            .execute('SHOW CREATE TABLE `$_sourceDb`.`$table`');
        var ddl = ddlRes.rows.first.colByName('Create Table') ?? '';
        ddl = ddl.replaceFirst(
            RegExp(r'CREATE TABLE'), 'CREATE TABLE IF NOT EXISTS');
        await tgt.mysqlConnection.execute('USE `$targetDb`');
        await tgt.mysqlConnection.execute(ddl);

        final rows = await src.mysqlConnection
            .execute('SELECT * FROM `$_sourceDb`.`$table`');
        final colNames = rows.cols.map((c) => c.name).toList();
        for (final row in rows.rows) {
          final values = colNames.map((col) {
            final v = row.colByName(col);
            if (v == null) return 'NULL';
            return "'${v.replaceAll("'", "''")}'";
          }).join(', ');
          if (values.isNotEmpty) {
            await tgt.mysqlConnection.execute(
                'INSERT IGNORE INTO `$targetDb`.`$table` VALUES ($values)');
          }
        }
        copied++;
      }
      setState(() => _status = '✓ Copied $copied tables to `$targetDb`');
    } catch (e) {
      setState(() => _status = '✗ Error: $e');
    } finally {
      setState(() => _copying = false);
    }
  }
}

class _DatabaseDropdown extends ConsumerWidget {
  final String sessionId;
  final String? value;
  final String hint;
  final void Function(String?) onChanged;

  const _DatabaseDropdown({
    required this.sessionId,
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(workspaceProvider)[sessionId];
    if (session == null) return const SizedBox.shrink();

    return FutureBuilder<List<String>>(
      future: session.mysqlConnection
          .execute(
              'SELECT SCHEMA_NAME FROM information_schema.SCHEMATA ORDER BY SCHEMA_NAME')
          .then((r) => r.rows
              .map((row) => row.colByName('SCHEMA_NAME') ?? '')
              .where((n) => n.isNotEmpty)
              .toList()),
      builder: (ctx, snap) {
        final dbs = snap.data ?? [];
        return DropdownButtonFormField<String>(
          initialValue: dbs.contains(value) ? value : null,
          hint: Text(hint, style: const TextStyle(fontSize: 12)),
          decoration: const InputDecoration(
              isDense: true, border: OutlineInputBorder()),
          items: dbs
              .map((db) => DropdownMenuItem(
                    value: db,
                    child: Text(db, style: const TextStyle(fontSize: 12)),
                  ))
              .toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}
