import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

class KairosColors {
  const KairosColors._();

  static const primary = Color(0xFF6E56CF);
  static const primaryDark = Color(0xFF9D7CFF);
  static const accent = Color(0xFF2DD4BF);
  static const success = Color(0xFF4ADE80);
  static const warning = Color(0xFFFACC15);
  static const critical = Color(0xFFFF6B6B);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF5D6678);
  static const surface = Color(0xFFF7FAFF);
  static const border = Color(0xFFD7DFEA);
  static const darkSurface = Color(0xFF101419);
  static const darkBorder = Color(0xFF343D4B);
}

class KairosSpacing {
  const KairosSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class KairosRadius {
  const KairosRadius._();

  static const sm = 10.0;
  static const md = 18.0;
  static const lg = 24.0;
}

class KairosTheme {
  const KairosTheme._();

  static ThemeData light() {
    return _base(
      brightness: Brightness.light,
      primary: KairosColors.primary,
      surface: Colors.white,
      scaffold: const Color(0xFFF4F7FB),
      textPrimary: KairosColors.textPrimary,
      textSecondary: KairosColors.textSecondary,
      border: KairosColors.border,
    );
  }

  static ThemeData dark() {
    return _base(
      brightness: Brightness.dark,
      primary: KairosColors.primaryDark,
      surface: KairosColors.darkSurface,
      scaffold: const Color(0xFF07090D),
      textPrimary: KairosColors.surface,
      textSecondary: const Color(0xFFB7C0D1),
      border: KairosColors.darkBorder,
    );
  }

  static ThemeData _base({
    required Brightness brightness,
    required Color primary,
    required Color surface,
    required Color scaffold,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      surface: surface,
      outline: border,
      error: KairosColors.critical,
    );

    final baseTextTheme = brightness == Brightness.light
        ? Typography.blackMountainView
        : Typography.whiteMountainView;

    final textTheme = baseTextTheme
        .copyWith(
          displayLarge: baseTextTheme.displayLarge?.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          headlineMedium: baseTextTheme.headlineMedium?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          titleLarge: baseTextTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          titleMedium: baseTextTheme.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(
            fontSize: 16,
            letterSpacing: 0,
          ),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(
            fontSize: 14,
            letterSpacing: 0,
          ),
          labelLarge: baseTextTheme.labelLarge?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          labelSmall: baseTextTheme.labelSmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        )
        .apply(
          bodyColor: textPrimary,
          displayColor: textPrimary,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffold,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surface.withValues(
          alpha: brightness == Brightness.light ? 0.62 : 0.34,
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KairosRadius.md),
          side: BorderSide(
            color: brightness == Brightness.light
                ? Colors.white.withValues(alpha: 0.82)
                : Colors.white.withValues(alpha: 0.14),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: brightness == Brightness.light
            ? Colors.white.withValues(alpha: 0.72)
            : Colors.white.withValues(alpha: 0.12),
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface.withValues(
          alpha: brightness == Brightness.light ? 0.58 : 0.28,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KairosRadius.md),
          borderSide: BorderSide(
            color: brightness == Brightness.light
                ? Colors.white.withValues(alpha: 0.78)
                : Colors.white.withValues(alpha: 0.16),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KairosRadius.md),
          borderSide: BorderSide(
            color: brightness == Brightness.light
                ? Colors.white.withValues(alpha: 0.72)
                : Colors.white.withValues(alpha: 0.14),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KairosRadius.md),
          borderSide: BorderSide(
            color: primary.withValues(alpha: 0.62),
            width: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(44, 44),
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KairosRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          backgroundColor: surface.withValues(
            alpha: brightness == Brightness.light ? 0.38 : 0.2,
          ),
          side: BorderSide(
            color: brightness == Brightness.light
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KairosRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface.withValues(
          alpha: brightness == Brightness.light ? 0.52 : 0.24,
        ),
        indicatorColor: primary.withValues(alpha: 0.2),
        selectedIconTheme: IconThemeData(color: primary),
        selectedLabelTextStyle: textTheme.bodyMedium?.copyWith(
          color: primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface.withValues(
          alpha: brightness == Brightness.light ? 0.64 : 0.24,
        ),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: primary.withValues(alpha: 0.2),
        height: 76,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected ? primary : textSecondary,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface.withValues(
          alpha: brightness == Brightness.light ? 0.44 : 0.2,
        ),
        selectedColor: primary.withValues(alpha: 0.16),
        side: BorderSide(
          color: brightness == Brightness.light
              ? Colors.white.withValues(alpha: 0.72)
              : Colors.white.withValues(alpha: 0.16),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KairosRadius.md),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            if (selected) return primary.withValues(alpha: 0.18);
            return surface.withValues(
              alpha: brightness == Brightness.light ? 0.34 : 0.22,
            );
          }),
          side: WidgetStateProperty.all(
            BorderSide(
              color: brightness == Brightness.light
                  ? Colors.white.withValues(alpha: 0.68)
                  : Colors.white.withValues(alpha: 0.16),
            ),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(KairosRadius.md),
            ),
          ),
        ),
      ),
    );
  }
}
