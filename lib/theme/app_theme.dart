/// Design tokens and the Material theme.
///
/// One neutral surface scale, one accent, and two status colours. Colour
/// carries meaning (accent = actionable or selected, caution = worth a look,
/// positive = done); it is never decoration.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class SpiderColors {
  // Surfaces, darkest to lightest.
  static const Color bg = Color(0xFF0B0B0C);
  static const Color surface = Color(0xFF141416);
  static const Color surfaceHigh = Color(0xFF1D1D20);
  static const Color outline = Color(0xFF2B2B30);

  // Text.
  static const Color textPrimary = Color(0xFFECEFF4);
  static const Color textMuted = Color(0xFF8E8E96);

  /// Brand red: primary actions, selection, the level ring.
  static const Color accent = Color(0xFFE5383B);

  /// Blue for data: progress bars, charts, water. Kept apart from red so a
  /// filling bar never reads as a warning.
  static const Color info = Color(0xFF4C82F0);

  /// Something worth a second look (a flagged food). Not an error.
  static const Color caution = Color(0xFFE6A23C);

  /// A finished thing.
  static const Color positive = Color(0xFF3FCF8E);

  /// Destructive actions only.
  static const Color danger = Color(0xFFEF5B63);
}

/// Spacing scale.
abstract final class SpiderSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 40;
}

abstract final class SpiderRadius {
  static const double card = 12;
  static const double pip = 8;
  static const double chip = 8;

  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius pipAll = BorderRadius.all(Radius.circular(pip));
  static const BorderRadius chipAll = BorderRadius.all(Radius.circular(chip));
}

abstract final class AppTheme {
  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: SpiderColors.accent,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF3A1517),
      onPrimaryContainer: SpiderColors.textPrimary,
      secondary: SpiderColors.info,
      onSecondary: Colors.white,
      secondaryContainer: SpiderColors.surfaceHigh,
      onSecondaryContainer: SpiderColors.textPrimary,
      tertiary: SpiderColors.positive,
      onTertiary: SpiderColors.bg,
      error: SpiderColors.danger,
      onError: SpiderColors.bg,
      surface: SpiderColors.surface,
      onSurface: SpiderColors.textPrimary,
      onSurfaceVariant: SpiderColors.textMuted,
      surfaceContainerHighest: SpiderColors.surfaceHigh,
      outline: SpiderColors.outline,
      outlineVariant: SpiderColors.outline,
      shadow: Colors.black,
      scrim: Colors.black,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: SpiderColors.bg,
      canvasColor: SpiderColors.bg,
      splashFactory: InkRipple.splashFactory,
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: SpiderColors.outline),
    );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: SpiderColors.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: SpiderColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.ibmPlexSans(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: SpiderColors.textPrimary,
        ),
      ),
      iconTheme: const IconThemeData(color: SpiderColors.textPrimary, size: 22),
      dividerTheme: const DividerThemeData(
        color: SpiderColors.outline,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: SpiderColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: SpiderRadius.cardAll,
          side: const BorderSide(color: SpiderColors.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SpiderColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: SpiderColors.accent, width: 1.5),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: SpiderColors.danger),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: SpiderColors.danger, width: 1.5),
        ),
        labelStyle: GoogleFonts.ibmPlexSans(color: SpiderColors.textMuted),
        hintStyle: GoogleFonts.ibmPlexSans(color: SpiderColors.textMuted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: SpiderColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          shape: buttonShape,
          textStyle: GoogleFonts.ibmPlexSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SpiderColors.textPrimary,
          side: const BorderSide(color: SpiderColors.outline),
          minimumSize: const Size(64, 48),
          shape: buttonShape,
          textStyle: GoogleFonts.ibmPlexSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SpiderColors.accent,
          textStyle: GoogleFonts.ibmPlexSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: SpiderColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: SpiderColors.accent.withValues(alpha: 0.18),
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.ibmPlexSans(
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? SpiderColors.textPrimary
                : SpiderColors.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? SpiderColors.accent
                : SpiderColors.textMuted,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: SpiderColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: SpiderColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: SpiderColors.surfaceHigh,
        contentTextStyle: GoogleFonts.ibmPlexSans(
          color: SpiderColors.textPrimary,
          fontSize: 14,
        ),
        actionTextColor: SpiderColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: SpiderColors.info,
        linearTrackColor: SpiderColors.outline,
        linearMinHeight: 6,
      ),
    );
  }

  /// IBM Plex Sans for text, Plex Sans Condensed for the big numerals.
  /// Hierarchy comes from size and weight rather than from decoration.
  static TextTheme _textTheme(TextTheme base) {
    final body = GoogleFonts.ibmPlexSansTextTheme(base).apply(
      bodyColor: SpiderColors.textPrimary,
      displayColor: SpiderColors.textPrimary,
    );

    TextStyle t(double size, FontWeight w, {double h = 1.25, double ls = 0}) =>
        GoogleFonts.ibmPlexSans(
          fontSize: size,
          fontWeight: w,
          height: h,
          letterSpacing: ls,
          color: SpiderColors.textPrimary,
          fontFeatures: const [FontFeature.tabularFigures()],
        );

    TextStyle numeral(double size) => GoogleFonts.ibmPlexSansCondensed(
      fontSize: size,
      fontWeight: FontWeight.w600,
      height: 1.0,
      letterSpacing: -0.5,
      color: SpiderColors.textPrimary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return body.copyWith(
      displayLarge: numeral(64),
      displayMedium: numeral(34),
      displaySmall: t(28, FontWeight.w700, h: 1.15, ls: -0.6),
      headlineLarge: t(28, FontWeight.w700, h: 1.1, ls: -0.6),
      headlineMedium: t(22, FontWeight.w700, ls: -0.3),
      headlineSmall: t(19, FontWeight.w600, ls: -0.2),
      titleLarge: t(17, FontWeight.w600, ls: -0.1),
      titleMedium: t(15, FontWeight.w600),
      titleSmall: t(13, FontWeight.w600),
      bodyLarge: t(15, FontWeight.w400, h: 1.45),
      bodyMedium: t(14, FontWeight.w400, h: 1.45),
      bodySmall: t(
        12.5,
        FontWeight.w400,
        h: 1.4,
      ).copyWith(color: SpiderColors.textMuted),
      labelLarge: t(14, FontWeight.w600),
      labelMedium: t(12, FontWeight.w500),
      labelSmall: t(
        11,
        FontWeight.w600,
        ls: 0.6,
      ).copyWith(color: SpiderColors.textMuted),
    );
  }
}
