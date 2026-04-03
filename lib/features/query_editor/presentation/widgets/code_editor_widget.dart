import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highlight/languages/sql.dart';

import '../../../../mysql/mysql_schema_fetcher.dart';
import '../../../workspace/presentation/providers/workspace_provider.dart';
import '../providers/query_editor_providers.dart';

// ── Autocomplete context ──────────────────────────────────────────────────────

enum _CtxType { dotDb, dotTable, clause, keywords }

class _AcCtx {
  final _CtxType type;
  final String? qualifier; // db or table name before the dot
  final String prefix; // what the user has typed so far after qualifier
  const _AcCtx(this.type, {this.qualifier, this.prefix = ''});
}

// ── Widget ────────────────────────────────────────────────────────────────────

class CodeEditorWidget extends ConsumerStatefulWidget {
  final String tabId;
  final String sessionId;

  const CodeEditorWidget({
    super.key,
    required this.tabId,
    required this.sessionId,
  });

  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  late final CodeController _controller;
  final _editorKey = GlobalKey();
  OverlayEntry? _autocompleteOverlay;

  // ── Schema cache ────────────────────────────────────────────────────────────
  final _fetcher = const MysqlSchemaFetcher();
  List<String> _dbNames = [];
  final Map<String, List<String>> _tablesCache = {}; // db → table names
  final Map<String, List<String>> _columnsCache = {}; // 'db.table' → col names

  // ── Popup state — read by OverlayEntry builder closure ──────────────────────
  // Storing here (not in popup widget) lets markNeedsBuild() refresh with fresh data.
  List<String> _acAllSuggestions = []; // full set for current popup context
  List<String> _acCurrentSuggestions = []; // filtered by prefix
  String _acCurrentPrefix = '';
  int _acSelectedIdx = 0;
  String _acHeaderLabel = '';
  IconData _acHeaderIcon = Icons.auto_awesome;
  double _acLeft = 0;
  double _acTop = 0;

  // ── Sync guard ──────────────────────────────────────────────────────────────
  // True while we push a value into the provider so the listener doesn't echo.
  bool _selfUpdating = false;

  @override
  void initState() {
    super.initState();
    final initialSql = ref.read(editorContentProvider(widget.tabId));
    _controller = CodeController(text: initialSql, language: sql);
    // Disable built-in flutter_code_editor popup — it returns highlight.js tokens
    // that are not clean SQL keywords.  We show our own popup instead.
    _controller.autocompleter.setCustomWords([]);
    _controller.addListener(_onChanged);
    _initSchemaCache();
  }

  /// Load database names in the background on first open.
  void _initSchemaCache() async {
    final session = ref.read(workspaceProvider)[widget.sessionId];
    if (session == null) return;
    try {
      final dbs = await _fetcher.fetchDatabases(session.mysqlConnection);
      if (!mounted) return;
      _dbNames = dbs.map((d) => d.name).toList();
    } catch (_) {}
  }

