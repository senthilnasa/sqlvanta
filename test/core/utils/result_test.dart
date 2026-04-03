import 'package:flutter_test/flutter_test.dart';
import 'package:sqlvanta/core/utils/result.dart';

void main() {
  group('Result', () {
    group('ResultSuccess', () {
      test('isSuccess is true', () {
        const r = Result<int, String>.success(42);
        expect(r.isSuccess, isTrue);
        expect(r.isFailure, isFalse);
      });

      test('value returns the wrapped value', () {
        const r = Result<String, String>.success('hello');
        expect(r.value, 'hello');
      });

      test('fold calls onSuccess', () {
        const r = Result<int, String>.success(10);
        final out = r.fold(onSuccess: (v) => 'ok:$v', onFailure: (_) => 'fail');
        expect(out, 'ok:10');
      });

      test('map transforms the success value', () {
        const r = Result<int, String>.success(5);
        final mapped = r.map((v) => v * 2);
        expect(mapped.isSuccess, isTrue);
        expect(mapped.value, 10);
      });
    });

    group('ResultFailure', () {
      test('isFailure is true', () {
        const r = Result<int, String>.failure('oops');
        expect(r.isFailure, isTrue);
        expect(r.isSuccess, isFalse);
      });

      test('error returns the wrapped error', () {
        const r = Result<int, String>.failure('bad');
        expect(r.error, 'bad');
      });

      test('fold calls onFailure', () {
        const r = Result<int, String>.failure('err');
        final out = r.fold(onSuccess: (_) => 'ok', onFailure: (e) => 'fail:$e');
        expect(out, 'fail:err');
      });

      test('map preserves failure without calling transform', () {
        var called = false;
        const r = Result<int, String>.failure('err');
        final mapped = r.map((v) {
          called = true;
          return v * 2;
        });
        expect(mapped.isFailure, isTrue);
        expect(mapped.error, 'err');
        expect(called, isFalse);
      });
    });

    test('accessing value on failure throws', () {
      const r = Result<int, String>.failure('oops');
      expect(() => r.value, throwsA(isA<TypeError>()));
    });

    test('accessing error on success throws', () {
      const r = Result<int, String>.success(1);
      expect(() => r.error, throwsA(isA<TypeError>()));
    });
  });
}
