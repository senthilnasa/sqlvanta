import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/db_constants.dart';
import '../../../workspace/presentation/providers/workspace_provider.dart';
import '../../domain/entities/connection_entity.dart';
import '../providers/connection_providers.dart';

/// SQLyog-style "Connect to MySQL Server" dialog.
///
/// ┌──────────────────────────────────────────────────────────────┐
/// │  ⊗  Connect to MySQL Server                                 │
/// ├─────────────────┬────────────────────────────────────────────┤
/// │  Saved Conns    │  Connection Name: [_____________________]  │
/// │  ─────────────  │  MySQL Host: [________________] Port:[___] │
/// │  + New          │  Username:   [_____________________]       │
/// │  ─────────────  │  Password:   [_________________] [👁]     │
/// │  ○ Production   │  Database:   [_____________________]       │
/// │  ○ Development  │                                            │
/// │  ○ Local Dev    │  [▶ Test Connection]  ✓ OK (12ms)         │
/// ├─────────────────┴────────────────────────────────────────────┤
/// │  [🗑 Delete]  [💾 Save]              [Cancel]  [Connect →]  │
/// └──────────────────────────────────────────────────────────────┘
class ConnectionDialog extends ConsumerStatefulWidget {
  const ConnectionDialog({super.key});

  /// Show the dialog. Returns after the dialog is dismissed.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ConnectionDialog(),
    );
  }

  @override
  ConsumerState<ConnectionDialog> createState() => _ConnectionDialogState();
}

