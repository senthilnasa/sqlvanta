import 'package:equatable/equatable.dart';

enum TabType { query, schemaDesigner, queryBuilder, schemaExplorer }

class QueryTab extends Equatable {
  final String id;
  final String title;
  final String sql;
  final String sessionId;
  final String? activeDatabase;
  final TabType type;

  const QueryTab({
    required this.id,
    required this.title,
    this.sql = '',
    required this.sessionId,
    this.activeDatabase,
    this.type = TabType.query,
  });

  QueryTab copyWith({
    String? title,
    String? sql,
    String? activeDatabase,
    TabType? type,
  }) {
    return QueryTab(
      id: id,
      title: title ?? this.title,
      sql: sql ?? this.sql,
      sessionId: sessionId,
      activeDatabase: activeDatabase ?? this.activeDatabase,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [id, title, sql, sessionId, activeDatabase, type];
}