  Future<List<String>> _getTablesFor(String db) async {
    if (_tablesCache.containsKey(db)) return _tablesCache[db]!;
    final session = ref.read(workspaceProvider)[widget.sessionId];
    if (session == null) return [];
    try {
      final tables = await _fetcher.fetchTables(session.mysqlConnection, db);
      _tablesCache[db] = tables.map((t) => t.name).toList();
      return _tablesCache[db]!;
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> _getColumnsFor(String db, String table) async {
    final cacheKey = '$db.$table';
    if (_columnsCache.containsKey(cacheKey)) return _columnsCache[cacheKey]!;
    final session = ref.read(workspaceProvider)[widget.sessionId];
    if (session == null) return [];
    try {
      final cols = await _fetcher.fetchColumns(
        session.mysqlConnection,
        db,
        table,
      );
      _columnsCache[cacheKey] = cols.map((c) => c.name).toList();
      return _columnsCache[cacheKey]!;
    } catch (_) {
      return [];
    }
  }

  String? _getActiveDb() {
    final session = ref.read(workspaceProvider)[widget.sessionId];
    if (session == null) return null;
    try {
      final tab = session.tabs.firstWhere((t) => t.id == widget.tabId);
      return tab.activeDatabase;
    } catch (_) {
      return null;
    }
  }

  // ── Change listener ─────────────────────────────────────────────────────────

  void _onChanged() {
    if (_selfUpdating) return;
    final text = _controller.text;
    ref.read(editorContentProvider(widget.tabId).notifier).update(text);

    final offset = _controller.selection.baseOffset.clamp(0, text.length);

    // Dot trigger: show schema popup immediately.
    if (offset > 0 && text[offset - 1] == '.') {
      _onDotTyped(text, offset);
      return;
    }

    final word = _wordAtCursor();

    // If popup is already visible → live-filter it with the new word.
    if (_autocompleteOverlay != null) {
      if (word.isEmpty) {
        _dismissAutocomplete();
      } else {
        _updatePopupFilter(word);
      }
      return;
    }

    // Auto-show keyword popup when the user types ≥ 2 pure-alpha characters.
    if (word.length >= 2 && RegExp(r'^[a-zA-Z_]+$').hasMatch(word)) {
      _showKeywordPopup(word);
    }
  }

  /// User just typed '.': figure out the qualifier before the dot.
  void _onDotTyped(String text, int offset) {
    var i = offset - 2; // skip the dot itself
    while (i >= 0 && RegExp(r'\w').hasMatch(text[i])) {
      i--;
    }
    final qualifier = text.substring(i + 1, offset - 1);
    if (qualifier.isEmpty) {
      _dismissAutocomplete();
      return;
    }
    _showSchemaPopup(qualifier, '');
  }

  // ── Live-filter update ──────────────────────────────────────────────────────

  void _updatePopupFilter(String newPrefix) {
    final filtered =
        _acAllSuggestions
            .where((s) => s.toLowerCase().startsWith(newPrefix.toLowerCase()))
            .toList();
    if (filtered.isEmpty) {
      _dismissAutocomplete();
      return;
    }
    _acCurrentSuggestions = filtered;
    _acCurrentPrefix = newPrefix;
    _acSelectedIdx = 0;
    _autocompleteOverlay?.markNeedsBuild();
  }

  // ── Context analysis ────────────────────────────────────────────────────────

  _AcCtx _getContext() {
    final text = _controller.text;
    final offset = _controller.selection.baseOffset.clamp(0, text.length);
    final before = text.substring(0, offset);

    // 1. Dot context — qualifier.prefix
    final dotIdx = before.lastIndexOf('.');
    if (dotIdx >= 0) {
      final afterDot = before.substring(dotIdx + 1);
      if (RegExp(r'^\w*$').hasMatch(afterDot)) {
        var i = dotIdx - 1;
        while (i >= 0 && RegExp(r'\w').hasMatch(before[i])) {
          i--;
        }
        final qualifier = before.substring(i + 1, dotIdx);

        if (qualifier.isNotEmpty) {
          if (_dbNames.any((d) => d.toLowerCase() == qualifier.toLowerCase())) {
            return _AcCtx(
              _CtxType.dotDb,
              qualifier: qualifier,
              prefix: afterDot,
            );
          }
          for (final tables in _tablesCache.values) {
            if (tables.any((t) => t.toLowerCase() == qualifier.toLowerCase())) {
              return _AcCtx(
                _CtxType.dotTable,
                qualifier: qualifier,
                prefix: afterDot,
              );
            }
          }
        }
      }
    }

    // 2. SQL clause context — after FROM / JOIN / UPDATE / INTO / TABLE
    final clauseRe = RegExp(
      r'\b(?:FROM|JOIN|UPDATE|INTO|TABLE)\s+(\w*)$',
      caseSensitive: false,
    );
    final clauseMatch = clauseRe.firstMatch(before);
    if (clauseMatch != null) {
      return _AcCtx(_CtxType.clause, prefix: clauseMatch.group(1) ?? '');
    }

    // 3. Default: keyword completion on word at cursor
    return _AcCtx(_CtxType.keywords, prefix: _wordAtCursor());
  }

  // ── Popup builders ──────────────────────────────────────────────────────────

  Future<void> _showSchemaPopup(String qualifier, String prefix) async {
    _dismissAutocomplete();

    // Qualifier is a database name → show tables
    if (_dbNames.any((d) => d.toLowerCase() == qualifier.toLowerCase())) {
      final dbName = _dbNames.firstWhere(
        (d) => d.toLowerCase() == qualifier.toLowerCase(),
      );
      final tables = await _getTablesFor(dbName);
      if (!mounted) return;
      final filtered =
          prefix.isEmpty
              ? tables
              : tables
                  .where(
                    (t) => t.toLowerCase().startsWith(prefix.toLowerCase()),
                  )
                  .toList();
      if (filtered.isEmpty) return;
      _openPopup(
        allSuggestions: tables,
        suggestions: filtered,
        prefix: prefix,
        headerLabel: 'Tables in `$dbName`',
        headerIcon: Icons.table_rows_outlined,
      );
      return;
    }

    // Qualifier might be a table name → show columns
    final matchDb = await _findDbForTable(qualifier);
    if (matchDb == null || !mounted) return;
    final tableName = _tablesCache[matchDb]!.firstWhere(
      (t) => t.toLowerCase() == qualifier.toLowerCase(),
    );
    final cols = await _getColumnsFor(matchDb, tableName);
    if (!mounted) return;
    final filtered =
        prefix.isEmpty
            ? cols
            : cols
                .where((c) => c.toLowerCase().startsWith(prefix.toLowerCase()))
                .toList();
    if (filtered.isEmpty) return;
    _openPopup(
      allSuggestions: cols,
      suggestions: filtered,
      prefix: prefix,
      headerLabel: 'Columns in `$tableName`',
      headerIcon: Icons.view_column_outlined,
    );
  }

  /// Finds which cached db contains [tableName], checking the active db first.
  Future<String?> _findDbForTable(String tableName) async {
    final activeDb = _getActiveDb();
    if (activeDb != null) {
      await _getTablesFor(activeDb); // ensure cached
      if (_tablesCache[activeDb]?.any(
            (t) => t.toLowerCase() == tableName.toLowerCase(),
          ) ==
          true) {
        return activeDb;
      }
    }
    for (final entry in _tablesCache.entries) {
      if (entry.value.any((t) => t.toLowerCase() == tableName.toLowerCase())) {
        return entry.key;
      }
    }
    return null;
  }

  Future<void> _showAutocompletePopup() async {
    final ctx = _getContext();

    switch (ctx.type) {
      case _CtxType.dotDb:
        await _showSchemaPopup(ctx.qualifier!, ctx.prefix);

      case _CtxType.dotTable:
        final matchDb = await _findDbForTable(ctx.qualifier!);
        if (matchDb == null || !mounted) return;
        final tableName = _tablesCache[matchDb]!.firstWhere(
          (t) => t.toLowerCase() == ctx.qualifier!.toLowerCase(),
        );
        final cols = await _getColumnsFor(matchDb, tableName);
        if (!mounted) return;
        final filtered =
            ctx.prefix.isEmpty
                ? cols
                : cols
                    .where(
                      (c) =>
                          c.toLowerCase().startsWith(ctx.prefix.toLowerCase()),
                    )
                    .toList();
        if (filtered.isEmpty) return;
        _openPopup(
          allSuggestions: cols,
          suggestions: filtered,
          prefix: ctx.prefix,
          headerLabel: 'Columns in `$tableName`',
          headerIcon: Icons.view_column_outlined,
        );

      case _CtxType.clause:
        // Build list: db names + db.table pairs + bare table names from active db.
        final items = <String>[];
        for (final db in _dbNames) {
          items.add(db);
          final tables = _tablesCache[db] ?? [];
          for (final t in tables) {
            items.add('$db.$t');
          }
        }
        final activeDb = _getActiveDb();
        if (activeDb != null) {
          final tables = await _getTablesFor(activeDb);
          for (final t in tables) {
            if (!items.contains(t)) {
              items.add(t);
            }
          }
        }
        if (!mounted) return;
        final filtered =
            ctx.prefix.isEmpty
                ? items
                : items
                    .where(
                      (s) =>
                          s.toLowerCase().startsWith(ctx.prefix.toLowerCase()),
                    )
                    .toList();
        if (filtered.isNotEmpty) {
          _openPopup(
            allSuggestions: items,
            suggestions: filtered,
            prefix: ctx.prefix,
            headerLabel: 'Databases & Tables',
            headerIcon: Icons.storage_outlined,
          );
        } else {
          _showKeywordPopup(ctx.prefix);
        }

      case _CtxType.keywords:
        _showKeywordPopup(ctx.prefix);
    }
  }

  /// Shows keyword suggestions filtered from our curated [_sqlKeywords] list.
  /// Does NOT call flutter_code_editor's autocompleter — that returns weird tokens.
  void _showKeywordPopup(String prefix) {
    final suggestions =
        prefix.isEmpty
            ? List<String>.from(_sqlKeywords)
            : _sqlKeywords
                .where((k) => k.toLowerCase().startsWith(prefix.toLowerCase()))
                .toList();
    if (suggestions.isEmpty) return;
    _openPopup(
      allSuggestions: _sqlKeywords,
      suggestions: suggestions,
      prefix: prefix,
      headerLabel: 'SQL Keywords',
      headerIcon: Icons.auto_awesome,
    );
  }

  void _openPopup({
    required List<String> allSuggestions,
    required List<String> suggestions,
    required String prefix,
    required String headerLabel,
    required IconData headerIcon,
  }) {
    if (!mounted || suggestions.isEmpty) return;

    final box = _editorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final globalPos = box.localToGlobal(Offset.zero);

    // Update shared popup state — the OverlayEntry builder closure reads these.
    _acAllSuggestions = allSuggestions;
    _acCurrentSuggestions = suggestions;
    _acCurrentPrefix = prefix;
    _acSelectedIdx = 0;
    _acHeaderLabel = headerLabel;
    _acHeaderIcon = headerIcon;
    _acLeft = globalPos.dx + 48;
    _acTop = globalPos.dy + 36;

    // If the popup is already open, just refresh it in-place.
    if (_autocompleteOverlay != null) {
      _autocompleteOverlay!.markNeedsBuild();
      return;
    }

    // Create and insert the overlay.  The builder closure captures `this` so
    // every markNeedsBuild() call reads the latest _ac* values.
    _autocompleteOverlay = OverlayEntry(
      builder:
          (_) => _AutocompletePopup(
            left: _acLeft,
            top: _acTop,
            suggestions: _acCurrentSuggestions,
            selectedIdx: _acSelectedIdx,
            prefix: _acCurrentPrefix,
            headerLabel: _acHeaderLabel,
            headerIcon: _acHeaderIcon,
            onSelect: (p, word) {
              _insertCompletion(p, word);
              _dismissAutocomplete();
            },
            onDismiss: _dismissAutocomplete,
          ),
    );
    Overlay.of(context, rootOverlay: true).insert(_autocompleteOverlay!);
  }

  // ── Editor helpers ──────────────────────────────────────────────────────────

  /// Returns the identifier word immediately before the cursor.
  String _wordAtCursor() {
    final text = _controller.text;
    final offset = _controller.selection.baseOffset.clamp(0, text.length);
    var start = offset;
    while (start > 0 && RegExp(r'[a-zA-Z_0-9]').hasMatch(text[start - 1])) {
      start--;
    }
    return text.substring(start, offset);
  }

  /// Replaces [prefix] immediately before the cursor with [word].
  void _insertCompletion(String prefix, String word) {
    final text = _controller.text;
    final offset = _controller.selection.baseOffset.clamp(0, text.length);
    final start = (offset - prefix.length).clamp(0, text.length);
    final newText = text.replaceRange(start, offset, word);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + word.length),
    );
  }

