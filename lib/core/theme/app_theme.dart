import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

abstract final class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.floodBlue,
      onPrimary: AppColors.surface,
      secondary: AppColors.warning,
      onSecondary: AppColors.ink,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.floodRed,
      onError: AppColors.surface,
    );

    const textTheme = TextTheme(
      headlineSmall: TextStyle(
        color: AppColors.ink,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      bodyMedium: TextStyle(color: AppColors.ink, fontSize: 16),
      labelSmall: TextStyle(color: AppColors.mutedText, fontSize: 12),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      textTheme: textTheme,
      cardTheme: const CardThemeData(margin: EdgeInsets.all(AppSpacing.sm)),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.floodBlue,
        foregroundColor: AppColors.surface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.floodBlue,
          foregroundColor: AppColors.surface,
          minimumSize: const Size.fromHeight(48),
          textStyle: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        errorStyle: TextStyle(color: AppColors.errorText, fontSize: 12),
      ),
    );
  }
}
