import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Incremented each time the user double-clicks a table in the object browser.
/// ResultsPanel watches this and switches to the Table Data tab.
/// Keyed by sessionId.
final tableDataTabSignalProvider =
    StateProvider.family<int, String>((ref, sessionId) => 0);
