import 'dart:io';

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

const _githubUrl = 'https://sqlvanta.senthilnasa.me/';

class AppStatusBar extends StatelessWidget {
  final String? connectionName;
  final String? serverVersion;
  final int? rowCount;
  final int? durationMs;

  const AppStatusBar({
    super.key,
    this.connectionName,
    this.serverVersion,
    this.rowCount,
    this.durationMs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final barColor = isDark ? const Color(0xFF007ACC) : cs.primary;
    final textColor = Colors.white;
    final textStyle = TextStyle(fontSize: 11, color: textColor);

    return Container(
      height: 22,
      color: barColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          if (connectionName != null) ...[
            const Icon(Icons.circle, size: 7, color: Colors.greenAccent),
            const SizedBox(width: 5),
            Text(connectionName!, style: textStyle),
            _pipe(textColor),
          ],
          if (serverVersion != null) ...[
            Text('MySQL $serverVersion', style: textStyle),
            _pipe(textColor),
          ],
          if (rowCount != null) ...[
            Icon(Icons.table_rows_outlined, size: 11, color: textColor),
            const SizedBox(width: 3),
            Text(
              '$rowCount row${rowCount == 1 ? '' : 's'}'
              '${durationMs != null ? ' · ${durationMs}ms' : ''}',
              style: textStyle,
            ),
            _pipe(textColor),
          ],

          const Spacer(),

          // App name
          Text(
            AppConstants.appName,
            style: textStyle.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),

          // GitHub link
          _GitHubLink(textColor: textColor),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _pipe(Color color) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Text(
      '|',
      style: TextStyle(color: color.withAlpha(140), fontSize: 11),
    ),
  );
}

// ── GitHub link ───────────────────────────────────────────────────────────────

class _GitHubLink extends StatefulWidget {
  final Color textColor;
  const _GitHubLink({required this.textColor});

  @override
  State<_GitHubLink> createState() => _GitHubLinkState();
}

class _GitHubLinkState extends State<_GitHubLink> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _githubUrl,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: _openGitHub,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.code,
                size: 11,
                color: widget.textColor.withAlpha(200),
              ),
              const SizedBox(width: 3),
              Text(
                'sqlvanta.senthilnasa.me',
                style: TextStyle(
                  fontSize: 11,
                  color: widget.textColor,
                  decoration: _hovering ? TextDecoration.underline : null,
                  decorationColor: widget.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openGitHub() {
    try {
      if (Platform.isWindows) {
        Process.run('cmd', ['/c', 'start', '', _githubUrl]);
      } else if (Platform.isMacOS) {
        Process.run('open', [_githubUrl]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [_githubUrl]);
      }
    } catch (_) {}
  }
}
