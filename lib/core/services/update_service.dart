import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Information about a GitHub release.
class UpdateInfo {
  final String latestVersion; // e.g. "1.2.0"
  final String currentVersion; // e.g. "1.0.0"
  final bool hasUpdate;
  final String releaseNotes;
  final String releaseUrl;
  final String? assetDownloadUrl; // platform-specific download URL
  final String? assetFileName; // e.g. "sqlvanta-windows-x64-1.2.0.zip"

  const UpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.hasUpdate,
    required this.releaseNotes,
    required this.releaseUrl,
    this.assetDownloadUrl,
    this.assetFileName,
  });
}

class UpdateService {
  static const _owner = 'senthilnasa';
  static const _repo = 'sqlvanta';
  static const _apiUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  /// Fetches the latest GitHub release and checks whether an update is available.
  /// [currentVersion] should come from [PackageInfo.version] at call time.
  Future<UpdateInfo> checkForUpdate(String currentVersion) async {
    final response = await http
        .get(
          Uri.parse(_apiUrl),
          headers: {'Accept': 'application/vnd.github+json'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'GitHub API returned ${response.statusCode}: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final tagName = (json['tag_name'] as String? ?? '').replaceAll('v', '');
    final body = json['body'] as String? ?? '';
    final htmlUrl = json['html_url'] as String? ?? '';
    final assets = (json['assets'] as List<dynamic>? ?? []);

    final hasUpdate = _isNewer(tagName, currentVersion);

    String? downloadUrl;
    String? fileName;
    if (hasUpdate) {
      final asset = _pickAsset(assets);
      if (asset != null) {
        downloadUrl = asset['browser_download_url'] as String?;
        fileName = asset['name'] as String?;
      }
    }

    return UpdateInfo(
      latestVersion: tagName,
      currentVersion: currentVersion,
      hasUpdate: hasUpdate,
      releaseNotes: body,
      releaseUrl: htmlUrl,
      assetDownloadUrl: downloadUrl,
      assetFileName: fileName,
    );
  }

  /// Downloads [url] to [savePath], calling [onProgress] with (received, total).
  /// Returns the path to the downloaded file.
  Future<String> download(
    String url,
    String savePath, {
    void Function(int received, int total)? onProgress,
  }) async {
    final request = http.Request('GET', Uri.parse(url));
    final response = await http.Client().send(request);

    final total = response.contentLength ?? 0;
    var received = 0;

    final file = File(savePath);
    final sink = file.openWrite();

    await for (final chunk in response.stream) {
      sink.add(chunk);
      received += chunk.length;
      onProgress?.call(received, total);
    }
    await sink.close();
    return savePath;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Returns true if [candidate] is strictly greater than [current].
  bool _isNewer(String candidate, String current) {
    final c = _parseVersion(candidate);
    final v = _parseVersion(current);
    for (var i = 0; i < 3; i++) {
      if (c[i] > v[i]) return true;
      if (c[i] < v[i]) return false;
    }
    return false;
  }

  List<int> _parseVersion(String v) {
    final parts = v.split('.');
    return List.generate(
      3,
      (i) => i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0,
    );
  }

  /// Picks the release asset that matches the current OS.
  Map<String, dynamic>? _pickAsset(List<dynamic> assets) {
    String pattern;
    if (Platform.isWindows) {
      pattern = 'windows-x64';
    } else if (Platform.isMacOS) {
      pattern = 'macos';
    } else if (Platform.isLinux) {
      pattern = 'linux-x64';
    } else {
      return null;
    }

    for (final a in assets) {
      final name = (a['name'] as String? ?? '').toLowerCase();
      if (name.contains(pattern)) {
        return a as Map<String, dynamic>;
      }
    }
    return null;
  }
}
