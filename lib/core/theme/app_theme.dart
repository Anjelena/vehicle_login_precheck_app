import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBackground = Colors.black;
  static const Color secondaryBackground = Color(0xFF212121);
  static const Color cardBackground = Color(0xFF212121);

  static const Color primaryText = Colors.white;
  static const Color secondaryText = Color(0xFFB0B0B0);
  static const Color disabledText = Color(0xFF757575);

  static const Color accent = Colors.blue;
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color error = Colors.red;

  static const TextStyle headingLarge = TextStyle(
    color: primaryText,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle headingMedium = TextStyle(
    color: primaryText,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle bodyMedium = TextStyle(
    color: primaryText,
    fontSize: 14,
  );

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: primaryBackground,
    cardColor: cardBackground,
    textTheme: const TextTheme(
      headlineLarge: headingLarge,
      headlineMedium: headingMedium,
      bodyMedium: bodyMedium,
    ),
  );
}