  void _dismissAutocomplete() {
    _autocompleteOverlay?.remove();
    _autocompleteOverlay = null;
  }

  @override
  void dispose() {
    _dismissAutocomplete();
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Sync external writes (e.g. "Select Top 1000") back into the CodeController.
    ref.listen(editorContentProvider(widget.tabId), (_, next) {
      if (_controller.text != next) {
        _selfUpdating = true;
        _controller.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
        _selfUpdating = false;
      }
    });

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Focus(
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;

        // Ctrl+Space → show / hide autocomplete
        if (event.logicalKey == LogicalKeyboardKey.space &&
            HardwareKeyboard.instance.isControlPressed) {
          if (_autocompleteOverlay != null) {
            _dismissAutocomplete();
          } else {
            _showAutocompletePopup();
          }
          return KeyEventResult.handled;
        }

        // When the popup is visible, intercept navigation keys.
        // All other keys fall through to the editor; _onChanged() updates the filter.
        if (_autocompleteOverlay != null) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            _dismissAutocomplete();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _acSelectedIdx = (_acSelectedIdx + 1).clamp(
              0,
              _acCurrentSuggestions.length - 1,
            );
            _autocompleteOverlay?.markNeedsBuild();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _acSelectedIdx = (_acSelectedIdx - 1).clamp(
              0,
              _acCurrentSuggestions.length - 1,
            );
            _autocompleteOverlay?.markNeedsBuild();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.tab) {
            if (_acCurrentSuggestions.isNotEmpty) {
              _insertCompletion(
                _acCurrentPrefix,
                _acCurrentSuggestions[_acSelectedIdx],
              );
              _dismissAutocomplete();
              return KeyEventResult.handled;
            }
          }
          // Any other key: pass through so the editor receives it.
          // _onChanged() will live-filter or dismiss as appropriate.
          return KeyEventResult.ignored;
        }

