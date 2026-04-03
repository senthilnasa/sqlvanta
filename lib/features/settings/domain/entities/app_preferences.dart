class AppPreferences {
  final String themeMode; // 'system' | 'light' | 'dark'
  final double editorFontSize;
  final int editorTabSize;
  final bool editorWordWrap;
  final int resultMaxRows;
  final String nullDisplayText;
  final double sidebarWidth;

  const AppPreferences({
    this.themeMode = 'system',
    this.editorFontSize = 14,
    this.editorTabSize = 2,
    this.editorWordWrap = false,
    this.resultMaxRows = 1000,
    this.nullDisplayText = 'NULL',
    this.sidebarWidth = 260,
  });

  AppPreferences copyWith({
    String? themeMode,
    double? editorFontSize,
    int? editorTabSize,
    bool? editorWordWrap,
    int? resultMaxRows,
    String? nullDisplayText,
    double? sidebarWidth,
  }) {
    return AppPreferences(
      themeMode: themeMode ?? this.themeMode,
      editorFontSize: editorFontSize ?? this.editorFontSize,
      editorTabSize: editorTabSize ?? this.editorTabSize,
      editorWordWrap: editorWordWrap ?? this.editorWordWrap,
      resultMaxRows: resultMaxRows ?? this.resultMaxRows,
      nullDisplayText: nullDisplayText ?? this.nullDisplayText,
      sidebarWidth: sidebarWidth ?? this.sidebarWidth,
    );
  }
}
