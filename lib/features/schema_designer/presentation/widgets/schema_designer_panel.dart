import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../../../mysql/mysql_schema_fetcher.dart';
import '../../../workspace/domain/entities/workspace_session.dart';

/// A table entry in the ERD — may belong to a different db (cross-db FK pull).
class _ErdTable {
  final String db;
  final String name;

  /// True when this table was pulled in automatically via a cross-db FK.
  final bool isCrossDb;
  _ErdTable(this.db, this.name, {this.isCrossDb = false});

  /// Qualified key used as the position/column map key.
  String get key => '$db.$name';

  /// Label shown in the card header.
  String get displayName => isCrossDb ? '$db.$name' : name;
}

// ─────────────────────────────────────────────────────────────────────────────

class SchemaDesignerPanel extends StatefulWidget {
  final WorkspaceSession session;
  const SchemaDesignerPanel({super.key, required this.session});

  @override
  State<SchemaDesignerPanel> createState() => _SchemaDesignerPanelState();
}

class _SchemaDesignerPanelState extends State<SchemaDesignerPanel> {
  final _fetcher = const MysqlSchemaFetcher();
  final _repaintKey = GlobalKey();

  // ── Picker state ──────────────────────────────────────────────────────────
  List<String> _databases = [];
  String? _selectedDb;

  // ── Canvas data ───────────────────────────────────────────────────────────
  /// All tables loaded (primary db + any cross-db FK tables).
  List<_ErdTable> _tables = [];
  Map<String, List<ColumnInfo>> _columns = {}; // key → cols
  List<ForeignKeyInfo> _foreignKeys = [];
  bool _loading = false;

  /// Which table keys are currently visible on the canvas.
  Set<String> _visibleKeys = {};

  // ── Canvas transform ──────────────────────────────────────────────────────
  double _scale = 1.0;
  Offset _offset = const Offset(24, 24);
  Offset _lastFocalPoint = Offset.zero;
  double _prevScaleGesture = 1.0;
  final Map<String, Offset> _positions = {};

  // ── Layout constants ──────────────────────────────────────────────────────
  static const double _cardWidth = 200.0;
  static const double _cardHeaderH = 30.0;
  static const double _cardRowH = 20.0;
  static const double _colGap = 230.0;
  static const double _rowGap = 40.0;

  // ── Sidebar toggle ────────────────────────────────────────────────────────
  bool _showSidebar = true;

