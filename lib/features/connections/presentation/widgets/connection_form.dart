import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/db_constants.dart';
import '../../domain/entities/connection_entity.dart';

class ConnectionForm extends StatefulWidget {
  final ConnectionEntity? initial;
  final String? initialPassword;
  final void Function(ConnectionEntity entity, String password) onSave;
  final void Function(ConnectionEntity entity, String password) onTest;

  const ConnectionForm({
    super.key,
    this.initial,
    this.initialPassword,
    required this.onSave,
    required this.onTest,
  });

  @override
  State<ConnectionForm> createState() => _ConnectionFormState();
}

class _ConnectionFormState extends State<ConnectionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _user;
  late final TextEditingController _password;
  late final TextEditingController _database;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    _name = TextEditingController(text: c?.name ?? '');
    _host = TextEditingController(text: c?.host ?? '127.0.0.1');
    _port = TextEditingController(
      text: (c?.port ?? DbConstants.defaultPort).toString(),
    );
    _user = TextEditingController(text: c?.username ?? 'root');
    _password = TextEditingController(text: widget.initialPassword ?? '');
    _database = TextEditingController(text: c?.defaultDatabase ?? '');
  }

  @override
  void dispose() {
    for (final c in [_name, _host, _port, _user, _password, _database]) {
      c.dispose();
    }
    super.dispose();
  }

  ConnectionEntity _buildEntity() {
    final existing = widget.initial;
    return ConnectionEntity(
      id: existing?.id ?? const Uuid().v4(),
      name: _name.text.trim(),
      host: _host.text.trim(),
      port: int.tryParse(_port.text) ?? DbConstants.defaultPort,
      username: _user.text.trim(),
      defaultDatabase:
          _database.text.trim().isEmpty ? null : _database.text.trim(),
      sortOrder: existing?.sortOrder ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _field(
            controller: _name,
            label: 'Connection Name',
            hint: 'e.g. Production DB',
            validator:
                (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _field(
                  controller: _host,
                  label: 'Host',
                  hint: '127.0.0.1',
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Host is required'
                              : null,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 90,
                child: _field(
                  controller: _port,
                  label: 'Port',
                  hint: '3306',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    final p = int.tryParse(v ?? '');
                    if (p == null || p < 1 || p > 65535) {
                      return 'Invalid port';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _field(
            controller: _user,
            label: 'Username',
            hint: 'root',
            validator:
                (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Username is required'
                        : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _password,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed:
                    () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _field(
            controller: _database,
            label: 'Default Database (optional)',
            hint: '',
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.network_ping, size: 16),
                label: const Text('Test Connection'),
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    widget.onTest(_buildEntity(), _password.text);
                  }
                },
              ),
              const Spacer(),
              FilledButton.icon(
                icon: const Icon(Icons.save, size: 16),
                label: const Text('Save'),
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    widget.onSave(_buildEntity(), _password.text);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
    );
  }
}
