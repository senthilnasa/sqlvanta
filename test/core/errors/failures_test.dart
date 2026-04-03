import 'package:flutter_test/flutter_test.dart';
import 'package:sqlvanta/core/errors/failures.dart';

void main() {
  group('Failures', () {
    test('DatabaseFailure stores message and optional errorCode', () {
      const f = DatabaseFailure('connection refused', errorCode: 2003);
      expect(f.message, 'connection refused');
      expect(f.errorCode, 2003);
    });

    test('DatabaseFailure with no errorCode defaults to null', () {
      const f = DatabaseFailure('error');
      expect(f.errorCode, isNull);
    });

    test('NetworkFailure stores message', () {
      const f = NetworkFailure('host unreachable');
      expect(f.message, 'host unreachable');
    });

    test('AuthFailure stores message', () {
      const f = AuthFailure('Access denied for user');
      expect(f.message, 'Access denied for user');
    });

    test('StorageFailure stores message', () {
      const f = StorageFailure('disk full');
      expect(f.message, 'disk full');
    });

    test('ValidationFailure stores message and optional fieldErrors', () {
      const f = ValidationFailure('invalid input', fieldErrors: {'host': 'required'});
      expect(f.message, 'invalid input');
      expect(f.fieldErrors['host'], 'required');
    });

    test('ValidationFailure fieldErrors defaults to empty map', () {
      const f = ValidationFailure('error');
      expect(f.fieldErrors, isEmpty);
    });

    test('UnexpectedFailure stores message and optional exception', () {
      final ex = Exception('boom');
      final f = UnexpectedFailure('unexpected', originalException: ex);
      expect(f.message, 'unexpected');
      expect(f.originalException, ex);
    });

    test('toString includes runtimeType and message', () {
      const f = DatabaseFailure('test error');
      expect(f.toString(), contains('DatabaseFailure'));
      expect(f.toString(), contains('test error'));
    });

    test('failures are sealed — exhaustive switch works', () {
      Failure f = const NetworkFailure('x');
      final label = switch (f) {
        DatabaseFailure() => 'db',
        NetworkFailure() => 'net',
        SshFailure() => 'ssh',
        AuthFailure() => 'auth',
        StorageFailure() => 'storage',
        ValidationFailure() => 'validation',
        UnexpectedFailure() => 'unexpected',
      };
      expect(label, 'net');
    });
  });
}
