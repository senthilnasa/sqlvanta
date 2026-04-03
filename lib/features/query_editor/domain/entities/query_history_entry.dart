import 'package:equatable/equatable.dart';

class QueryHistoryEntry extends Equatable {
  final String id;
  final String connectionId;
  final String? databaseName;
  final String sqlText;
  final DateTime executedAt;
  final int durationMs;
  final int? rowsAffected;
  final bool hadError;
  final String? errorMessage;
  final bool isFavorite;

  const QueryHistoryEntry({
    required this.id,
    required this.connectionId,
    this.databaseName,
    required this.sqlText,
    required this.executedAt,
    required this.durationMs,
    this.rowsAffected,
    this.hadError = false,
    this.errorMessage,
    this.isFavorite = false,
  });

  @override
  List<Object?> get props => [id, connectionId, sqlText, executedAt];
}
