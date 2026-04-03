import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_split_view.dart';
import '../../../../core/widgets/app_status_bar.dart';
import '../../../object_browser/presentation/widgets/object_browser_panel.dart';
import '../../../query_builder/presentation/widgets/query_builder_panel.dart';
import '../../../query_editor/domain/entities/query_tab.dart';
import '../../../query_editor/presentation/widgets/query_editor_panel.dart';
import '../../../results_grid/presentation/widgets/results_panel.dart';
import '../../../schema_designer/presentation/widgets/schema_designer_panel.dart';
import '../../../schema_explorer/presentation/widgets/schema_explorer_panel.dart';
import '../../domain/entities/workspace_session.dart';
import '../widgets/workspace_tab_bar.dart';

/// The per-session IDE layout:
///   [Query Tabs]
///   [Object Browser | main content (varies by tab type)]
///   [Status Bar]
class WorkspaceLayout extends ConsumerWidget {
  final WorkspaceSession session;

  const WorkspaceLayout({super.key, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab =
        session.tabs.where((t) => t.id == session.activeTabId).firstOrNull;

    return Column(
      children: [
        WorkspaceTabBar(
          sessionId: session.sessionId,
          tabs: session.tabs,
          activeTabId: session.activeTabId,
        ),
        const Divider(height: 1),
        Expanded(
          child: AppSplitView(
            initialRatio: 0.22,
            minRatio: 0.12,
            maxRatio: 0.45,
            leading: ObjectBrowserPanel(session: session),
            trailing: _buildMainContent(activeTab),
          ),
        ),
        AppStatusBar(connectionName: session.connection.name),
      ],
    );
  }

  Widget _buildMainContent(QueryTab? activeTab) {
    if (activeTab == null) {
      return const Center(
        child: Text(
          'No tab — press Ctrl+T to add one',
          style: TextStyle(fontSize: 13),
        ),
      );
    }

    return switch (activeTab.type) {
      TabType.schemaDesigner => SchemaDesignerPanel(session: session),
      TabType.schemaExplorer => SchemaExplorerPanel(session: session),
      TabType.queryBuilder => QueryBuilderPanel(
        session: session,
        tabId: activeTab.id,
      ),
      TabType.query => AppSplitView(
        axis: Axis.vertical,
        initialRatio: 0.55,
        minRatio: 0.20,
        maxRatio: 0.85,
        leading: QueryEditorPanel(tab: activeTab, session: session),
        trailing: ResultsPanel(
          tabId: activeTab.id,
          sessionId: session.sessionId,
        ),
      ),
    };
  }
}
