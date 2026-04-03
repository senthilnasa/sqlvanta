import 'package:flutter/material.dart';

enum TreeNodeType {
  database,
  category,
  table,
  view,
  storedProc,
  function,
  trigger,
  event,
}

class TreeNodeTile extends StatelessWidget {
  final String label;
  final TreeNodeType type;
  final String? subtitle;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final List<PopupMenuEntry<String>> contextMenuItems;
  final void Function(String)? onContextMenuSelected;

  const TreeNodeTile({
    super.key,
    required this.label,
    required this.type,
    this.subtitle,
    this.isExpanded = false,
    required this.onTap,
    this.onDoubleTap,
    this.contextMenuItems = const [],
    this.onContextMenuSelected,
  });

  bool get _hasChevron =>
      type == TreeNodeType.database || type == TreeNodeType.category;

  IconData get _icon => switch (type) {
    TreeNodeType.database => Icons.storage_outlined,
    TreeNodeType.category => Icons.folder_outlined,
    TreeNodeType.table => Icons.table_rows_outlined,
    TreeNodeType.view => Icons.remove_red_eye_outlined,
    TreeNodeType.storedProc => Icons.settings_suggest_outlined,
    TreeNodeType.function => Icons.functions,
    TreeNodeType.trigger => Icons.bolt_outlined,
    TreeNodeType.event => Icons.event_outlined,
  };

  Color _iconColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return switch (type) {
      TreeNodeType.database => cs.primary,
      TreeNodeType.category => cs.onSurface.withValues(alpha: 0.5),
      TreeNodeType.table => cs.secondary,
      TreeNodeType.view => cs.tertiary,
      TreeNodeType.storedProc => Colors.purple.shade400,
      TreeNodeType.function => Colors.orange.shade600,
      TreeNodeType.trigger => Colors.amber.shade700,
      TreeNodeType.event => Colors.teal.shade400,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tile = InkWell(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          children: [
            if (_hasChevron)
              Icon(
                isExpanded ? Icons.expand_more : Icons.chevron_right,
                size: 16,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
              )
            else
              const SizedBox(width: 16),
            const SizedBox(width: 2),
            Icon(_icon, size: 15, color: _iconColor(context)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight:
                      type == TreeNodeType.database
                          ? FontWeight.w600
                          : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );

    if (contextMenuItems.isEmpty) return tile;

    return GestureDetector(
      onSecondaryTapUp: (details) async {
        final result = await showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx,
            details.globalPosition.dy,
          ),
          items: contextMenuItems,
        );
        if (result != null) onContextMenuSelected?.call(result);
      },
      child: tile,
    );
  }
}