  @override
  void initState() {
    super.initState();
    _loadDatabases();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadDatabases() async {
    try {
      final dbs = await _fetcher.fetchAllDatabases(
        widget.session.mysqlConnection,
      );
      if (!mounted) return;
      setState(() => _databases = dbs.map((d) => d.name).toList());
    } catch (_) {}
  }

  Future<void> _loadSchema(String db) async {
    setState(() => _loading = true);
    try {
      final tables = await _fetcher.fetchTables(
        widget.session.mysqlConnection,
        db,
      );
      final baseTables = tables.where((t) => !t.isView).toList();

      // Fetch columns + FK for primary db
      final cols = <String, List<ColumnInfo>>{};
      for (final t in baseTables) {
        final key = '$db.${t.name}';
        cols[key] = await _fetcher.fetchColumns(
          widget.session.mysqlConnection,
          db,
          t.name,
        );
      }

      final fks = await _fetcher.fetchForeignKeys(
        widget.session.mysqlConnection,
        db,
      );

      // Build ErdTable list for primary db
      final erdTables = baseTables.map((t) => _ErdTable(db, t.name)).toList();

      // ── Cross-db FK tables ─────────────────────────────────────────────
      // For every FK that points to a different db, auto-load that table too.
      final crossDbKeys = <String>{};
      final crossDbFks = fks.where((fk) => fk.refDatabase.isNotEmpty).toList();

      for (final fk in crossDbFks) {
        final crossKey = '${fk.refDatabase}.${fk.refTable}';
        if (crossDbKeys.contains(crossKey)) continue;
        crossDbKeys.add(crossKey);

        try {
          final crossCols = await _fetcher.fetchColumns(
            widget.session.mysqlConnection,
            fk.refDatabase,
            fk.refTable,
          );
          cols[crossKey] = crossCols;
          erdTables.add(
            _ErdTable(fk.refDatabase, fk.refTable, isCrossDb: true),
          );
        } catch (_) {}
      }

      // ── Layout positions (4-column grid) ──────────────────────────────
      final positions = <String, Offset>{};
      for (var i = 0; i < erdTables.length; i++) {
        final colIdx = i % 4;
        positions[erdTables[i].key] = Offset(
          colIdx * _colGap,
          _rowForIndex(i, erdTables, cols),
        );
      }

      if (!mounted) return;
      setState(() {
        _tables = erdTables;
        _columns = cols;
        _foreignKeys = fks;
        _positions
          ..clear()
          ..addAll(positions);
        // All tables visible by default
        _visibleKeys = erdTables.map((t) => t.key).toSet();
        _loading = false;
        _scale = 1.0;
        _offset = const Offset(24, 24);
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _rowForIndex(
    int i,
    List<_ErdTable> tables,
    Map<String, List<ColumnInfo>> cols,
  ) {
    if (i < 4) return 0;
    double y = 0;
    final colIdx = i % 4;
    for (var j = colIdx; j < i; j += 4) {
      final cardH =
          _cardHeaderH + (cols[tables[j].key]?.length ?? 5) * _cardRowH + 8;
      y += cardH + _rowGap;
    }
    return y;
  }

  // ── Gesture handlers ──────────────────────────────────────────────────────

  void _onScaleStart(ScaleStartDetails d) {
    _lastFocalPoint = d.focalPoint;
    _prevScaleGesture = 1.0;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    setState(() {
      final scaleDelta = d.scale / _prevScaleGesture;
      _prevScaleGesture = d.scale;
      final panDelta = d.focalPoint - _lastFocalPoint;
      _lastFocalPoint = d.focalPoint;
      _offset += panDelta;
      if ((scaleDelta - 1.0).abs() > 0.001) {
        final newScale = (_scale * scaleDelta).clamp(0.15, 4.0);
        final focalInCanvas = (d.focalPoint - _offset) / _scale;
        _scale = newScale;
        _offset = d.focalPoint - focalInCanvas * _scale;
      }
    });
  }

  void _moveCard(String key, Offset screenDelta) {
    setState(() {
      _positions[key] = (_positions[key] ?? Offset.zero) + screenDelta / _scale;
    });
  }

  void _zoomBy(double factor) {
    setState(() {
      final center = Offset(
        MediaQuery.sizeOf(context).width / 2,
        MediaQuery.sizeOf(context).height / 2,
      );
      final newScale = (_scale * factor).clamp(0.15, 4.0);
      final focalInCanvas = (center - _offset) / _scale;
      _scale = newScale;
      _offset = center - focalInCanvas * _scale;
    });
  }

  void _resetView() => setState(() {
    _scale = 1.0;
    _offset = const Offset(24, 24);
  });

  void _fitAll() {
    final visible = _tables.where((t) => _visibleKeys.contains(t.key)).toList();
    if (visible.isEmpty) return;
    setState(() {
      double minX = double.infinity, minY = double.infinity;
      double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
      for (final t in visible) {
        final pos = _positions[t.key] ?? Offset.zero;
        if (pos.dx < minX) minX = pos.dx;
        if (pos.dy < minY) minY = pos.dy;
        if (pos.dx + _cardWidth > maxX) maxX = pos.dx + _cardWidth;
        if (pos.dy + 200 > maxY) maxY = pos.dy + 200;
      }
      final canvasW = maxX - minX + 80;
      final canvasH = maxY - minY + 80;
      final viewW = MediaQuery.sizeOf(context).width * 0.75;
      final viewH = MediaQuery.sizeOf(context).height * 0.75;
      _scale = (viewW / canvasW).clamp(0.15, 1.5);
      if (viewH / canvasH < _scale) {
        _scale = (viewH / canvasH).clamp(0.15, 1.5);
      }
      _offset = Offset(-minX * _scale + 40, -minY * _scale + 40);
    });
  }

  Future<void> _exportPng() async {
    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      await Clipboard.setData(
        ClipboardData(text: '[PNG ${bytes.length} bytes]'),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ER Diagram exported (${bytes.length ~/ 1024} KB)'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Tables actually shown on canvas
    final visibleTables =
        _tables.where((t) => _visibleKeys.contains(t.key)).toList();

    return Column(
      children: [
        // ── Toolbar ──────────────────────────────────────────────────────────
        Container(
          height: 36,
          color: cs.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const Icon(Icons.schema_outlined, size: 15),
              const SizedBox(width: 6),
              const Text(
                'Schema Designer',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              const SizedBox(width: 12),
              const VerticalDivider(width: 1, indent: 6, endIndent: 6),
              const SizedBox(width: 8),
              const Text('Database:', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDb,
                    hint: const Text('Select…', style: TextStyle(fontSize: 11)),
                    isDense: true,
                    isExpanded: true,
                    style: const TextStyle(fontSize: 11),
                    items:
                        _databases
                            .map(
                              (db) => DropdownMenuItem(
                                value: db,
                                child: Text(
                                  db,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _selectedDb = v);
                      _loadSchema(v);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Sidebar toggle
              _ToolbarIconBtn(
                icon: _showSidebar ? Icons.list_alt_outlined : Icons.list_alt,
                tooltip: _showSidebar ? 'Hide table list' : 'Show table list',
                onTap: () => setState(() => _showSidebar = !_showSidebar),
              ),
              const Spacer(),
              if (_tables.isNotEmpty) ...[
                Text(
                  '${visibleTables.length}/${_tables.length} tables  ·  ${_foreignKeys.length} FK',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                const VerticalDivider(width: 1, indent: 6, endIndent: 6),
                const SizedBox(width: 4),
              ],
              Text(
                '${(_scale * 100).round()}%',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 2),
              _ToolbarIconBtn(
                icon: Icons.remove,
                tooltip: 'Zoom out',
                onTap: () => _zoomBy(0.8),
              ),
              _ToolbarIconBtn(
                icon: Icons.add,
                tooltip: 'Zoom in',
                onTap: () => _zoomBy(1.25),
              ),
              _ToolbarIconBtn(
                icon: Icons.fit_screen,
                tooltip: 'Reset view',
                onTap: _resetView,
              ),
              _ToolbarIconBtn(
                icon: Icons.zoom_out_map,
                tooltip: 'Fit all',
                onTap: _fitAll,
              ),
              const VerticalDivider(width: 1, indent: 6, endIndent: 6),
              const SizedBox(width: 4),
              _ToolbarIconBtn(
                icon: Icons.image_outlined,
                tooltip: 'Export PNG',
                onTap: _tables.isEmpty ? null : _exportPng,
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),

        const Divider(height: 1),

        // ── Body: optional sidebar + canvas ──────────────────────────────────
        Expanded(
          child:
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedDb == null
                  ? _EmptyHint(cs: cs)
                  : _tables.isEmpty
                  ? Center(
                    child: Text(
                      'No tables found in `$_selectedDb`',
                      style: TextStyle(
                        color: cs.onSurface.withAlpha(120),
                        fontSize: 13,
                      ),
                    ),
                  )
                  : Row(
                    children: [
                      // ── Table visibility sidebar ─────────────────────
                      if (_showSidebar)
                        _TableSidebar(
                          tables: _tables,
                          visibleKeys: _visibleKeys,
                          onToggle:
                              (key) => setState(
                                () =>
                                    _visibleKeys.contains(key)
                                        ? _visibleKeys.remove(key)
                                        : _visibleKeys.add(key),
                              ),
                          onShowAll:
                              () => setState(
                                () =>
                                    _visibleKeys =
                                        _tables.map((t) => t.key).toSet(),
                              ),
                          onHideAll: () => setState(() => _visibleKeys.clear()),
                        ),
                      if (_showSidebar) const VerticalDivider(width: 1),
                      // ── ERD canvas ───────────────────────────────────
                      Expanded(
                        child: _ErdCanvas(
                          repaintKey: _repaintKey,
                          scale: _scale,
                          offset: _offset,
                          tables: visibleTables,
                          columns: _columns,
                          foreignKeys: _foreignKeys,
                          positions: _positions,
                          onScaleStart: _onScaleStart,
                          onScaleUpdate: _onScaleUpdate,
                          onCardDrag: _moveCard,
                          cardWidth: _cardWidth,
                          cardHeaderH: _cardHeaderH,
                          cardRowH: _cardRowH,
                        ),
                      ),
                    ],
                  ),
        ),
      ],
    );
  }
}

// ── Table visibility sidebar ──────────────────────────────────────────────────

class _TableSidebar extends StatelessWidget {
  final List<_ErdTable> tables;
  final Set<String> visibleKeys;
  final void Function(String key) onToggle;
  final VoidCallback onShowAll;
  final VoidCallback onHideAll;

  const _TableSidebar({
    required this.tables,
    required this.visibleKeys,
    required this.onToggle,
    required this.onShowAll,
    required this.onHideAll,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Group by db for display
    final primaryTables = tables.where((t) => !t.isCrossDb).toList();
    final crossTables = tables.where((t) => t.isCrossDb).toList();

    return SizedBox(
      width: 190,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header + all/none buttons
          Container(
            height: 30,
            color: cs.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const Icon(Icons.table_rows_outlined, size: 13),
                const SizedBox(width: 5),
                const Expanded(
                  child: Text(
                    'Tables',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ),
                InkWell(
                  onTap: onShowAll,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'All',
                      style: TextStyle(fontSize: 10, color: Colors.blueAccent),
                    ),
                  ),
                ),
                const Text(
                  '·',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                InkWell(
                  onTap: onHideAll,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'None',
                      style: TextStyle(fontSize: 10, color: Colors.blueAccent),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Table list
          Expanded(
            child: ListView(
              children: [
                if (primaryTables.isNotEmpty)
                  _SidebarSection(
                    label: primaryTables.first.db,
                    tables: primaryTables,
                    visibleKeys: visibleKeys,
                    onToggle: onToggle,
                    cs: cs,
                    isCrossDb: false,
                  ),
                if (crossTables.isNotEmpty) ...[
                  const Divider(height: 8, indent: 8, endIndent: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    child: Text(
                      'Cross-DB References',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface.withAlpha(120),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  _SidebarSection(
                    label: '',
                    tables: crossTables,
                    visibleKeys: visibleKeys,
                    onToggle: onToggle,
                    cs: cs,
                    isCrossDb: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  final String label;
  final List<_ErdTable> tables;
  final Set<String> visibleKeys;
  final void Function(String) onToggle;
  final ColorScheme cs;
  final bool isCrossDb;

  const _SidebarSection({
    required this.label,
    required this.tables,
    required this.visibleKeys,
    required this.onToggle,
    required this.cs,
    required this.isCrossDb,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: cs.primary.withAlpha(180),
                letterSpacing: 0.6,
              ),
            ),
          ),
        ...tables.map((t) {
          final visible = visibleKeys.contains(t.key);
          return InkWell(
            onTap: () => onToggle(t.key),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    visible
                        ? Icons.check_box_outlined
                        : Icons.check_box_outline_blank,
                    size: 13,
                    color: visible ? cs.primary : cs.onSurface.withAlpha(100),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      t.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: isCrossDb ? Colors.teal.shade600 : cs.onSurface,
                        decoration:
                            visible
                                ? TextDecoration.none
                                : TextDecoration.lineThrough,
                        decorationColor: cs.onSurface.withAlpha(80),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── ERD Canvas ────────────────────────────────────────────────────────────────

class _ErdCanvas extends StatelessWidget {
  final GlobalKey repaintKey;
  final double scale;
  final Offset offset;
  final List<_ErdTable> tables;
  final Map<String, List<ColumnInfo>> columns;
  final List<ForeignKeyInfo> foreignKeys;
  final Map<String, Offset> positions;
  final void Function(ScaleStartDetails) onScaleStart;
  final void Function(ScaleUpdateDetails) onScaleUpdate;
  final void Function(String, Offset) onCardDrag;
  final double cardWidth;
  final double cardHeaderH;
  final double cardRowH;

  const _ErdCanvas({
    required this.repaintKey,
    required this.scale,
    required this.offset,
    required this.tables,
    required this.columns,
    required this.foreignKeys,
    required this.positions,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onCardDrag,
    required this.cardWidth,
    required this.cardHeaderH,
    required this.cardRowH,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Only draw FK lines between tables that are both visible
    final visibleKeys = tables.map((t) => t.key).toSet();
    final visibleFks =
        foreignKeys.where((fk) {
          final srcKey = '${_selectedDb(fk, tables)}.${fk.table}';
          final tgtKey =
              fk.refDatabase.isNotEmpty
                  ? '${fk.refDatabase}.${fk.refTable}'
                  : '${_primaryDb(tables)}.${fk.refTable}';
          return visibleKeys.contains(srcKey) && visibleKeys.contains(tgtKey);
        }).toList();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onScaleStart: onScaleStart,
      onScaleUpdate: onScaleUpdate,
      child: RepaintBoundary(
        key: repaintKey,
        child: Container(
          color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF4F6FA),
          child: ClipRect(
            child: CustomPaint(
              foregroundPainter: _FkLinePainter(
                tables: tables,
                foreignKeys: visibleFks,
                positions: positions,
                columns: columns,
                scale: scale,
                offset: offset,
                cardWidth: cardWidth,
                cardHeaderH: cardHeaderH,
                cardRowH: cardRowH,
                lineColor: cs.primary.withAlpha(160),
              ),
              child: Transform.translate(
                offset: offset,
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topLeft,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const SizedBox(width: 8000, height: 8000),
                      for (final table in tables)
                        Positioned(
                          left: positions[table.key]?.dx ?? 0,
                          top: positions[table.key]?.dy ?? 0,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanUpdate: (d) => onCardDrag(table.key, d.delta),
                            child: _TableCard(
                              table: table,
                              columns: columns[table.key] ?? [],
                              fkColumns:
                                  foreignKeys
                                      .where((fk) => fk.table == table.name)
                                      .map((fk) => fk.column)
                                      .toSet(),
                              cardWidth: cardWidth,
                              cardHeaderH: cardHeaderH,
                              cardRowH: cardRowH,
                              cs: cs,
                              isDark: isDark,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helpers to resolve which db a table belongs to for FK line matching.
  String _primaryDb(List<_ErdTable> tables) =>
      tables.where((t) => !t.isCrossDb).map((t) => t.db).firstOrNull ?? '';

  String _selectedDb(ForeignKeyInfo fk, List<_ErdTable> tables) =>
      tables
          .where((t) => t.name == fk.table && !t.isCrossDb)
          .map((t) => t.db)
          .firstOrNull ??
      _primaryDb(tables);
}

// ── Table card ────────────────────────────────────────────────────────────────

class _TableCard extends StatelessWidget {
  final _ErdTable table;
  final List<ColumnInfo> columns;
  final Set<String> fkColumns; // column names that are FK cols in this table
  final double cardWidth;
  final double cardHeaderH;
  final double cardRowH;
  final ColorScheme cs;
  final bool isDark;

  const _TableCard({
    required this.table,
    required this.columns,
    required this.fkColumns,
    required this.cardWidth,
    required this.cardHeaderH,
    required this.cardRowH,
    required this.cs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Cross-db cards use a teal accent header to distinguish them visually.
    final headerColor = table.isCrossDb ? Colors.teal.shade600 : cs.primary;

    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252540) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: headerColor.withAlpha(150), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 80 : 40),
            blurRadius: 10,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Container(
            height: cardHeaderH,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [headerColor, headerColor.withAlpha(200)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(7),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(
                  table.isCrossDb
                      ? Icons.open_in_new_outlined
                      : Icons.table_rows,
                  size: 11,
                  color: Colors.white70,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    table.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          // ── Column rows ───────────────────────────────────────────────────
          ...columns.map((col) {
            final isFk = fkColumns.contains(col.name);
            return SizedBox(
              height: cardRowH,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    // Key icon
                    SizedBox(
                      width: 12,
                      child:
                          col.isPrimaryKey
                              ? Icon(
                                Icons.vpn_key,
                                size: 9,
                                color: Colors.amber.shade600,
                              )
                              : isFk
                              ? Icon(Icons.link, size: 9, color: cs.tertiary)
                              : col.isUniqueKey
                              ? Icon(
                                Icons.fingerprint,
                                size: 9,
                                color: cs.secondary,
                              )
                              : Icon(
                                Icons.horizontal_rule,
                                size: 9,
                                color: cs.onSurface.withAlpha(40),
                              ),
                    ),
                    const SizedBox(width: 3),
                    // Column name
                    Expanded(
                      child: Text(
                        col.name,
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color:
                              col.isPrimaryKey
                                  ? Colors.amber.shade700
                                  : isFk
                                  ? cs.tertiary
                                  : cs.onSurface,
                          fontWeight:
                              col.isPrimaryKey || isFk
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    // Data type — capped to prevent overflow
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 68),
                      child: Text(
                        col.columnType ?? col.dataType,
                        style: TextStyle(
                          fontSize: 8,
                          fontFamily: 'monospace',
                          color: cs.onSurface.withAlpha(90),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    // NOT NULL indicator
                    if (!col.isNullable)
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Icon(
                          Icons.block,
                          size: 7,
                          color: cs.error.withAlpha(110),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── FK line painter ───────────────────────────────────────────────────────────

class _FkLinePainter extends CustomPainter {
  final List<_ErdTable> tables;
  final List<ForeignKeyInfo> foreignKeys;
  final Map<String, Offset> positions;
  final Map<String, List<ColumnInfo>> columns;
  final double scale;
  final Offset offset;
  final double cardWidth;
  final double cardHeaderH;
  final double cardRowH;
  final Color lineColor;

  const _FkLinePainter({
    required this.tables,
    required this.foreignKeys,
    required this.positions,
    required this.columns,
    required this.scale,
    required this.offset,
    required this.cardWidth,
    required this.cardHeaderH,
    required this.cardRowH,
    required this.lineColor,
  });

  String _keyFor(String db, String table) => '$db.$table';

  String _primaryDb() =>
      tables.where((t) => !t.isCrossDb).map((t) => t.db).firstOrNull ?? '';

  Offset _columnAnchor(String tableKey, String colName, bool rightSide) {
    final pos = positions[tableKey] ?? Offset.zero;
    final cols = columns[tableKey] ?? [];
    final idx = cols.indexWhere((c) => c.name == colName);
    final y = cardHeaderH + (idx >= 0 ? idx : 0) * cardRowH + cardRowH / 2;
    final x = rightSide ? cardWidth : 0.0;
    return Offset(
      pos.dx * scale + offset.dx + x * scale,
      pos.dy * scale + offset.dy + y * scale,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = lineColor
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

    for (final fk in foreignKeys) {
      final primary = _primaryDb();
      final srcKey = _keyFor(primary, fk.table);
      final tgtKey =
          fk.refDatabase.isNotEmpty
              ? _keyFor(fk.refDatabase, fk.refTable)
              : _keyFor(primary, fk.refTable);

      final srcPos = positions[srcKey];
      final tgtPos = positions[tgtKey];
      if (srcPos == null || tgtPos == null) continue;

      final srcRight =
          (srcPos.dx + cardWidth / 2) < (tgtPos.dx + cardWidth / 2);
      final src = _columnAnchor(srcKey, fk.column, srcRight);
      final tgt = _columnAnchor(tgtKey, fk.refColumn, !srcRight);

      final dx = (tgt.dx - src.dx).abs() * 0.5;
      final path =
          Path()
            ..moveTo(src.dx, src.dy)
            ..cubicTo(
              src.dx + (srcRight ? dx : -dx),
              src.dy,
              tgt.dx + (srcRight ? -dx : dx),
              tgt.dy,
              tgt.dx,
              tgt.dy,
            );
      canvas.drawPath(path, paint);
      _drawArrow(
        canvas,
        paint,
        tgt,
        srcRight ? const Offset(-1, 0) : const Offset(1, 0),
      );
    }
  }

  void _drawArrow(Canvas canvas, Paint paint, Offset tip, Offset dir) {
    final ap =
        Paint()
          ..color = paint.color
          ..style = PaintingStyle.fill;
    final s = 6.0 * scale.clamp(0.5, 2.0);
    final perp = Offset(-dir.dy, dir.dx);
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(
          tip.dx + dir.dx * s + perp.dx * s / 2,
          tip.dy + dir.dy * s + perp.dy * s / 2,
        )
        ..lineTo(
          tip.dx + dir.dx * s - perp.dx * s / 2,
          tip.dy + dir.dy * s - perp.dy * s / 2,
        )
        ..close(),
      ap,
    );
  }

  @override
  bool shouldRepaint(_FkLinePainter old) =>
      old.scale != scale ||
      old.offset != offset ||
      old.foreignKeys != foreignKeys ||
      old.positions != positions;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _ToolbarIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  const _ToolbarIconBtn({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Icon(
            icon,
            size: 15,
            color:
                onTap == null
                    ? Theme.of(context).colorScheme.onSurface.withAlpha(60)
                    : null,
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final ColorScheme cs;
  const _EmptyHint({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schema_outlined,
            size: 48,
            color: cs.primary.withAlpha(80),
          ),
          const SizedBox(height: 12),
          Text(
            'Select a database to view its schema',
            style: TextStyle(fontSize: 13, color: cs.onSurface.withAlpha(120)),
          ),
          const SizedBox(height: 4),
          Text(
            'Use the Database dropdown above',
            style: TextStyle(fontSize: 11, color: cs.onSurface.withAlpha(80)),
          ),
        ],
      ),
    );
  }
}
