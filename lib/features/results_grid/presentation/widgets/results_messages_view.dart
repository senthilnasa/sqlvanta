import 'package:flutter/material.dart';

import '../../../../mysql/mysql_query_executor.dart';

class ResultsMessagesView extends StatelessWidget {
  final QueryResult? result;

  const ResultsMessagesView({super.key, this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (result == null) {
      return const Center(
        child: Text('Run a query to see messages.',
            style: TextStyle(fontSize: 12)),
      );
    }

    final r = result!;
    final color = r.isError ? Colors.red.shade400 : Colors.green.shade400;
    final icon = r.isError ? Icons.error_outline : Icons.check_circle_outline;
    final message = r.isError
        ? r.errorMessage ?? 'Unknown error'
        : r.hasData
            ? '${r.rowCount} row(s) returned in ${r.duration.inMilliseconds}ms'
            : '${r.affectedRows ?? 0} row(s) affected in ${r.duration.inMilliseconds}ms';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
