import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqlvanta/core/errors/failures.dart';
import 'package:sqlvanta/core/utils/result.dart';
import 'package:sqlvanta/features/connections/domain/entities/connection_entity.dart';
import 'package:sqlvanta/features/connections/domain/repositories/connection_repository.dart';
import 'package:sqlvanta/features/connections/domain/usecases/delete_connection.dart';
import 'package:sqlvanta/features/connections/domain/usecases/get_all_connections.dart';
import 'package:sqlvanta/features/connections/domain/usecases/save_connection.dart';
import 'package:sqlvanta/features/connections/domain/usecases/test_connection.dart';

class MockConnectionRepository extends Mock implements ConnectionRepository {}

const _entity = ConnectionEntity(
  id: 'id-1',
  name: 'Test',
  host: 'localhost',
  port: 3306,
  username: 'root',
);

void main() {
  late MockConnectionRepository repo;

  setUpAll(() {
    registerFallbackValue(const ConnectionEntity(
      id: '', name: '', host: '', port: 3306, username: '',
    ));
  });

  setUp(() => repo = MockConnectionRepository());

  group('GetAllConnections', () {
    test('returns list on success', () async {
      when(() => repo.getAllConnections())
          .thenAnswer((_) async => const Result.success([_entity]));

      final result = await GetAllConnections(repo).call();

      expect(result.isSuccess, isTrue);
      expect(result.value, [_entity]);
      verify(() => repo.getAllConnections()).called(1);
    });

    test('propagates failure', () async {
      when(() => repo.getAllConnections())
          .thenAnswer((_) async =>
              const Result.failure(StorageFailure('db error')));

      final result = await GetAllConnections(repo).call();

      expect(result.isFailure, isTrue);
      expect(result.error, isA<StorageFailure>());
    });
  });

  group('SaveConnection', () {
    test('calls repository with entity and password', () async {
      when(() => repo.saveConnection(any(), any()))
          .thenAnswer((_) async => const Result.success(null));

      final result =
          await SaveConnection(repo).call(_entity, 'secret');

      expect(result.isSuccess, isTrue);
      verify(() => repo.saveConnection(_entity, 'secret')).called(1);
    });

    test('propagates storage failure', () async {
      when(() => repo.saveConnection(any(), any()))
          .thenAnswer((_) async =>
              const Result.failure(StorageFailure('write failed')));

      final result =
          await SaveConnection(repo).call(_entity, 'secret');

      expect(result.isFailure, isTrue);
      expect(result.error.message, 'write failed');
    });
  });

  group('DeleteConnection', () {
    test('calls repository with the connection id', () async {
      when(() => repo.deleteConnection(any()))
          .thenAnswer((_) async => const Result.success(null));

      final result = await DeleteConnection(repo).call('id-1');

      expect(result.isSuccess, isTrue);
      verify(() => repo.deleteConnection('id-1')).called(1);
    });

    test('propagates failure', () async {
      when(() => repo.deleteConnection(any()))
          .thenAnswer((_) async =>
              const Result.failure(StorageFailure('not found')));

      final result = await DeleteConnection(repo).call('id-1');

      expect(result.isFailure, isTrue);
    });
  });

  group('TestConnection', () {
    test('returns duration on successful ping', () async {
      final latency = const Duration(milliseconds: 42);
      when(() => repo.testConnection(any(), any()))
          .thenAnswer((_) async => Result.success(latency));

      final result =
          await TestConnection(repo).call(_entity, 'secret');

      expect(result.isSuccess, isTrue);
      expect(result.value, latency);
    });

    test('returns NetworkFailure when connection fails', () async {
      when(() => repo.testConnection(any(), any()))
          .thenAnswer((_) async =>
              const Result.failure(NetworkFailure('connection refused')));

      final result =
          await TestConnection(repo).call(_entity, 'secret');

      expect(result.isFailure, isTrue);
      expect(result.error, isA<NetworkFailure>());
      expect(result.error.message, 'connection refused');
    });
  });
}
