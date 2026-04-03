import 'package:drift/drift.dart';

class Connections extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get host => text()();
  IntColumn get port => integer().withDefault(const Constant(3306))();
  TextColumn get username => text()();

  // Key into flutter_secure_storage — NOT the actual password
  TextColumn get passwordKey => text()();

  TextColumn get defaultDatabase => text().nullable()();
  BoolColumn get useSsl => boolean().withDefault(const Constant(false))();
  TextColumn get sslCaCertPath => text().nullable()();
  IntColumn get connectionTimeout =>
      integer().withDefault(const Constant(30))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastConnectedAt => dateTime().nullable()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get colorTag => text().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
