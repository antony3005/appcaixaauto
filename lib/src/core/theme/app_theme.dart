import 'package:flutter/material.dart';

abstract final class AppColors {
  static const navy = Color(0xFF082F5B);
  static const navyDark = Color(0xFF031B35);
  static const navySurface = Color(0xFF0B2847);
  static const blue = Color(0xFF146CC5);
  static const gold = Color(0xFFC89B3C);
  static const goldSoft = Color(0xFFF8EFD9);
  static const fresh = Color(0xFF238B61);
  static const coral = Color(0xFFC94B3A);
  static const cream = Color(0xFFF7F9FC);
  static const paper = Color(0xFFFCFDFE);
  static const ink = Color(0xFF10243B);
  static const muted = Color(0xFF607389);
  static const line = Color(0xFFDCE4EE);
  static const darkText = Color(0xFFF4F7FB);
  static const darkMuted = Color(0xFFA9B9CA);
  static const darkLine = Color(0xFF234563);
  static const qrPaper = Color(0xFFFDFEFF);
  static const qrInk = Color(0xFF031B35);
  static const successSoft = Color(0xFFE2F5EC);
  static const warningSoft = Color(0xFFFFF2D8);
  static const errorSoft = Color(0xFFFBE8E4);
}

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class AppRadii {
  static const small = 10.0;
  static const control = 14.0;
  static const card = 20.0;
  static const hero = 28.0;
  static const pill = 999.0;
}

abstract final class AppAnimations {
  static const short = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 220);
  static const long = Duration(milliseconds: 360);
  static const standard = Curves.easeOutCubic;
  static const emphasized = Curves.easeOutQuart;
  static const exit = Curves.easeInCubic;
}

abstract final class AppShadows {
  static const light = [
    BoxShadow(color: Color(0x12082F5B), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const dark = [
    BoxShadow(color: Color(0x33020F1D), blurRadius: 20, offset: Offset(0, 8)),
  ];
}

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.gold,
    required this.onGold,
    required this.goldContainer,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.muted,
    required this.qr,
  });

  final Color gold, onGold, goldContainer;
  final Color success, successContainer;
  final Color warning, warningContainer;
  final Color muted, qr;

  @override
  AppSemanticColors copyWith({
    Color? gold,
    Color? onGold,
    Color? goldContainer,
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? muted,
    Color? qr,
  }) => AppSemanticColors(
    gold: gold ?? this.gold,
    onGold: onGold ?? this.onGold,
    goldContainer: goldContainer ?? this.goldContainer,
    success: success ?? this.success,
    successContainer: successContainer ?? this.successContainer,
    warning: warning ?? this.warning,
    warningContainer: warningContainer ?? this.warningContainer,
    muted: muted ?? this.muted,
    qr: qr ?? this.qr,
  );

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      gold: Color.lerp(gold, other.gold, t)!,
      onGold: Color.lerp(onGold, other.onGold, t)!,
      goldContainer: Color.lerp(goldContainer, other.goldContainer, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      muted: Color.lerp(muted, other.muted, t)!,
      qr: Color.lerp(qr, other.qr, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppSemanticColors get semantic =>
      Theme.of(this).extension<AppSemanticColors>()!;
}

abstract final class AppTheme {
  static ThemeData light() => _theme(Brightness.light);
  static ThemeData dark() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          brightness: brightness,
          primary: dark ? const Color(0xFF78B7F4) : AppColors.navy,
          secondary: dark ? const Color(0xFFE0B75F) : AppColors.gold,
          surface: dark ? AppColors.navySurface : AppColors.paper,
          error: dark ? const Color(0xFFFFB4A9) : const Color(0xFFBA1A1A),
        ).copyWith(
          onSurface: dark ? AppColors.darkText : AppColors.ink,
          outline: dark ? AppColors.darkLine : AppColors.line,
          surfaceContainerLowest: dark ? AppColors.navyDark : AppColors.paper,
          surfaceContainerLow: dark
              ? const Color(0xFF07223D)
              : const Color(0xFFF4F7FB),
          surfaceContainer: dark
              ? AppColors.navySurface
              : const Color(0xFFEEF3F8),
          surfaceContainerHigh: dark
              ? const Color(0xFF123553)
              : const Color(0xFFE7EDF4),
        );
    const text = TextTheme(
      displaySmall: TextStyle(
        fontSize: 34,
        height: 1.08,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.1,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        height: 1.15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.25,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.45),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4),
      bodySmall: TextStyle(fontSize: 12, height: 1.35),
      labelLarge: TextStyle(
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w700,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
    final resolvedText = text.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? AppColors.navyDark : AppColors.cream,
      textTheme: resolvedText,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [
        AppSemanticColors(
          gold: dark ? const Color(0xFFE0B75F) : AppColors.gold,
          onGold: dark ? AppColors.darkText : AppColors.navyDark,
          goldContainer: dark ? const Color(0xFF493B20) : AppColors.goldSoft,
          success: dark ? const Color(0xFF72D5A6) : AppColors.fresh,
          successContainer: dark
              ? const Color(0xFF123D32)
              : AppColors.successSoft,
          warning: dark ? const Color(0xFFFFC86A) : const Color(0xFF855600),
          warningContainer: dark
              ? const Color(0xFF4A3617)
              : AppColors.warningSoft,
          muted: dark ? AppColors.darkMuted : AppColors.muted,
          qr: dark ? AppColors.navyDark : AppColors.navyDark,
        ),
      ],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? AppColors.navyDark : AppColors.cream,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleSpacing: AppSpacing.md,
        titleTextStyle: resolvedText.headlineSmall,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: const Color(0x00000000),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(AppRadii.card)),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 52),
          elevation: 0,
          textStyle: resolvedText.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          textStyle: resolvedText.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          textStyle: resolvedText.labelLarge,
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(
            Radius.circular(AppRadii.control),
          ),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(
            Radius.circular(AppRadii.control),
          ),
          borderSide: BorderSide(color: scheme.outline),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.small),
        ),
        labelStyle: resolvedText.labelMedium,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: scheme.surface,
        indicatorColor: dark
            ? const Color(0xFF244D72)
            : const Color(0xFFDCEBFA),
        elevation: 0,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => resolvedText.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : dark
                ? AppColors.darkMuted
                : AppColors.muted,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: const Color(0x00000000),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.hero)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? const Color(0xFF173B59) : AppColors.ink,
        contentTextStyle: resolvedText.bodyMedium?.copyWith(
          color: AppColors.darkText,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.control)),
        ),
      ),
    );
  }
}
