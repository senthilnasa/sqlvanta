import 'package:flutter/material.dart';

class ConnectionTestBanner extends StatelessWidget {
  final bool? success;
  final Duration? latency;
  final String? errorMessage;
  final bool isLoading;

  const ConnectionTestBanner({
    super.key,
    this.success,
    this.latency,
    this.errorMessage,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Testing connection…'),
          ],
        ),
      );
    }

    if (success == null) return const SizedBox.shrink();

    final color = success! ? Colors.green.shade600 : Colors.red.shade600;
    final icon = success! ? Icons.check_circle_outline : Icons.error_outline;
    final message =
        success!
            ? 'Connection successful — ${latency!.inMilliseconds}ms'
            : errorMessage ?? 'Connection failed';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(message, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
