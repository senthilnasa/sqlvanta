import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTextStyles {
  // Editor font — monospace for SQL
  static TextStyle editorBase({double fontSize = 14}) =>
      GoogleFonts.jetBrainsMono(fontSize: fontSize);

  static TextStyle editorStyle({
    double fontSize = 14,
    Color? color,
    FontWeight weight = FontWeight.normal,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        color: color,
        fontWeight: weight,
      );

  // UI font — clean sans-serif
  static TextStyle uiLabel({double fontSize = 13, Color? color}) =>
      GoogleFonts.inter(fontSize: fontSize, color: color);

  static TextStyle uiBody({double fontSize = 14, Color? color}) =>
      GoogleFonts.inter(fontSize: fontSize, color: color);

  static TextStyle uiCaption({double fontSize = 11, Color? color}) =>
      GoogleFonts.inter(fontSize: fontSize, color: color);

  static TextStyle uiTitle({double fontSize = 16, Color? color}) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        color: color,
        fontWeight: FontWeight.w600,
      );

  // Tree nodes in object browser
  static TextStyle treeNode({double fontSize = 13, Color? color}) =>
      GoogleFonts.inter(fontSize: fontSize, color: color);
}
