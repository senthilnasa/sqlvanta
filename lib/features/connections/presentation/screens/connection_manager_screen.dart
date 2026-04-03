import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/db_constants.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../domain/entities/connection_entity.dart';
import '../providers/connection_providers.dart';
import '../widgets/connection_form.dart';
import '../widgets/connection_list_tile.dart';
import '../widgets/connection_test_banner.dart';
import '../../../workspace/presentation/providers/workspace_provider.dart';

class ConnectionManagerScreen extends ConsumerStatefulWidget {
  const ConnectionManagerScreen({super.key});

  @override
  ConsumerState<ConnectionManagerScreen> createState() =>
      _ConnectionManagerScreenState();
}

class _ConnectionManagerScreenState
    extends ConsumerState<ConnectionManagerScreen> {
  ConnectionEntity? _editing;
  String? _editingPassword;
  bool _isNew = false;

  // Open state
  bool _openingConnection = false;

  // Test state
  bool _testLoading = false;
  bool? _testSuccess;
  Duration? _testLatency;
  String? _testError;

  void _newConnection() {
    setState(() {
      _editing = null;
      _editingPassword = null;
      _isNew = true;
      _resetTest();
    });
  }

  Future<void> _selectConnection(ConnectionEntity c) async {
    final storage = ref.read(secureStorageProvider);
    final password =
        await storage.read(
          key: '${DbConstants.secureStorageKeyPrefix}${c.id}',
        ) ??
        '';
    if (mounted) {
      setState(() {
        _editing = c;
        _editingPassword = password;
        _isNew = false;
        _resetTest();
      });
    }
  }

  void _resetTest() {
    _testLoading = false;
    _testSuccess = null;
    _testLatency = null;
    _testError = null;
  }

  Future<void> _save(ConnectionEntity entity, String password) async {
    await ref.read(connectionListProvider.notifier).save(entity, password);
    _showSuccessToast('Connection saved');
    if (mounted) {
      setState(() {
        _editing = entity;
        _isNew = false;
      });
    }
  }

  Future<void> _openConnection(ConnectionEntity entity) async {
    setState(() => _openingConnection = true);
    final cancelLoading = BotToast.showCustomLoading(
      toastBuilder: (_) => _ConnectingToast(name: entity.name),
    );
    try {
      final storage = ref.read(secureStorageProvider);
      final password =
          await storage.read(
            key: '${DbConstants.secureStorageKeyPrefix}${entity.id}',
          ) ??
          '';
      await ref
          .read(workspaceProvider.notifier)
          .openConnection(entity, password);
      // Set this connection as the active tab in the IDE shell
      ref.read(activeSessionIdProvider.notifier).select(entity.id);
      cancelLoading();
      if (mounted) context.push('/workspace');
    } catch (e) {
      cancelLoading();
      _showErrorToast('Connection failed', e.toString());
    } finally {
      if (mounted) setState(() => _openingConnection = false);
    }
  }

  static void _showErrorToast(String title, String message) {
    BotToast.showCustomNotification(
      duration: const Duration(seconds: 5),
      toastBuilder:
          (_) => _AppToast(
            icon: Icons.error_outline,
            iconColor: Colors.redAccent,
            title: title,
            message: message,
          ),
    );
  }

  static void _showSuccessToast(String message) {
    BotToast.showCustomNotification(
      duration: const Duration(seconds: 3),
      toastBuilder:
          (_) => _AppToast(
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
            title: 'Success',
            message: message,
          ),
    );
  }

  Future<void> _test(ConnectionEntity entity, String password) async {
    setState(() {
      _testLoading = true;
      _testSuccess = null;
      _testError = null;
    });
    final result = await ref
        .read(connectionListProvider.notifier)
        .test(entity, password);
    if (mounted) {
      setState(() {
        _testLoading = false;
        result.fold(
          onSuccess: (d) {
            _testSuccess = true;
            _testLatency = d;
          },
          onFailure: (f) {
            _testSuccess = false;
            _testError = f.message;
          },
        );
      });
    }
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Connection'),
            content: const Text(
              'This will permanently remove the connection and its saved password.',
            ),
            actions: [
              TextButton(
                onPressed: () => ctx.pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => ctx.pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirm == true) {
      await ref.read(connectionListProvider.notifier).remove(id);
      if (mounted && _editing?.id == id) {
        setState(() {
          _editing = null;
          _isNew = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(connectionListProvider);
    final selected = ref.watch(selectedConnectionIdProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          // ── Left panel: connection list ──────────────────────────────────
          SizedBox(
            width: 280,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Row(
                    children: [
                      const Text(
                        'Connections',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        tooltip: 'New connection',
                        onPressed: _newConnection,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: listAsync.when(
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data:
                        (list) =>
                            list.isEmpty
                                ? EmptyStateWidget(
                                  icon: Icons.storage_outlined,
                                  title: 'No connections',
                                  subtitle: 'Click + to add a new connection',
                                  action: FilledButton.icon(
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('New Connection'),
                                    onPressed: _newConnection,
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: list.length,
                                  itemBuilder: (ctx, i) {
                                    final c = list[i];
                                    return ConnectionListTile(
                                      connection: c,
                                      isSelected: selected == c.id,
                                      onTap: () {
                                        ref
                                            .read(
                                              selectedConnectionIdProvider
                                                  .notifier,
                                            )
                                            .select(c.id);
                                        _selectConnection(c);
                                      },
                                      onDelete: () => _delete(c.id),
                                    );
                                  },
                                ),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),

          // ── Right panel: form ────────────────────────────────────────────
          Expanded(
            child:
                (_editing != null || _isNew)
                    ? Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          color: theme.colorScheme.surfaceContainerHighest,
                          width: double.infinity,
                          child: Row(
                            children: [
                              Text(
                                _isNew
                                    ? 'New Connection'
                                    : _editing?.name ?? 'Edit Connection',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              if (_editing != null && !_isNew)
                                FilledButton.icon(
                                  icon:
                                      _openingConnection
                                          ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                          : const Icon(
                                            Icons.open_in_new,
                                            size: 16,
                                          ),
                                  label: const Text('Open'),
                                  onPressed:
                                      _openingConnection
                                          ? null
                                          : () => _openConnection(_editing!),
                                ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ConnectionForm(
                            key: ValueKey(_isNew ? 'new' : _editing?.id),
                            initial: _editing,
                            initialPassword: _editingPassword,
                            onSave: _save,
                            onTest: _test,
                          ),
                        ),
                        ConnectionTestBanner(
                          isLoading: _testLoading,
                          success: _testSuccess,
                          latency: _testLatency,
                          errorMessage: _testError,
                        ),
                        const SizedBox(height: 8),
                      ],
                    )
                    : EmptyStateWidget(
                      icon: Icons.storage_outlined,
                      title: 'Select or create a connection',
                      subtitle:
                          'Choose a connection from the list or add a new one',
                      action: FilledButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('New Connection'),
                        onPressed: _newConnection,
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

// ── Toast widgets ─────────────────────────────────────────────────────────────

class _ConnectingToast extends StatelessWidget {
  final String name;
  const _ConnectingToast({required this.name});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(60),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: cs.primary, strokeWidth: 3),
            const SizedBox(height: 16),
            Text(
              'Connecting to',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppToast extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  const _AppToast({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        margin: const EdgeInsets.only(bottom: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: cs.onSurface,
                    ),
                  ),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
