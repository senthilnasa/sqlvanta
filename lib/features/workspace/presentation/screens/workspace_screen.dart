import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/empty_state_widget.dart';
import '../providers/workspace_provider.dart';
import '../widgets/workspace_layout.dart';
import '../widgets/workspace_tab_bar.dart';

class WorkspaceScreen extends ConsumerWidget {
  final String sessionId;
  const WorkspaceScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(workspaceProvider)[sessionId];

    if (session == null) {
      return Scaffold(
        body: EmptyStateWidget(
          icon: Icons.storage_outlined,
          title: 'Session not found',
          subtitle: 'The connection session may have been closed.',
          action: FilledButton(
            onPressed: () => context.go('/connections'),
            child: const Text('Back to Connections'),
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 36,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const Icon(Icons.storage, size: 14),
                const SizedBox(width: 6),
                Text(
                  session.connection.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                if (session.connection.host.isNotEmpty) ...[
                  Text(
                    ' — ${session.connection.username}@'
                    '${session.connection.host}:${session.connection.port}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 16),
                  tooltip: 'Settings',
                  onPressed: () => context.push('/settings'),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  tooltip: 'Close connection',
                  onPressed: () async {
                    await ref
                        .read(workspaceProvider.notifier)
                        .closeSession(sessionId);
                    if (context.mounted) context.go('/connections');
                  },
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ],
            ),
          ),
          WorkspaceTabBar(
            sessionId: sessionId,
            tabs: session.tabs,
            activeTabId: session.activeTabId,
          ),
          Expanded(child: WorkspaceLayout(session: session)),
        ],
      ),
    );
  }
}
