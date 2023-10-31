import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LAppTheme{
  static TextStyle bHeader = GoogleFonts.lexend(color: Colors.black, fontWeight: FontWeight.normal, fontSize: 26);
  static TextStyle header = GoogleFonts.lexend(color: Colors.black, fontWeight: FontWeight.normal, fontSize: 23);
  static TextStyle sHeader = GoogleFonts.lexend(color: Colors.black87, fontWeight: FontWeight.normal, fontSize: 20.0);
  static TextStyle body = GoogleFonts.redHatDisplay(color: Colors.black87, fontSize: 16.5);
  static TextStyle sBody = GoogleFonts.redHatDisplay(color: Colors.black87, fontSize: 12.0);
  static TextStyle lBody = GoogleFonts.redHatDisplay(color: Colors.black87, fontSize: 16.5, fontWeight: FontWeight.bold);

  static TextStyle d_bHeader = GoogleFonts.lexend(color: Colors.white, fontWeight: FontWeight.normal, fontSize: 26);
  static TextStyle d_header = GoogleFonts.lexend(color: Colors.white, fontWeight: FontWeight.normal, fontSize: 23);
  static TextStyle d_sHeader = GoogleFonts.lexend(color: Colors.white, fontWeight: FontWeight.normal, fontSize: 20.0);
  static TextStyle d_body = GoogleFonts.redHatDisplay(color: Colors.white70, fontSize: 16.5);
  static TextStyle d_sBody = GoogleFonts.redHatDisplay(color: Colors.white70, fontSize: 12.0);
  static TextStyle d_lBody = GoogleFonts.redHatDisplay(color: Colors.white70, fontSize: 16.5, fontWeight: FontWeight.bold);

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: const MaterialColor(0xFFF8AC41, {
      50: Color(0xFFFFF5E0),
      100: Color(0xFFFFE0B2),
      200: Color(0xFFFFCC80),
      300: Color(0xFFFFB74D),
      400: Color(0xFFFFA726),
      500: Color(0xFFF8AC41), // Your desired color
      600: Color(0xFFF39C12),
      700: Color(0xFFF29F05),
      800: Color(0xFFE86C02),
      900: Color(0xFFD84315),
    }),

    canvasColor: Colors.white,

    textTheme: TextTheme(
      headlineLarge: bHeader,
      headlineMedium: header,
      headlineSmall: sHeader,
      bodyLarge: lBody,
      bodyMedium: body,
      bodySmall: sBody,
    ),
  );






  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: const MaterialColor(0xFFEFCE14, <int, Color>{
      50: Color(0xFFFDF9E3),
      100: Color(0xFFFAF0B9),
      200: Color(0xFFF7E78A),
      300: Color(0xFFF4DD5B),
      400: Color(0xFFF1D537),
      500: Color(0xFFEFCE14),
      600: Color(0xFFEDC912),
      700: Color(0xFFEBC20E),
      800: Color(0xFFE8BC0B),
      900: Color(0xFFE4B006),
    }
    ),
    textTheme: TextTheme(
      headlineLarge: d_bHeader,
      headlineMedium: d_header,
      headlineSmall: d_sHeader,
      bodyLarge: d_lBody,
      bodyMedium: d_body,
      bodySmall: d_sBody,
    ),
    hintColor: LAppTheme.lightTheme.primaryColor,
  );
}