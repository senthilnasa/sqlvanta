import 'package:flutter/material.dart';

import '../../domain/entities/connection_entity.dart';

class ConnectionListTile extends StatelessWidget {
  final ConnectionEntity connection;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ConnectionListTile({
    super.key,
    required this.connection,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = connection.colorTag != null
        ? Color(int.parse(connection.colorTag!.replaceFirst('#', '0xFF')))
        : theme.colorScheme.primary;

    return ListTile(
      selected: isSelected,
      selectedTileColor:
          theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: color.withValues(alpha: 0.2),
        child: Icon(Icons.storage, size: 16, color: color),
      ),
      title: Text(
        connection.name,
        style: theme.textTheme.bodyMedium
            ?.copyWith(fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${connection.username}@${connection.host}:${connection.port}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 18),
        tooltip: 'Delete connection',
        onPressed: onDelete,
      ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    );
  }
}
