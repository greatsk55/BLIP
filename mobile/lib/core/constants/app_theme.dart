import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// BLIP 테마 (SSOT)
class AppTheme {
  AppTheme._();

  static ThemeData dark() => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.voidBlackDark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.signalGreenDark,
          onPrimary: AppColors.voidBlackDark,
          surface: AppColors.surfaceDark,
          onSurface: AppColors.white,
          error: AppColors.glitchRed,
          onError: AppColors.white,
          outline: AppColors.borderDark,
        ),
        textTheme: _textTheme(AppColors.white, AppColors.ghostGreyDark),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.voidBlackDark,
          foregroundColor: AppColors.signalGreenDark,
          elevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        cardTheme: const CardThemeData(
          color: AppColors.cardDark,
          elevation: 0,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.borderDark,
          thickness: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.borderDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.signalGreenDark),
          ),
          hintStyle: const TextStyle(color: AppColors.ghostGreyDark),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.signalGreenDark,
            foregroundColor: AppColors.voidBlackDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.signalGreenDark,
            side: const BorderSide(color: AppColors.signalGreenDark),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.cardDark,
          contentTextStyle: TextStyle(color: AppColors.white),
          behavior: SnackBarBehavior.floating,
        ),
      );

  static ThemeData light() => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.voidBlackLight,
        colorScheme: const ColorScheme.light(
          primary: AppColors.signalGreenLight,
          onPrimary: AppColors.white,
          surface: AppColors.surfaceLight,
          onSurface: AppColors.black,
          error: AppColors.glitchRed,
          onError: AppColors.white,
          outline: AppColors.borderLight,
        ),
        textTheme: _textTheme(AppColors.black, AppColors.ghostGreyLight),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.voidBlackLight,
          foregroundColor: AppColors.signalGreenLight,
          elevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        cardTheme: const CardThemeData(
          color: AppColors.cardLight,
          elevation: 0,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.borderLight,
          thickness: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.signalGreenLight),
          ),
          hintStyle: const TextStyle(color: AppColors.ghostGreyLight),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.signalGreenLight,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.signalGreenLight,
            side: const BorderSide(color: AppColors.signalGreenLight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      );

  static TextTheme _textTheme(Color primary, Color secondary) => TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: primary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: primary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: primary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: primary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: secondary,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
      );
}
