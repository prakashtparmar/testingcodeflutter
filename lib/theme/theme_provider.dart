import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final Color primaryColorLight = Color.fromRGBO(6, 77, 131, 1);
  static final Color primaryColorDark = Color.fromRGBO(28, 99, 153, 1);
  static final Color secondaryColorLight = Color.fromRGBO(244, 248, 251, 1);
  static final Color secondaryColorDark = Color.fromRGBO(30, 35, 40, 1);
  static final Color errorColor = Color.fromRGBO(211, 47, 47, 1);

  static TextTheme _buildTextTheme(TextTheme base, Color textColor) {
    return GoogleFonts.poppinsTextTheme(base).copyWith(
      displayLarge: GoogleFonts.poppins(
        color: textColor,
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
      ),
      displayMedium: GoogleFonts.poppins(
        color: textColor,
        fontSize: 45,
        fontWeight: FontWeight.w400,
      ),
      displaySmall: GoogleFonts.poppins(
        color: textColor,
        fontSize: 36,
        fontWeight: FontWeight.w400,
      ),
      headlineLarge: GoogleFonts.poppins(
        color: textColor,
        fontSize: 32,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: GoogleFonts.poppins(
        color: textColor,
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: GoogleFonts.poppins(
        color: textColor,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.poppins(
        color: textColor,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.poppins(
        color: textColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.poppins(
        color: textColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      bodyLarge: GoogleFonts.poppins(
        color: textColor.withOpacity(0.9),
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.poppins(
        color: textColor.withOpacity(0.8),
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.poppins(
        color: textColor.withOpacity(0.6),
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
      ),
      labelLarge: GoogleFonts.poppins(
        color: textColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.poppins(
        color: textColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.poppins(
        color: textColor,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }

  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColorLight,
    colorScheme: ColorScheme.light(
      primary: primaryColorLight,
      secondary: primaryColorLight.withOpacity(0.8),
      surface: Colors.white,
      background: secondaryColorLight,
      error: errorColor,
    ),
    scaffoldBackgroundColor: secondaryColorLight,
    appBarTheme: AppBarTheme(
      color: primaryColorLight,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      elevation: 0,
      toolbarTextStyle: _buildTextTheme(
        ThemeData.light().textTheme,
        Colors.white,
      ).bodyMedium?.copyWith(color: Colors.white),
    ),
    textTheme: _buildTextTheme(ThemeData.light().textTheme, Colors.black87),
    primaryTextTheme: _buildTextTheme(
      ThemeData.light().textTheme,
      Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColorLight,
        foregroundColor: Colors.white,
        textStyle: _buildTextTheme(
          ThemeData.light().textTheme,
          Colors.white,
        ).labelLarge?.copyWith(fontWeight: FontWeight.w600),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColorLight,
        textStyle: _buildTextTheme(
          ThemeData.light().textTheme,
          primaryColorLight,
        ).labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColorLight,
        side: BorderSide(color: primaryColorLight),
        textStyle: _buildTextTheme(
          ThemeData.light().textTheme,
          primaryColorLight,
        ).labelLarge?.copyWith(fontWeight: FontWeight.w600),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primaryColorLight,
      linearTrackColor: primaryColorLight.withOpacity(0.24),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColorLight),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorColor),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle:
          _buildTextTheme(
            ThemeData.light().textTheme,
            Colors.black54,
          ).bodyMedium,
      hintStyle:
          _buildTextTheme(
            ThemeData.light().textTheme,
            Colors.black38,
          ).bodyMedium,
      errorStyle: _buildTextTheme(
        ThemeData.light().textTheme,
        errorColor,
      ).bodySmall?.copyWith(fontWeight: FontWeight.w500),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: primaryColorLight,
      labelStyle:
          _buildTextTheme(
            ThemeData.light().textTheme,
            Colors.black87,
          ).bodySmall,
      secondaryLabelStyle:
          _buildTextTheme(ThemeData.light().textTheme, Colors.white).bodySmall,
      brightness: Brightness.light,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColorDark,
    colorScheme: ColorScheme.dark(
      primary: primaryColorDark,
      secondary: primaryColorDark.withOpacity(0.8),
      surface: Color.fromRGBO(40, 45, 50, 1),
      background: secondaryColorDark,
      error: errorColor,
    ),
    scaffoldBackgroundColor: secondaryColorDark,
    appBarTheme: AppBarTheme(
      color: primaryColorDark,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      elevation: 0,
      toolbarTextStyle:
          _buildTextTheme(ThemeData.dark().textTheme, Colors.white).bodyMedium,
    ),
    textTheme: _buildTextTheme(
      ThemeData.dark().textTheme,
      Colors.white.withOpacity(0.9),
    ),
    primaryTextTheme: _buildTextTheme(ThemeData.dark().textTheme, Colors.white),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColorDark,
        foregroundColor: Colors.white,
        textStyle: _buildTextTheme(
          ThemeData.dark().textTheme,
          Colors.white,
        ).labelLarge?.copyWith(fontWeight: FontWeight.w600),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColorDark,
        textStyle: _buildTextTheme(
          ThemeData.dark().textTheme,
          primaryColorDark,
        ).labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColorDark,
        side: BorderSide(color: primaryColorDark),
        textStyle: _buildTextTheme(
          ThemeData.dark().textTheme,
          primaryColorDark,
        ).labelLarge?.copyWith(fontWeight: FontWeight.w600),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primaryColorDark,
      linearTrackColor: primaryColorDark.withOpacity(0.24),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color.fromRGBO(50, 55, 60, 1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColorDark),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorColor),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle:
          _buildTextTheme(
            ThemeData.dark().textTheme,
            Colors.white.withOpacity(0.7),
          ).bodyMedium,
      hintStyle:
          _buildTextTheme(
            ThemeData.dark().textTheme,
            Colors.white.withOpacity(0.5),
          ).bodyMedium,
      errorStyle: _buildTextTheme(
        ThemeData.dark().textTheme,
        errorColor,
      ).bodySmall?.copyWith(fontWeight: FontWeight.w500),
    ),
    cardTheme: CardThemeData(
      color: Color.fromRGBO(40, 45, 50, 1),
      elevation: 2,
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Color.fromRGBO(50, 55, 60, 1),
      selectedColor: primaryColorDark,
      labelStyle:
          _buildTextTheme(
            ThemeData.dark().textTheme,
            Colors.white.withOpacity(0.9),
          ).bodySmall,
      secondaryLabelStyle:
          _buildTextTheme(ThemeData.dark().textTheme, Colors.white).bodySmall,
      brightness: Brightness.dark,
    ),
  );
}
