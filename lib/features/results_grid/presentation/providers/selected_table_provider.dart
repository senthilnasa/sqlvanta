import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Carries the DB + table that the user clicked in the object browser.
/// Keyed by sessionId so each connection has independent state.
class SelectedTable {
  final String database;
  final String table;
  const SelectedTable({required this.database, required this.table});
}

final selectedTableProvider = StateProvider.family<SelectedTable?, String>(
  (ref, sessionId) => null,
);
