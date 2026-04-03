import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTheme {
  // ── Light theme (SQLyog-inspired professional look) ─────────────────────────
  static ThemeData get light => FlexThemeData.light(
        scheme: FlexScheme.blue,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 4,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 8,
          blendOnColors: false,
          useM2StyleDividerInM3: true,
          inputDecoratorIsDense: true,
          inputDecoratorBorderType: FlexInputBorderType.outline,
          inputDecoratorUnfocusedHasBorder: true,
          tabBarIndicatorWeight: 2,
          tabBarDividerColor: Colors.transparent,
        ),
        visualDensity: VisualDensity.compact,
        useMaterial3: true,
        textTheme: _textTheme,
      );

  // ── Dark theme ───────────────────────────────────────────────────────────────
  static ThemeData get dark => FlexThemeData.dark(
        scheme: FlexScheme.blue,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 15,
        darkIsTrueBlack: false,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 20,
          useM2StyleDividerInM3: true,
          inputDecoratorIsDense: true,
          inputDecoratorBorderType: FlexInputBorderType.outline,
          inputDecoratorUnfocusedHasBorder: true,
          tabBarIndicatorWeight: 2,
          tabBarDividerColor: Colors.transparent,
        ),
        visualDensity: VisualDensity.compact,
        useMaterial3: true,
        textTheme: _textTheme,
      );

  static TextTheme get _textTheme => GoogleFonts.interTextTheme();
}
