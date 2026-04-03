import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/query_history_entry.dart';
import '../providers/query_editor_providers.dart';

class QueryHistoryDrawer extends ConsumerWidget {
  final String connectionId;
  final void Function(String sql) onSelectQuery;

  const QueryHistoryDrawer({
    super.key,
    required this.connectionId,
    required this.onSelectQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = ref.watch(queryHistoryDatasourceProvider);

    return Drawer(
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            width: double.infinity,
            child: const Text('Query History',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<QueryHistoryEntry>>(
              future: ds.getRecent(connectionId: connectionId),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final entries = snap.data ?? [];
                if (entries.isEmpty) {
                  return const Center(
                    child: Text('No history yet',
                        style: TextStyle(fontSize: 12)),
                  );
                }
                return ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final e = entries[i];
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        e.hadError
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        size: 16,
                        color: e.hadError
                            ? Colors.red.shade400
                            : Colors.green.shade400,
                      ),
                      title: Text(
                        e.sqlText.replaceAll('\n', ' '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, fontFamily: 'monospace'),
                      ),
                      subtitle: Text(
                        '${e.durationMs}ms · ${_formatDate(e.executedAt)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onTap: () {
                        onSelectQuery(e.sqlText);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
