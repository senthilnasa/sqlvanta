abstract final class DbConstants {
  static const int defaultPort = 3306;
  static const int defaultConnectionTimeoutSeconds = 30;
  static const int keepAliveIntervalMinutes = 10;
  static const int defaultResultMaxRows = 1000;
  static const int absoluteMaxRows = 10000;
  static const String nullDisplayText = 'NULL';
  static const String secureStorageKeyPrefix = 'sqlvanta_conn_';
}
