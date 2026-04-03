import 'package:flutter/material.dart';

import '../../domain/entities/workspace_session.dart';

/// SQLyog-style horizontal tab strip showing one tab per open server connection.
class ServerTabBar extends StatelessWidget {
  final Map<String, WorkspaceSession> sessions;
  final String? activeSessionId;
  final void Function(String id) onSelect;
  final void Function(String id) onClose;
  final VoidCallback onAdd;

  const ServerTabBar({
    super.key,
    required this.sessions,
    required this.activeSessionId,
    required this.onSelect,
    required this.onClose,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      height: 38,
      color: cs.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: sessions.entries.map((entry) {
                final isActive = entry.key == activeSessionId;
                return _ServerTab(
                  session: entry.value,
                  isActive: isActive,
                  onTap: () => onSelect(entry.key),
                  onClose: () => onClose(entry.key),
                );
              }).toList(),
            ),
          ),
          // Add connection button
          Tooltip(
            message: 'Open connection (Ctrl+Shift+C)',
            child: InkWell(
              onTap: onAdd,
              child: Container(
                width: 36,
                alignment: Alignment.center,
                child: Icon(Icons.add, size: 18, color: cs.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerTab extends StatelessWidget {
  final WorkspaceSession session;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _ServerTab({
    required this.session,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? cs.surface : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isActive ? cs.primary : Colors.transparent,
              width: 2,
            ),
            right: BorderSide(color: cs.outlineVariant.withAlpha(60)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storage_outlined,
              size: 14,
              color: isActive ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.connection.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive ? cs.onSurface : cs.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${session.connection.username}@${session.connection.host}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: cs.onSurfaceVariant.withAlpha(160),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onClose,
              child: Icon(
                Icons.close,
                size: 13,
                color: cs.onSurface.withAlpha(100),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
