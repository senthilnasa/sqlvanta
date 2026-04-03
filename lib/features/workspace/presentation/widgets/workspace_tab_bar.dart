import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../query_editor/domain/entities/query_tab.dart';
import '../providers/workspace_provider.dart';

IconData _tabIcon(TabType type) => switch (type) {
      TabType.query          => Icons.code,
      TabType.schemaDesigner => Icons.schema_outlined,
      TabType.queryBuilder   => Icons.build_outlined,
      TabType.schemaExplorer => Icons.explore_outlined,
    };

class WorkspaceTabBar extends ConsumerWidget {
  final String sessionId;
  final List<QueryTab> tabs;
  final String? activeTabId;

  const WorkspaceTabBar({
    super.key,
    required this.sessionId,
    required this.tabs,
    this.activeTabId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      height: 36,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (ctx, i) {
                final tab = tabs[i];
                final isActive = tab.id == activeTabId;
                return _TabChip(
                  tab: tab,
                  isActive: isActive,
                  onTap: () => ref
                      .read(workspaceProvider.notifier)
                      .setActiveTab(sessionId, tab.id),
                  onClose: () => ref
                      .read(workspaceProvider.notifier)
                      .closeTab(sessionId, tab.id),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            tooltip: 'New tab (Ctrl+T)',
            onPressed: () =>
                ref.read(workspaceProvider.notifier).addTab(sessionId),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 36),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final QueryTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TabChip({
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 100, maxWidth: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.surface
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isActive
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_tabIcon(tab.type), size: 13),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                tab.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onClose,
              child: Icon(
                Icons.close,
                size: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
