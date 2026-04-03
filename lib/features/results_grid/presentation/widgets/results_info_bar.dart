import 'package:flutter/material.dart';

import '../../../../mysql/mysql_query_executor.dart';

class ResultsInfoBar extends StatelessWidget {
  final QueryResult? result;

  const ResultsInfoBar({super.key, this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
    );

    if (result == null) return const SizedBox(height: 24);

    final r = result!;
    final String message;
    if (r.isError) {
      message = 'Error — ${r.duration.inMilliseconds}ms';
    } else if (r.hasData) {
      final cap = r.rowCount >= 1000 ? ' (capped)' : '';
      message =
          '${r.rowCount} row${r.rowCount == 1 ? '' : 's'}$cap — ${r.duration.inMilliseconds}ms';
    } else {
      final affected = r.affectedRows ?? 0;
      message =
          '$affected row${affected == 1 ? '' : 's'} affected — ${r.duration.inMilliseconds}ms';
    }

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.centerLeft,
      child: Text(message, style: style),
    );
  }
}
