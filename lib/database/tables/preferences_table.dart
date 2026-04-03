import 'package:drift/drift.dart';

class Preferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()(); // JSON-encoded
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}