        return KeyEventResult.ignored;
      },
      child: CodeTheme(
        data: CodeThemeData(styles: isDark ? _darkStyles : _lightStyles),
        child: SingleChildScrollView(
          child: Container(
            key: _editorKey,
            child: CodeField(
              controller: _controller,
              textStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13.5,
                height: 1.5,
              ),
              background:
                  isDark ? const Color(0xFF1E1E1E) : theme.colorScheme.surface,
              minLines: 10,
            ),
          ),
        ),
      ),
    );
  }

  // ── SQL keyword list ──────────────────────────────────────────────────────

  static const List<String> _sqlKeywords = [
    'SELECT',
    'INSERT',
    'UPDATE',
    'DELETE',
    'REPLACE',
    'MERGE',
    'CREATE',
    'ALTER',
    'DROP',
    'TRUNCATE',
    'RENAME',
    'GRANT',
    'REVOKE',
    'BEGIN',
    'START',
    'TRANSACTION',
    'COMMIT',
    'ROLLBACK',
    'SAVEPOINT',
    'FROM',
    'WHERE',
    'HAVING',
    'GROUP',
    'ORDER',
    'BY',
    'LIMIT',
    'OFFSET',
    'JOIN',
    'INNER',
    'LEFT',
    'RIGHT',
    'OUTER',
    'CROSS',
    'FULL',
    'ON',
    'UNION',
    'INTERSECT',
    'EXCEPT',
    'ALL',
    'DISTINCT',
    'INTO',
    'VALUES',
    'SET',
    'AS',
    'WITH',
    'RECURSIVE',
    'AND',
    'OR',
    'NOT',
    'IN',
    'EXISTS',
    'BETWEEN',
    'LIKE',
    'RLIKE',
    'IS',
    'NULL',
    'CASE',
    'WHEN',
    'THEN',
    'ELSE',
    'END',
    'IF',
    'IFNULL',
    'NULLIF',
    'COALESCE',
    'ISNULL',
    'COUNT',
    'SUM',
    'AVG',
    'MIN',
    'MAX',
    'GROUP_CONCAT',
    'CONCAT',
    'CONCAT_WS',
    'SUBSTRING',
    'SUBSTR',
    'LENGTH',
    'CHAR_LENGTH',
    'UPPER',
    'LOWER',
    'LTRIM',
    'RTRIM',
    'TRIM',
    'REPLACE',
    'INSTR',
    'LPAD',
    'RPAD',
    'REPEAT',
    'REVERSE',
    'FORMAT',
    'ABS',
    'CEILING',
    'FLOOR',
    'ROUND',
    'MOD',
    'POWER',
    'SQRT',
    'RAND',
    'NOW',
    'CURDATE',
    'CURTIME',
    'CURRENT_TIMESTAMP',
    'CURRENT_DATE',
    'DATE',
    'TIME',
    'YEAR',
    'MONTH',
    'DAY',
    'HOUR',
    'MINUTE',
    'SECOND',
    'DATE_FORMAT',
    'STR_TO_DATE',
    'DATE_ADD',
    'DATE_SUB',
    'DATEDIFF',
    'UNIX_TIMESTAMP',
    'FROM_UNIXTIME',
    'CAST',
    'CONVERT',
    'TABLE',
    'VIEW',
    'INDEX',
    'DATABASE',
    'SCHEMA',
    'COLUMN',
    'CONSTRAINT',
    'PROCEDURE',
    'FUNCTION',
    'TRIGGER',
    'EVENT',
    'PRIMARY',
    'KEY',
    'FOREIGN',
    'REFERENCES',
    'UNIQUE',
    'DEFAULT',
    'AUTO_INCREMENT',
    'INT',
    'INTEGER',
    'BIGINT',
    'SMALLINT',
    'TINYINT',
    'MEDIUMINT',
    'DECIMAL',
    'NUMERIC',
    'FLOAT',
    'DOUBLE',
    'VARCHAR',
    'CHAR',
    'TEXT',
    'LONGTEXT',
    'MEDIUMTEXT',
    'TINYTEXT',
    'BLOB',
    'LONGBLOB',
    'MEDIUMBLOB',
    'DATETIME',
    'TIMESTAMP',
    'BOOL',
    'BOOLEAN',
    'ENUM',
    'JSON',
    'SHOW',
    'DESCRIBE',
    'EXPLAIN',
    'USE',
    'DATABASES',
    'TABLES',
    'COLUMNS',
    'ENGINE',
    'CHARSET',
    'COLLATE',
    'CHARACTER',
    'IGNORE',
    'FORCE',
    'LOCK',
    'UNLOCK',
    'CALL',
  ];

  // ── Syntax highlight themes ───────────────────────────────────────────────

  static const Map<String, TextStyle> _darkStyles = {
    'root': TextStyle(
      backgroundColor: Color(0xFF1E1E1E),
      color: Color(0xFFD4D4D4),
    ),
    'keyword': TextStyle(color: Color(0xFF569CD6), fontWeight: FontWeight.w600),
    'string': TextStyle(color: Color(0xFFCE9178)),
    'comment': TextStyle(color: Color(0xFF6A9955), fontStyle: FontStyle.italic),
    'number': TextStyle(color: Color(0xFFB5CEA8)),
    'built_in': TextStyle(color: Color(0xFFDCDCAA)),
  };

  static const Map<String, TextStyle> _lightStyles = {
    'root': TextStyle(
      backgroundColor: Color(0xFFFCFCFC),
      color: Color(0xFF1F1F1F),
    ),
    'keyword': TextStyle(color: Color(0xFF0000FF), fontWeight: FontWeight.w600),
    'string': TextStyle(color: Color(0xFFA31515)),
    'comment': TextStyle(color: Color(0xFF008000), fontStyle: FontStyle.italic),
    'number': TextStyle(color: Color(0xFF098658)),
    'built_in': TextStyle(color: Color(0xFF795E26)),
  };
}

