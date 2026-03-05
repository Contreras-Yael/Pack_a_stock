import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppPalette.accent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.dark.bg,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.dark.card,
          foregroundColor: AppColors.dark.text,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        drawerTheme: DrawerThemeData(backgroundColor: AppColors.dark.card),
        dialogTheme: DialogThemeData(backgroundColor: AppColors.dark.card),
        extensions: const [AppColors.dark],
      );

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppPalette.accent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.light.bg,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.light.card,
          foregroundColor: AppColors.light.text,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        drawerTheme: DrawerThemeData(backgroundColor: AppColors.light.card),
        dialogTheme: DialogThemeData(backgroundColor: AppColors.light.card),
        extensions: const [AppColors.light],
      );
}
