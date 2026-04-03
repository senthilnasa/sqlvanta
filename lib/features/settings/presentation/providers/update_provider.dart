import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/services/update_service.dart';

final _updateService = UpdateService();

// ── App version ──────────────────────────────────────────────────────────────

/// Resolves once and caches the running app's version string (e.g. "1.0.0").
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version; // e.g. "1.0.0"  (no build number)
});

// ── Check provider ──────────────────────────────────────────────────────────

/// Fetches update info from GitHub. null means not yet checked.
final updateInfoProvider =
    AsyncNotifierProvider<UpdateInfoNotifier, UpdateInfo?>(
      UpdateInfoNotifier.new,
    );

class UpdateInfoNotifier extends AsyncNotifier<UpdateInfo?> {
  @override
  Future<UpdateInfo?> build() async => null; // lazy — don't check on startup

  Future<void> check() async {
    state = const AsyncLoading();
    final currentVersion = await ref.read(appVersionProvider.future);
    state = await AsyncValue.guard(
      () => _updateService.checkForUpdate(currentVersion),
    );
  }
}

// ── Download provider ───────────────────────────────────────────────────────

class DownloadState {
  final bool isDownloading;
  final double progress; // 0.0 – 1.0
  final String? savedPath;
  final String? error;

  const DownloadState({
    this.isDownloading = false,
    this.progress = 0,
    this.savedPath,
    this.error,
  });

  bool get isDone => savedPath != null;

  DownloadState copyWith({
    bool? isDownloading,
    double? progress,
    String? savedPath,
    String? error,
  }) => DownloadState(
    isDownloading: isDownloading ?? this.isDownloading,
    progress: progress ?? this.progress,
    savedPath: savedPath ?? this.savedPath,
    error: error ?? this.error,
  );
}

final downloadStateProvider =
    NotifierProvider<DownloadNotifier, DownloadState>(DownloadNotifier.new);

class DownloadNotifier extends Notifier<DownloadState> {
  @override
  DownloadState build() => const DownloadState();

  Future<void> startDownload(UpdateInfo info) async {
    if (info.assetDownloadUrl == null || info.assetFileName == null) return;

    state = const DownloadState(isDownloading: true, progress: 0);

    try {
      final dir = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final savePath =
          '${dir.path}${Platform.pathSeparator}${info.assetFileName}';

      await _updateService.download(
        info.assetDownloadUrl!,
        savePath,
        onProgress: (received, total) {
          if (total > 0) {
            state = state.copyWith(
              isDownloading: true,
              progress: received / total,
            );
          }
        },
      );

      state = DownloadState(
        isDownloading: false,
        progress: 1.0,
        savedPath: savePath,
      );
    } catch (e) {
      state = DownloadState(isDownloading: false, error: e.toString());
    }
  }

  void reset() => state = const DownloadState();

  void openDownloadFolder(String filePath) {
    try {
      if (Platform.isWindows) {
        Process.run('explorer.exe', ['/select,', filePath]);
      } else if (Platform.isMacOS) {
        Process.run('open', ['-R', filePath]);
      } else if (Platform.isLinux) {
        final dir = File(filePath).parent.path;
        Process.run('xdg-open', [dir]);
      }
    } catch (_) {}
  }
}