// ── Autocomplete popup ────────────────────────────────────────────────────────
// Pure display widget — no FocusNode, no keyboard handling.
// All navigation (↑↓ Enter Tab Esc) is handled in the editor's Focus.onKeyEvent.
// The editor's Focus keeps keyboard focus while the popup is visible.

class _AutocompletePopup extends StatefulWidget {
  final double left;
  final double top;
  final List<String> suggestions;
  final int selectedIdx;
  final String prefix;
  final String headerLabel;
  final IconData headerIcon;
  final void Function(String prefix, String word) onSelect;
  final VoidCallback onDismiss;

  const _AutocompletePopup({
    required this.left,
    required this.top,
    required this.suggestions,
    required this.selectedIdx,
    required this.prefix,
    required this.headerLabel,
    required this.headerIcon,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  State<_AutocompletePopup> createState() => _AutocompletePopupState();
}

class _AutocompletePopupState extends State<_AutocompletePopup> {
  final _scrollCtrl = ScrollController();
  static const _itemHeight = 28.0;

  @override
  void didUpdateWidget(_AutocompletePopup old) {
    super.didUpdateWidget(old);
    // Auto-scroll to selected item whenever selection or list changes.
    if (old.selectedIdx != widget.selectedIdx ||
        old.suggestions != widget.suggestions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollCtrl.hasClients) return;
        final target = widget.selectedIdx * _itemHeight;
        _scrollCtrl.animateTo(
          target.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Stack(
      children: [
        // Transparent barrier — tap anywhere outside popup to dismiss.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onDismiss,
            child: const SizedBox.expand(),
          ),
        ),
        // Popup card
        Positioned(
          left: widget.left,
          top: widget.top,
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(6),
            shadowColor: Colors.black.withAlpha(80),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300, maxHeight: 260),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: cs.outlineVariant),
                color: cs.surface,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(widget.headerIcon, size: 11, color: cs.primary),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            widget.headerLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '↑↓  Tab / ↵',
                          style: TextStyle(
                            fontSize: 9,
                            color: cs.onSurface.withAlpha(100),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Item list
                  Flexible(
                    child: ListView.builder(
                      controller: _scrollCtrl,
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      itemCount: widget.suggestions.length,
                      itemExtent: _itemHeight,
                      itemBuilder: (ctx, i) {
                        final word = widget.suggestions[i];
                        final isSelected = i == widget.selectedIdx;
                        final prefixLen = widget.prefix.length.clamp(
                          0,
                          word.length,
                        );

                        return InkWell(
                          onTap: () => widget.onSelect(widget.prefix, word),
                          child: Container(
                            color:
                                isSelected
                                    ? cs.primaryContainer
                                    : Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            alignment: Alignment.centerLeft,
                            child: RichText(
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                children: [
                                  // Bold-highlight the matched prefix
                                  if (prefixLen > 0)
                                    TextSpan(
                                      text: word.substring(0, prefixLen),
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: cs.primary,
                                      ),
                                    ),
                                  // Rest of the word
                                  TextSpan(
                                    text: word.substring(prefixLen),
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color:
                                          isSelected
                                              ? cs.onPrimaryContainer
                                              : cs.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
