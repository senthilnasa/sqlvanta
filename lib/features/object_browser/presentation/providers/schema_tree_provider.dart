import 'package:mysql_client/mysql_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../mysql/mysql_schema_fetcher.dart';
import '../../domain/entities/database_node.dart';
import '../../domain/entities/table_node.dart';

part 'schema_tree_provider.g.dart';

@riverpod
MysqlSchemaFetcher schemaFetcher(SchemaFetcherRef ref) =>
    const MysqlSchemaFetcher();

@riverpod
Future<List<DatabaseNode>> schemaDatabases(
  SchemaDatabasesRef ref,
  MySQLConnection conn,
) async {
  final fetcher = ref.watch(schemaFetcherProvider);
  final results = await fetcher.fetchDatabases(conn);
  return results.map((d) => DatabaseNode(d.name)).toList();
}

@riverpod
Future<List<TableNode>> schemaTables(
  SchemaTablesRef ref,
  MySQLConnection conn,
  String database,
) async {
  final fetcher = ref.watch(schemaFetcherProvider);
  final results = await fetcher.fetchTables(conn, database);
  return results
      .map(
        (t) => TableNode(
          name: t.name,
          type: t.type,
          estimatedRows: t.estimatedRows,
        ),
      )
      .toList();
}
