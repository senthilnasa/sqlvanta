import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../results_grid/presentation/providers/table_data_tab_signal_provider.dart';
import '../../../workspace/domain/entities/workspace_session.dart';
import 'schema_tree_view.dart';

class ObjectBrowserPanel extends ConsumerStatefulWidget {
  final WorkspaceSession session;
  const ObjectBrowserPanel({super.key, required this.session});

  @override
  ConsumerState<ObjectBrowserPanel> createState() =>
      _ObjectBrowserPanelState();
}

class _ObjectBrowserPanelState extends ConsumerState<ObjectBrowserPanel> {
  final _searchController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          color: theme.colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Filter objects…',
              prefixIcon: const Icon(Icons.search, size: 16),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              suffixIcon: _filter.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 14),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _filter = '');
                      },
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _filter = v.toLowerCase()),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SchemaTreeView(
            session: widget.session,
            filter: _filter,
            onTableDoubleClick: () {
              // Increment signal so ResultsPanel switches to Table Data tab.
              final notifier = ref.read(
                tableDataTabSignalProvider(widget.session.sessionId).notifier,
              );
              notifier.state = notifier.state + 1;
            },
          ),
        ),
      ],
    );
  }
}
