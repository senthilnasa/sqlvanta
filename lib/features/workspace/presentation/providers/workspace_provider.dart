import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../connections/domain/entities/connection_entity.dart';
import '../../../connections/presentation/providers/connection_providers.dart';
import '../../../query_editor/domain/entities/query_tab.dart';
import '../../domain/entities/workspace_session.dart';

part 'workspace_provider.g.dart';

/// Tracks which server tab is currently active in the IDE shell.
@riverpod
class ActiveSessionId extends _$ActiveSessionId {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

@riverpod
class Workspace extends _$Workspace {
  @override
  Map<String, WorkspaceSession> build() => {};

  Future<WorkspaceSession> openConnection(
    ConnectionEntity connection,
    String password,
  ) async {
    // Use connection ID as session key — one session per connection in Phase 1
    final sessionId = connection.id;

    // Reuse existing session for the same connection
    if (state.containsKey(sessionId)) return state[sessionId]!;

    final factory = ref.read(mysqlClientFactoryProvider);
    final conn = await factory.create(connection, password);
    await conn.connect();

    final firstTab = QueryTab(
      id: const Uuid().v4(),
      title: 'Query 1',
      sessionId: sessionId,
      activeDatabase: connection.defaultDatabase,
    );

    final session = WorkspaceSession(
      sessionId: sessionId,
      connection: connection,
      mysqlConnection: conn,
      tabs: [firstTab],
      activeTabId: firstTab.id,
    );

    state = {...state, sessionId: session};
    return session;
  }

  Future<void> closeSession(String sessionId) async {
    final session = state[sessionId];
    if (session != null) {
      await session.mysqlConnection.close();
    }
    final updated = Map<String, WorkspaceSession>.from(state);
    updated.remove(sessionId);
    state = updated;
  }

  void addTab(String sessionId) {
    final session = state[sessionId];
    if (session == null) return;
    final queryCount =
        session.tabs.where((t) => t.type == TabType.query).length + 1;
    final tab = QueryTab(
      id: const Uuid().v4(),
      title: 'Query $queryCount',
      sessionId: sessionId,
      activeDatabase: session.connection.defaultDatabase,
    );
    state = {
      ...state,
      sessionId: session.copyWith(
        tabs: [...session.tabs, tab],
        activeTabId: tab.id,
      ),
    };
  }

  void addSchemaDesignerTab(String sessionId) {
    final session = state[sessionId];
    if (session == null) return;
    final tab = QueryTab(
      id: const Uuid().v4(),
      title: 'Schema Designer',
      sessionId: sessionId,
      activeDatabase: session.connection.defaultDatabase,
      type: TabType.schemaDesigner,
    );
    state = {
      ...state,
      sessionId: session.copyWith(
        tabs: [...session.tabs, tab],
        activeTabId: tab.id,
      ),
    };
  }

  void addQueryBuilderTab(String sessionId) {
    final session = state[sessionId];
    if (session == null) return;
    final tab = QueryTab(
      id: const Uuid().v4(),
      title: 'Query Builder',
      sessionId: sessionId,
      activeDatabase: session.connection.defaultDatabase,
      type: TabType.queryBuilder,
    );
    state = {
      ...state,
      sessionId: session.copyWith(
        tabs: [...session.tabs, tab],
        activeTabId: tab.id,
      ),
    };
  }

  void addSchemaExplorerTab(String sessionId) {
    final session = state[sessionId];
    if (session == null) return;
    final tab = QueryTab(
      id: const Uuid().v4(),
      title: 'Schema Explorer',
      sessionId: sessionId,
      activeDatabase: session.connection.defaultDatabase,
      type: TabType.schemaExplorer,
    );
    state = {
      ...state,
      sessionId: session.copyWith(
        tabs: [...session.tabs, tab],
        activeTabId: tab.id,
      ),
    };
  }

  void closeTab(String sessionId, String tabId) {
    final session = state[sessionId];
    if (session == null) return;
    final remaining = session.tabs.where((t) => t.id != tabId).toList();
    if (remaining.isEmpty) {
      closeSession(sessionId);
      return;
    }
    final newActive =
        session.activeTabId == tabId ? remaining.last.id : session.activeTabId;
    state = {
      ...state,
      sessionId: session.copyWith(tabs: remaining, activeTabId: newActive),
    };
  }

  void setActiveTab(String sessionId, String tabId) {
    final session = state[sessionId];
    if (session == null) return;
    state = {...state, sessionId: session.copyWith(activeTabId: tabId)};
  }

  void updateTabDatabase(String sessionId, String tabId, String database) {
    final session = state[sessionId];
    if (session == null) return;
    final updatedTabs =
        session.tabs.map((t) {
          return t.id == tabId ? t.copyWith(activeDatabase: database) : t;
        }).toList();
    state = {...state, sessionId: session.copyWith(tabs: updatedTabs)};
  }
}
