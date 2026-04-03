import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/preferences_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(preferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (prefs) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Theme
            _SectionHeader('Appearance'),
            DropdownButtonFormField<String>(
              initialValue: prefs.themeMode,
              decoration: const InputDecoration(
                labelText: 'Theme',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'system', child: Text('System')),
                DropdownMenuItem(value: 'light', child: Text('Light')),
                DropdownMenuItem(value: 'dark', child: Text('Dark')),
              ],
              onChanged: (v) {
                if (v != null) {
                  ref
                      .read(preferencesProvider.notifier)
                      .save(prefs.copyWith(themeMode: v));
                }
              },
            ),
            const SizedBox(height: 24),

            // Editor
            _SectionHeader('Editor'),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Font Size: ${prefs.editorFontSize.toInt()}pt',
                          style: const TextStyle(fontSize: 13)),
                      Slider(
                        value: prefs.editorFontSize,
                        min: 10,
                        max: 24,
                        divisions: 14,
                        label: '${prefs.editorFontSize.toInt()}pt',
                        onChanged: (v) => ref
                            .read(preferencesProvider.notifier)
                            .save(prefs.copyWith(editorFontSize: v)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: prefs.editorTabSize,
              decoration: const InputDecoration(
                labelText: 'Tab Size',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 2, child: Text('2 spaces')),
                DropdownMenuItem(value: 4, child: Text('4 spaces')),
              ],
              onChanged: (v) {
                if (v != null) {
                  ref
                      .read(preferencesProvider.notifier)
                      .save(prefs.copyWith(editorTabSize: v));
                }
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Word Wrap'),
              value: prefs.editorWordWrap,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => ref
                  .read(preferencesProvider.notifier)
                  .save(prefs.copyWith(editorWordWrap: v)),
            ),
            const SizedBox(height: 24),

            // Results
            _SectionHeader('Results'),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Max Rows: ${prefs.resultMaxRows}',
                    style: const TextStyle(fontSize: 13)),
                Slider(
                  value: prefs.resultMaxRows.toDouble(),
                  min: 100,
                  max: 10000,
                  divisions: 99,
                  label: prefs.resultMaxRows.toString(),
                  onChanged: (v) => ref
                      .read(preferencesProvider.notifier)
                      .save(
                          prefs.copyWith(resultMaxRows: v.toInt())),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: prefs.nullDisplayText,
              decoration: const InputDecoration(
                labelText: 'NULL Display Text',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onFieldSubmitted: (v) => ref
                  .read(preferencesProvider.notifier)
                  .save(prefs.copyWith(nullDisplayText: v)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
