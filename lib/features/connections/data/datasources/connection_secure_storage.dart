import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/db_constants.dart';

class ConnectionSecureStorage {
  final FlutterSecureStorage _storage;
  const ConnectionSecureStorage(this._storage);

  String _key(String connectionId) =>
      '${DbConstants.secureStorageKeyPrefix}$connectionId';

  Future<void> savePassword(String connectionId, String password) =>
      _storage.write(key: _key(connectionId), value: password);

  Future<String?> getPassword(String connectionId) =>
      _storage.read(key: _key(connectionId));

  Future<void> deletePassword(String connectionId) =>
      _storage.delete(key: _key(connectionId));
}
