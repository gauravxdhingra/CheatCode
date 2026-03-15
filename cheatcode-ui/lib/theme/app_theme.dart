import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const black = Color(0xFF080808);
  static const dim = Color(0xFF1A1A1A);
  static const mid = Color(0xFF2A2A2A);
  static const white = Color(0xFFF0EDE6);
  static const green = Color(0xFF00FF88);
  static const red = Color(0xFFFF2D55);
  static const yellow = Color(0xFFFFAA00);
  static const codePink = Color(0xFFFF79C6);
  static const codeGreen = Color(0xFF50FA7B);
  static const codeYellow = Color(0xFFF1FA8C);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: black,
        colorScheme: const ColorScheme.dark(
          primary: green,
          secondary: green,
          surface: dim,
          error: red,
        ),
        textTheme: GoogleFonts.syneTextTheme(
          ThemeData.dark().textTheme,
        ).apply(bodyColor: white, displayColor: white),
        useMaterial3: true,
      );

  static TextStyle mono({
    double size = 14,
    Color color = white,
    FontWeight weight = FontWeight.normal,
  }) =>
      GoogleFonts.spaceMono(
        fontSize: size,
        color: color,
        fontWeight: weight,
      );
}
