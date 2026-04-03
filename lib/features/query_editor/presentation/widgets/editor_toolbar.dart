import 'package:flutter/material.dart';

class EditorToolbar extends StatelessWidget {
  final VoidCallback? onRun;
  final VoidCallback? onStop;
  final VoidCallback? onFormat;
  final VoidCallback? onHistory;
  final bool isExecuting;
  final String? activeDatabase;
  final List<String> databases;
  final void Function(String)? onDatabaseChanged;

  const EditorToolbar({
    super.key,
    this.onRun,
    this.onStop,
    this.onFormat,
    this.onHistory,
    this.isExecuting = false,
    this.activeDatabase,
    this.databases = const [],
    this.onDatabaseChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          // Run / Stop
          _ToolbarButton(
            icon:
                isExecuting
                    ? Icons.stop_circle_outlined
                    : Icons.play_circle_filled,
            label: isExecuting ? 'Stop' : 'Run',
            color: isExecuting ? Colors.red.shade400 : Colors.green.shade600,
            tooltip: isExecuting ? 'Stop (Esc)' : 'Execute (F5)',
            onPressed: isExecuting ? onStop : onRun,
          ),
          const _Divider(),
          _ToolbarButton(
            icon: Icons.auto_fix_high_outlined,
            tooltip: 'Format SQL',
            onPressed: onFormat,
          ),
          _ToolbarButton(
            icon: Icons.history_outlined,
            tooltip: 'Query history',
            onPressed: onHistory,
          ),
          // Database selector
          if (databases.isNotEmpty) ...[
            const _Divider(),
            const SizedBox(width: 4),
            Icon(Icons.storage_outlined, size: 13, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: DropdownButton<String>(
                value: activeDatabase,
                hint: Text(
                  'Database',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                isDense: true,
                underline: const SizedBox.shrink(),
                style: theme.textTheme.bodySmall,
                borderRadius: BorderRadius.circular(6),
                items:
                    databases
                        .map(
                          (db) => DropdownMenuItem(
                            value: db,
                            child: Text(
                              db,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (db) {
                  if (db != null) onDatabaseChanged?.call(db);
                },
              ),
            ),
          ] else if (activeDatabase != null) ...[
            const _Divider(),
            const SizedBox(width: 4),
            Icon(Icons.storage_outlined, size: 13, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              activeDatabase!,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
          const Spacer(),
          if (isExecuting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String tooltip;
  final Color? color;
  final VoidCallback? onPressed;

  const _ToolbarButton({
    required this.icon,
    this.label,
    required this.tooltip,
    this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveColor = color ?? cs.onSurfaceVariant;

    if (label != null) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: effectiveColor),
                const SizedBox(width: 4),
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: 12,
                    color: effectiveColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Icon(icon, size: 16, color: effectiveColor),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(height: 20, child: VerticalDivider(width: 1)),
    );
  }
}