class _ConnectionDialogState extends ConsumerState<ConnectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _hostCtrl = TextEditingController(text: '127.0.0.1');
  final _portCtrl = TextEditingController(text: '3306');
  final _userCtrl = TextEditingController(text: 'root');
  final _passCtrl = TextEditingController();
  final _dbCtrl = TextEditingController();

  bool _obscurePass = true;
  ConnectionEntity? _selected;
  bool _isNew = true;

  bool _testLoading = false;
  bool? _testSuccess;
  String? _testError;
  int? _testMs;
  bool _connecting = false;

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _hostCtrl,
      _portCtrl,
      _userCtrl,
      _passCtrl,
      _dbCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _resetForm(ConnectionEntity? entity, {String password = ''}) {
    setState(() {
      _selected = entity;
      _isNew = entity == null;
      _nameCtrl.text = entity?.name ?? '';
      _hostCtrl.text = entity?.host ?? '127.0.0.1';
      _portCtrl.text = (entity?.port ?? DbConstants.defaultPort).toString();
      _userCtrl.text = entity?.username ?? 'root';
      _passCtrl.text = password;
      _dbCtrl.text = entity?.defaultDatabase ?? '';
      _testSuccess = null;
      _testError = null;
      _testMs = null;
    });
  }

  ConnectionEntity _buildEntity() => ConnectionEntity(
    id: _selected?.id ?? const Uuid().v4(),
    name: _nameCtrl.text.trim(),
    host: _hostCtrl.text.trim(),
    port: int.tryParse(_portCtrl.text) ?? DbConstants.defaultPort,
    username: _userCtrl.text.trim(),
    defaultDatabase: _dbCtrl.text.trim().isEmpty ? null : _dbCtrl.text.trim(),
    sortOrder: _selected?.sortOrder ?? 0,
  );

  Future<void> _onSelectSaved(ConnectionEntity c) async {
    final storage = ref.read(secureStorageProvider);
    final pass =
        await storage.read(
          key: '${DbConstants.secureStorageKeyPrefix}${c.id}',
        ) ??
        '';
    if (mounted) _resetForm(c, password: pass);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final entity = _buildEntity();
    await ref
        .read(connectionListProvider.notifier)
        .save(entity, _passCtrl.text);
    if (mounted) {
      setState(() {
        _selected = entity;
        _isNew = false;
      });
      BotToast.showSimpleNotification(title: 'Saved', subTitle: entity.name);
    }
  }

  Future<void> _test() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _testLoading = true;
      _testSuccess = null;
      _testError = null;
      _testMs = null;
    });
    final result = await ref
        .read(connectionListProvider.notifier)
        .test(_buildEntity(), _passCtrl.text);
    if (mounted) {
      setState(() {
        _testLoading = false;
        result.fold(
          onSuccess: (d) {
            _testSuccess = true;
            _testMs = d.inMilliseconds;
          },
          onFailure: (f) {
            _testSuccess = false;
            _testError = f.message;
          },
        );
      });
    }
  }

  Future<void> _connect() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final entity = _buildEntity();

    setState(() => _connecting = true);
    final cancelLoading = BotToast.showCustomLoading(
      toastBuilder: (_) => _ConnectingToast(name: entity.name),
    );
    try {
      // Auto-save if new so it appears in the list next time
      if (_isNew || _selected == null) {
        await ref
            .read(connectionListProvider.notifier)
            .save(entity, _passCtrl.text);
      }
      await ref
          .read(workspaceProvider.notifier)
          .openConnection(entity, _passCtrl.text);
      ref.read(activeSessionIdProvider.notifier).select(entity.id);
      cancelLoading();
      if (mounted) {
        Navigator.of(context).pop();
        if (context.mounted) {
          final currentPath = GoRouterState.of(context).uri.path;
          if (currentPath != '/workspace') context.go('/workspace');
        }
      }
    } catch (e) {
      cancelLoading();
      if (mounted) {
        setState(() {
          _connecting = false;
          _testSuccess = false;
          _testError = e.toString();
        });
      }
    }
  }

  Future<void> _delete() async {
    if (_selected == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Connection'),
            content: Text('Remove "${_selected!.name}"?'),
            actions: [
              TextButton(
                onPressed: () => ctx.pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => ctx.pop(true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirm == true && mounted) {
      await ref.read(connectionListProvider.notifier).remove(_selected!.id);
      _resetForm(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final connections = ref.watch(connectionListProvider).valueOrNull ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      elevation: 24,
      child: SizedBox(
        width: 660,
        height: 460,
        child: Column(
          children: [
            // ── Title bar ────────────────────────────────────────────────
            _TitleBar(onClose: () => Navigator.of(context).pop()),

            // ── Body: left list + right form ─────────────────────────────
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Saved connections list ────────────────────────────
                  _SavedConnectionsSidebar(
                    connections: connections,
                    selectedId: _selected?.id,
                    isNew: _isNew,
                    onNew: () => _resetForm(null),
                    onSelect: _onSelectSaved,
                  ),

                  // ── Connection form ───────────────────────────────────
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                        children: [
                          _FormField(
                            controller: _nameCtrl,
                            label: 'Connection Name',
                            hint: 'e.g. Production DB',
                            validator:
                                (v) =>
                                    (v?.trim().isEmpty ?? true)
                                        ? 'Required'
                                        : null,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _FormField(
                                  controller: _hostCtrl,
                                  label: 'MySQL Host',
                                  hint: '127.0.0.1',
                                  validator:
                                      (v) =>
                                          (v?.trim().isEmpty ?? true)
                                              ? 'Required'
                                              : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 82,
                                child: _FormField(
                                  controller: _portCtrl,
                                  label: 'Port',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (v) {
                                    final p = int.tryParse(v ?? '');
                                    return (p == null || p < 1 || p > 65535)
                                        ? 'Invalid'
                                        : null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _FormField(
                            controller: _userCtrl,
                            label: 'Username',
                            hint: 'root',
                            validator:
                                (v) =>
                                    (v?.trim().isEmpty ?? true)
                                        ? 'Required'
                                        : null,
                          ),
                          const SizedBox(height: 10),
                          _PasswordField(
                            controller: _passCtrl,
                            obscure: _obscurePass,
                            onToggle:
                                () => setState(
                                  () => _obscurePass = !_obscurePass,
                                ),
                          ),
                          const SizedBox(height: 10),
                          _FormField(
                            controller: _dbCtrl,
                            label: 'Default Database (optional)',
                          ),
                          const SizedBox(height: 14),
                          _TestRow(
                            loading: _testLoading,
                            success: _testSuccess,
                            error: _testError,
                            ms: _testMs,
                            onTest: _test,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Action bar ───────────────────────────────────────────────
            _ActionBar(
              hasSelected: _selected != null,
              connecting: _connecting,
              onDelete: _delete,
              onSave: _save,
              onCancel: () => Navigator.of(context).pop(),
              onConnect: _connect,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _TitleBar extends StatelessWidget {
  final VoidCallback onClose;
  const _TitleBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 42,
      color: cs.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.storage, size: 16, color: cs.onPrimary),
          const SizedBox(width: 10),
          Text(
            'Connect to MySQL Server',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: cs.onPrimary),
            onPressed: onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}

class _SavedConnectionsSidebar extends StatelessWidget {
  final List<ConnectionEntity> connections;
  final String? selectedId;
  final bool isNew;
  final VoidCallback onNew;
  final void Function(ConnectionEntity) onSelect;

  const _SavedConnectionsSidebar({
    required this.connections,
    required this.selectedId,
    required this.isNew,
    required this.onNew,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: 210,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(right: BorderSide(color: cs.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // "New Connection" row
          InkWell(
            onTap: onNew,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color:
                  isNew
                      ? cs.primaryContainer.withAlpha(100)
                      : Colors.transparent,
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, size: 15, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'New Connection',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant),
          // Saved list
          Expanded(
            child:
                connections.isEmpty
                    ? Center(
                      child: Text(
                        'No saved connections',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withAlpha(100),
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.only(top: 4),
                      itemCount: connections.length,
                      itemBuilder: (_, i) {
                        final c = connections[i];
                        final isSelected = selectedId == c.id;
                        return InkWell(
                          onTap: () => onSelect(c),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            color:
                                isSelected
                                    ? cs.primaryContainer.withAlpha(100)
                                    : Colors.transparent,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.storage_outlined,
                                  size: 14,
                                  color:
                                      isSelected
                                          ? cs.primary
                                          : cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.name,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${c.username}@${c.host}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: cs.onSurface.withAlpha(110),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _FormField({
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
      ),
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: 'Password',
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            size: 18,
          ),
          onPressed: onToggle,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _TestRow extends StatelessWidget {
  final bool loading;
  final bool? success;
  final String? error;
  final int? ms;
  final VoidCallback onTest;

  const _TestRow({
    required this.loading,
    required this.success,
    required this.error,
    required this.ms,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          icon:
              loading
                  ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  )
                  : const Icon(Icons.network_ping, size: 14),
          label: const Text('Test Connection', style: TextStyle(fontSize: 12)),
          onPressed: loading ? null : onTest,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        if (success != null) ...[
          const SizedBox(width: 10),
          Icon(
            success! ? Icons.check_circle : Icons.error_outline,
            size: 15,
            color: success! ? Colors.green.shade600 : Colors.red.shade600,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              success!
                  ? 'OK${ms != null ? ' (${ms}ms)' : ''}'
                  : (error ?? 'Failed'),
              style: TextStyle(
                fontSize: 11,
                color: success! ? Colors.green.shade600 : Colors.red.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  final bool hasSelected;
  final bool connecting;
  final VoidCallback onDelete;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback onConnect;

  const _ActionBar({
    required this.hasSelected,
    required this.connecting,
    required this.onDelete,
    required this.onSave,
    required this.onCancel,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          if (hasSelected)
            TextButton.icon(
              icon: const Icon(Icons.delete_outline, size: 15),
              label: const Text('Delete', style: TextStyle(fontSize: 12)),
              onPressed: onDelete,
              style: TextButton.styleFrom(foregroundColor: cs.error),
            ),
          TextButton.icon(
            icon: const Icon(Icons.save_outlined, size: 15),
            label: const Text('Save', style: TextStyle(fontSize: 12)),
            onPressed: onSave,
          ),
          const Spacer(),
          TextButton(
            onPressed: onCancel,
            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            icon:
                connecting
                    ? const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.arrow_forward, size: 15),
            label: const Text('Connect', style: TextStyle(fontSize: 12)),
            onPressed: connecting ? null : onConnect,
          ),
        ],
      ),
    );
  }
}

// ── Loading toast ─────────────────────────────────────────────────────────────

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
