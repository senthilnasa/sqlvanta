import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/update_service.dart';
import '../providers/preferences_provider.dart';
import '../providers/update_provider.dart';

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
        data:
            (prefs) => ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Appearance ────────────────────────────────────────────
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

                // ── Editor ────────────────────────────────────────────────
                _SectionHeader('Editor'),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Font Size: ${prefs.editorFontSize.toInt()}pt',
                            style: const TextStyle(fontSize: 13),
                          ),
                          Slider(
                            value: prefs.editorFontSize,
                            min: 10,
                            max: 24,
                            divisions: 14,
                            label: '${prefs.editorFontSize.toInt()}pt',
                            onChanged:
                                (v) => ref
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
                  onChanged:
                      (v) => ref
                          .read(preferencesProvider.notifier)
                          .save(prefs.copyWith(editorWordWrap: v)),
                ),
                const SizedBox(height: 24),

                // ── Results ───────────────────────────────────────────────
                _SectionHeader('Results'),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Max Rows: ${prefs.resultMaxRows}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    Slider(
                      value: prefs.resultMaxRows.toDouble(),
                      min: 100,
                      max: 10000,
                      divisions: 99,
                      label: prefs.resultMaxRows.toString(),
                      onChanged:
                          (v) => ref
                              .read(preferencesProvider.notifier)
                              .save(prefs.copyWith(resultMaxRows: v.toInt())),
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
                  onFieldSubmitted:
                      (v) => ref
                          .read(preferencesProvider.notifier)
                          .save(prefs.copyWith(nullDisplayText: v)),
                ),
                const SizedBox(height: 24),

                // ── Updates ───────────────────────────────────────────────
                _SectionHeader('Updates'),
                const _UpdateSection(),

              ],
            ),
      ),
    );
  }
}

// ── Update Section ────────────────────────────────────────────────────────────

class _UpdateSection extends ConsumerWidget {
  const _UpdateSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateAsync = ref.watch(updateInfoProvider);
    final download = ref.watch(downloadStateProvider);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current version row
        Row(
          children: [
            Text(
              'Current version: v${ref.watch(appVersionProvider).valueOrNull ?? '…'}',
              style: const TextStyle(fontSize: 13),
            ),
            const Spacer(),
            updateAsync.when(
              data: (info) {
                if (info == null) {
                  return FilledButton.icon(
                    icon: const Icon(Icons.search, size: 15),
                    label: const Text('Check for Updates'),
                    onPressed:
                        () => ref.read(updateInfoProvider.notifier).check(),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  );
                }
                return TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text('Re-check', style: TextStyle(fontSize: 12)),
                  onPressed:
                      () {
                        ref.read(downloadStateProvider.notifier).reset();
                        ref.read(updateInfoProvider.notifier).check();
                      },
                );
              },
              loading:
                  () => const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              error:
                  (e, _) => TextButton.icon(
                    icon: const Icon(Icons.refresh, size: 14),
                    label: const Text(
                      'Retry',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed:
                        () => ref.read(updateInfoProvider.notifier).check(),
                  ),
            ),
          ],
        ),

        // Result card
        updateAsync.when(
          data: (info) {
            if (info == null) return const SizedBox.shrink();
            return _UpdateResultCard(info: info, download: download);
          },
          loading: () => const SizedBox.shrink(),
          error:
              (e, _) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 14, color: cs.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Check failed: $e',
                        style: TextStyle(fontSize: 12, color: cs.error),
                      ),
                    ),
                  ],
                ),
              ),
        ),
      ],
    );
  }
}

class _UpdateResultCard extends ConsumerWidget {
  final UpdateInfo info;
  final DownloadState download;

  const _UpdateResultCard({required this.info, required this.download});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    if (!info.hasUpdate) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, size: 15, color: Colors.green.shade500),
            const SizedBox(width: 6),
            Text(
              'You are on the latest version (v${info.currentVersion})',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Update available
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withAlpha(80),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.primary.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.new_releases_outlined, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                'v${info.latestVersion} available',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
            ],
          ),

          if (info.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              info.releaseNotes.length > 300
                  ? '${info.releaseNotes.substring(0, 300)}…'
                  : info.releaseNotes,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withAlpha(180),
              ),
            ),
          ],

          const SizedBox(height: 12),

          if (download.error != null) ...[
            Row(
              children: [
                Icon(Icons.error_outline, size: 13, color: cs.error),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    download.error!,
                    style: TextStyle(fontSize: 11, color: cs.error),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          if (download.isDone) ...[
            Row(
              children: [
                Icon(
                  Icons.download_done_outlined,
                  size: 14,
                  color: Colors.green.shade500,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Downloaded: ${info.assetFileName}',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.folder_open_outlined, size: 13),
                  label: const Text(
                    'Show in Explorer',
                    style: TextStyle(fontSize: 11),
                  ),
                  onPressed:
                      () => ref
                          .read(downloadStateProvider.notifier)
                          .openDownloadFolder(download.savedPath!),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ] else if (download.isDownloading) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Downloading… ${(download.progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: download.progress > 0 ? download.progress : null,
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                if (info.assetDownloadUrl != null) ...[
                  FilledButton.icon(
                    icon: const Icon(Icons.download_outlined, size: 15),
                    label: Text(
                      'Download v${info.latestVersion}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed:
                        () => ref
                            .read(downloadStateProvider.notifier)
                            .startDownload(info),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                TextButton.icon(
                  icon: const Icon(Icons.open_in_browser, size: 13),
                  label: const Text(
                    'View Release',
                    style: TextStyle(fontSize: 11),
                  ),
                  onPressed:
                      () {
                        // Opens in default browser via Process.run
                        _openUrl(info.releaseUrl);
                      },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

void _openUrl(String url) {
  if (url.isEmpty) return;
  try {
    if (Platform.isWindows) {
      Process.run('cmd', ['/c', 'start', '', url]);
    } else if (Platform.isMacOS) {
      Process.run('open', [url]);
    } else if (Platform.isLinux) {
      Process.run('xdg-open', [url]);
    }
  } catch (_) {}
}

// ── Section Header ────────────────────────────────────────────────────────────

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
