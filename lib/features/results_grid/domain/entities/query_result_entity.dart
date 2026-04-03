// Re-export QueryResult from the mysql infrastructure layer so the
// results_grid feature has a clean domain reference without coupling
// to the mysql package directly.
export '../../../../mysql/mysql_query_executor.dart' show QueryResult;
