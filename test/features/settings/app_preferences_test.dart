import 'package:flutter_test/flutter_test.dart';
import 'package:sqlvanta/features/settings/domain/entities/app_preferences.dart';

void main() {
  group('AppPreferences', () {
    test('has correct defaults', () {
      const p = AppPreferences();
      expect(p.themeMode, 'system');
      expect(p.editorFontSize, 14);
      expect(p.editorTabSize, 2);
      expect(p.editorWordWrap, isFalse);
      expect(p.resultMaxRows, 1000);
      expect(p.nullDisplayText, 'NULL');
      expect(p.sidebarWidth, 260);
    });

    test('copyWith overrides only specified fields', () {
      const p = AppPreferences();
      final updated = p.copyWith(themeMode: 'dark', editorFontSize: 16);
      expect(updated.themeMode, 'dark');
      expect(updated.editorFontSize, 16);
      // unchanged
      expect(updated.editorTabSize, 2);
      expect(updated.resultMaxRows, 1000);
    });

    test('copyWith without args returns equivalent preferences', () {
      const p = AppPreferences(themeMode: 'light', editorFontSize: 18);
      final copy = p.copyWith();
      expect(copy.themeMode, p.themeMode);
      expect(copy.editorFontSize, p.editorFontSize);
      expect(copy.editorTabSize, p.editorTabSize);
    });

    test('copyWith can toggle editorWordWrap', () {
      const p = AppPreferences();
      final wrapped = p.copyWith(editorWordWrap: true);
      expect(wrapped.editorWordWrap, isTrue);
      final unwrapped = wrapped.copyWith(editorWordWrap: false);
      expect(unwrapped.editorWordWrap, isFalse);
    });

    test('supports custom null display text', () {
      const p = AppPreferences(nullDisplayText: '(null)');
      expect(p.nullDisplayText, '(null)');
    });

    test('themeMode values are valid strings', () {
      for (final mode in ['system', 'light', 'dark']) {
        final p = AppPreferences(themeMode: mode);
        expect(p.themeMode, mode);
      }
    });
  });
}
