import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

import '../../../../mysql/mysql_query_executor.dart';
import '../../../workspace/domain/entities/workspace_session.dart';

/// Dialog that lets the user paste CSV text and import it into a table.
class ImportCsvDialog extends StatefulWidget {
  final WorkspaceSession session;
  final String database;
  final String table;

  const ImportCsvDialog({
    super.key,
    required this.session,
    required this.database,
    required this.table,
  });

  /// Opens the dialog and returns the number of rows imported, or null if cancelled.
  static Future<int?> show(
    BuildContext context, {
    required WorkspaceSession session,
    required String database,
    required String table,
  }) {
    return showDialog<int>(
      context: context,
      builder:
          (_) => ImportCsvDialog(
            session: session,
            database: database,
            table: table,
          ),
    );
  }

  @override
  State<ImportCsvDialog> createState() => _ImportCsvDialogState();
}

class _ImportCsvDialogState extends State<ImportCsvDialog> {
  final _csvCtrl = TextEditingController();
  final _executor = const MysqlQueryExecutor();

  bool _hasHeader = true;
  List<String> _parsedHeaders = [];
  List<List<String>> _parsedRows = [];
  bool _importing = false;
  String? _parseError;

  @override
  void dispose() {
    _csvCtrl.dispose();
    super.dispose();
  }

  // ── CSV parser ─────────────────────────────────────────────────────────────

  void _parse() {
    final text = _csvCtrl.text.trim();
    if (text.isEmpty) {
      setState(() {
        _parsedHeaders = [];
        _parsedRows = [];
        _parseError = null;
      });
      return;
    }
    try {
      final lines = _splitLines(text);
      final all = lines.map(_parseCsvLine).toList();
      if (all.isEmpty) {
        setState(() {
          _parsedHeaders = [];
          _parsedRows = [];
          _parseError = 'No data found';
        });
        return;
      }
      setState(() {
        _parseError = null;
        if (_hasHeader) {
          _parsedHeaders = all.first;
          _parsedRows = all.skip(1).toList();
        } else {
          _parsedHeaders = List.generate(
            all.first.length,
            (i) => 'col${i + 1}',
          );
          _parsedRows = all;
        }
      });
    } catch (e) {
      setState(() => _parseError = e.toString());
    }
  }

  /// Splits text into non-empty lines.
  List<String> _splitLines(String text) =>
      text
          .split('\n')
          .map((l) => l.trimRight())
          .where((l) => l.isNotEmpty)
          .toList();

  /// Parses a single CSV line respecting double-quoted fields.
  List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        fields.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    fields.add(buf.toString());
    return fields;
  }

  // ── Import ─────────────────────────────────────────────────────────────────

  Future<void> _import() async {
    if (_parsedRows.isEmpty) return;
    setState(() => _importing = true);

    final db = widget.database;
    final tbl = widget.table;
    final cols = _parsedHeaders.map((h) => '`$h`').join(', ');
    int done = 0, failed = 0;

    for (final row in _parsedRows) {
      final vals = row
          .map((v) {
            if (v.isEmpty || v.toUpperCase() == 'NULL') return 'NULL';
            return "'${v.replaceAll("'", "''")}'";
          })
          .join(', ');
      final sql = 'INSERT INTO `$db`.`$tbl` ($cols) VALUES ($vals)';
      try {
        final result = await _executor.execute(
          widget.session.mysqlConnection,
          sql,
        );
        if (result.isError) {
          failed++;
        } else {
          done++;
        }
      } catch (_) {
        failed++;
      }
    }

    if (!mounted) return;
    setState(() => _importing = false);

    BotToast.showSimpleNotification(
      title: failed == 0 ? '✓ Import complete' : 'Partial import',
      subTitle: '$done inserted${failed > 0 ? ', $failed failed' : ''}',
    );

    Navigator.of(context).pop(done);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasData = _parsedRows.isNotEmpty;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 620),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: cs.surfaceContainerHighest,
              child: Row(
                children: [
                  const Icon(Icons.upload_file_outlined, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Import CSV → `${widget.database}`.`${widget.table}`',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Options row
                    Row(
                      children: [
                        Checkbox(
                          value: _hasHeader,
                          onChanged: (v) {
                            setState(() => _hasHeader = v ?? true);
                            if (_csvCtrl.text.isNotEmpty) _parse();
                          },
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        const Text(
                          'First row is header',
                          style: TextStyle(fontSize: 12),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.play_arrow, size: 14),
                          label: const Text(
                            'Parse',
                            style: TextStyle(fontSize: 12),
                          ),
                          onPressed: _parse,
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // CSV input
                    SizedBox(
                      height: 140,
                      child: TextField(
                        controller: _csvCtrl,
                        maxLines: null,
                        expands: true,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Paste CSV here…\n'
                              'e.g.:\nid,name,email\n1,Alice,alice@example.com',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          contentPadding: const EdgeInsets.all(8),
                          errorText: _parseError,
                        ),
                        onChanged: (_) {
                          // Auto-parse after user stops typing
                          if (_csvCtrl.text.contains('\n')) _parse();
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Preview
                    if (_parsedHeaders.isNotEmpty) ...[
                      Text(
                        'Preview — ${_parsedRows.length} row${_parsedRows.length == 1 ? '' : 's'} detected',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: cs.outlineVariant),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: SingleChildScrollView(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columnSpacing: 12,
                                headingRowHeight: 28,
                                dataRowMinHeight: 26,
                                dataRowMaxHeight: 26,
                                headingRowColor: WidgetStateProperty.all(
                                  cs.surfaceContainerHighest,
                                ),
                                columns:
                                    _parsedHeaders
                                        .map(
                                          (h) => DataColumn(
                                            label: Text(
                                              h,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                rows:
                                    _parsedRows
                                        .take(5)
                                        .map(
                                          (row) => DataRow(
                                            cells: List.generate(
                                              _parsedHeaders.length,
                                              (i) => DataCell(
                                                Text(
                                                  i < row.length ? row[i] : '',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      const Expanded(child: SizedBox.shrink()),
                    ],
                  ],
                ),
              ),
            ),

            // Action bar
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  if (hasData)
                    Text(
                      '${_parsedRows.length} rows will be inserted',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    icon:
                        _importing
                            ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.upload, size: 15),
                    label: Text(_importing ? 'Importing…' : 'Import'),
                    onPressed: (!hasData || _importing) ? null : _import,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
