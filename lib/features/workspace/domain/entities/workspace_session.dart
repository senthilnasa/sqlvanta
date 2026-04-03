import 'package:equatable/equatable.dart';
import 'package:mysql_client/mysql_client.dart';

import '../../../connections/domain/entities/connection_entity.dart';
import '../../../query_editor/domain/entities/query_tab.dart';

class WorkspaceSession extends Equatable {
  final String sessionId;
  final ConnectionEntity connection;
  final MySQLConnection mysqlConnection;
  final List<QueryTab> tabs;
  final String? activeTabId;

  const WorkspaceSession({
    required this.sessionId,
    required this.connection,
    required this.mysqlConnection,
    this.tabs = const [],
    this.activeTabId,
  });

  WorkspaceSession copyWith({
    List<QueryTab>? tabs,
    String? activeTabId,
  }) {
    return WorkspaceSession(
      sessionId: sessionId,
      connection: connection,
      mysqlConnection: mysqlConnection,
      tabs: tabs ?? this.tabs,
      activeTabId: activeTabId ?? this.activeTabId,
    );
  }

  @override
  List<Object?> get props =>
      [sessionId, connection, tabs, activeTabId];
}
