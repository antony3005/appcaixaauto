import 'package:flutter/material.dart';

/// Tokens do design system 24/7 (App Cliente).
///
/// Cores fixas da marca, iguais nos dois temas. As que mudam entre claro e
/// escuro vivem em [AppSemanticColors] e no [ColorScheme].
abstract final class AppColors {
  static const navy = Color(0xFF082F5B);
  static const navyDark = Color(0xFF031B35);
  static const onNavy = Color(0xFFF4F7FB);
  static const onNavyMuted = Color(0xFFA9B9CA);
  static const blue = Color(0xFF146CC5);
  static const qrPaper = Color(0xFFFDFEFF);
  static const qrInk = Color(0xFF031B35);
}

/// Espaçamento `space-1` … `space-10`.
abstract final class AppSpacing {
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
  static const s10 = 40.0;

  /// Margem lateral da tela.
  static const gutter = s4;

  /// Distância entre seções.
  static const section = s6;
}

abstract final class AppRadii {
  static const xs = 6.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const pill = 999.0;
}

abstract final class AppSizes {
  static const control = 48.0;
  static const navHeight = 72.0;
  static const contentMax = 480.0;
  static const tapTarget = 48.0;
  static const iconSm = 16.0;
  static const iconMd = 20.0;
  static const iconLg = 24.0;
  static const well = 40.0;
}

abstract final class AppAnimations {
  static const press = Duration(milliseconds: 120);
  static const short = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 220);
  static const long = Duration(milliseconds: 360);
  static const standard = Curves.easeOutCubic;
  static const emphasized = Curves.easeOutQuart;
  static const exit = Curves.easeInCubic;
}

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.background,
    required this.muted,
    required this.fieldLine,
    required this.primarySoft,
    required this.gold,
    required this.onGold,
    required this.goldContainer,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.errorContainer,
    required this.cardShadow,
    required this.raisedShadow,
  });

  final Color background, muted, fieldLine, primarySoft;
  final Color gold, onGold, goldContainer;
  final Color success, successContainer;
  final Color warning, warningContainer;
  final Color errorContainer;
  final List<BoxShadow> cardShadow, raisedShadow;

  static const light = AppSemanticColors(
    background: Color(0xFFFFFFFF),
    muted: Color(0xFF607389),
    fieldLine: Color(0xFF607389),
    primarySoft: Color(0xFFDCEBFA),
    gold: Color(0xFFC89B3C),
    onGold: Color(0xFF031B35),
    goldContainer: Color(0xFFF8EFD9),
    success: Color(0xFF238B61),
    successContainer: Color(0xFFE2F5EC),
    warning: Color(0xFF855600),
    warningContainer: Color(0xFFFFF2D8),
    errorContainer: Color(0xFFFBE8E4),
    cardShadow: [
      BoxShadow(color: Color(0x0F082F5B), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x0A082F5B), blurRadius: 16, offset: Offset(0, 6)),
    ],
    raisedShadow: [
      BoxShadow(color: Color(0x12082F5B), blurRadius: 24, offset: Offset(0, 8)),
    ],
  );

  static const dark = AppSemanticColors(
    background: Color(0xFF031B35),
    muted: Color(0xFFA9B9CA),
    fieldLine: Color(0xFFA9B9CA),
    primarySoft: Color(0xFF244D72),
    gold: Color(0xFFE0B75F),
    onGold: Color(0xFFF4F7FB),
    goldContainer: Color(0xFF493B20),
    success: Color(0xFF72D5A6),
    successContainer: Color(0xFF123D32),
    warning: Color(0xFFFFC86A),
    warningContainer: Color(0xFF4A3617),
    errorContainer: Color(0xFF4A1F1C),
    cardShadow: [],
    raisedShadow: [
      BoxShadow(color: Color(0x33020F1D), blurRadius: 20, offset: Offset(0, 8)),
    ],
  );

  @override
  AppSemanticColors copyWith({
    Color? background,
    Color? muted,
    Color? fieldLine,
    Color? primarySoft,
    Color? gold,
    Color? onGold,
    Color? goldContainer,
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? errorContainer,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? raisedShadow,
  }) => AppSemanticColors(
    background: background ?? this.background,
    muted: muted ?? this.muted,
    fieldLine: fieldLine ?? this.fieldLine,
    primarySoft: primarySoft ?? this.primarySoft,
    gold: gold ?? this.gold,
    onGold: onGold ?? this.onGold,
    goldContainer: goldContainer ?? this.goldContainer,
    success: success ?? this.success,
    successContainer: successContainer ?? this.successContainer,
    warning: warning ?? this.warning,
    warningContainer: warningContainer ?? this.warningContainer,
    errorContainer: errorContainer ?? this.errorContainer,
    cardShadow: cardShadow ?? this.cardShadow,
    raisedShadow: raisedShadow ?? this.raisedShadow,
  );

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppSemanticColors(
      background: mix(background, other.background),
      muted: mix(muted, other.muted),
      fieldLine: mix(fieldLine, other.fieldLine),
      primarySoft: mix(primarySoft, other.primarySoft),
      gold: mix(gold, other.gold),
      onGold: mix(onGold, other.onGold),
      goldContainer: mix(goldContainer, other.goldContainer),
      success: mix(success, other.success),
      successContainer: mix(successContainer, other.successContainer),
      warning: mix(warning, other.warning),
      warningContainer: mix(warningContainer, other.warningContainer),
      errorContainer: mix(errorContainer, other.errorContainer),
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t) ?? [],
      raisedShadow:
          BoxShadow.lerpList(raisedShadow, other.raisedShadow, t) ?? [],
    );
  }
}

extension AppThemeContext on BuildContext {
  AppSemanticColors get semantic =>
      Theme.of(this).extension<AppSemanticColors>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Preço no detalhe do produto (`price`).
  TextStyle get priceStyle => Theme.of(this).textTheme.headlineSmall!.copyWith(
    fontSize: 22,
    height: 1.15,
    letterSpacing: -0.4,
  );

  /// Rótulo em caixa alta acima de títulos e nos cartões de destaque.
  TextStyle get eyebrowStyle => Theme.of(this).textTheme.labelSmall!;
}

abstract final class AppTheme {
  static const fontFamily = 'PlusJakartaSans';

  static ThemeData light() => _theme(Brightness.light);
  static ThemeData dark() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final semantic = dark ? AppSemanticColors.dark : AppSemanticColors.light;
    final ink = dark ? const Color(0xFFF4F7FB) : const Color(0xFF10243B);
    final outline = dark ? const Color(0xFF234563) : const Color(0xFFDCE4EE);
    final surfaceHigh = dark
        ? const Color(0xFF123553)
        : const Color(0xFFE7EDF4);
    final scheme = ColorScheme(
      brightness: brightness,
      primary: dark ? const Color(0xFF78B7F4) : AppColors.navy,
      onPrimary: dark ? AppColors.navyDark : Colors.white,
      primaryContainer: semantic.primarySoft,
      onPrimaryContainer: ink,
      secondary: semantic.gold,
      onSecondary: AppColors.navyDark,
      secondaryContainer: semantic.goldContainer,
      onSecondaryContainer: semantic.onGold,
      tertiary: semantic.success,
      onTertiary: dark ? AppColors.navyDark : Colors.white,
      tertiaryContainer: semantic.successContainer,
      onTertiaryContainer: ink,
      error: dark ? const Color(0xFFFFB4A9) : const Color(0xFFBA1A1A),
      onError: dark ? AppColors.navyDark : Colors.white,
      errorContainer: semantic.errorContainer,
      onErrorContainer: dark
          ? const Color(0xFFFFB4A9)
          : const Color(0xFFBA1A1A),
      surface: dark ? const Color(0xFF0B2847) : const Color(0xFFFCFDFE),
      onSurface: ink,
      onSurfaceVariant: semantic.muted,
      surfaceContainerLowest: semantic.background,
      surfaceContainerLow: dark
          ? const Color(0xFF07223D)
          : const Color(0xFFF4F7FB),
      surfaceContainer: dark
          ? const Color(0xFF0B2847)
          : const Color(0xFFEEF3F8),
      surfaceContainerHigh: surfaceHigh,
      surfaceContainerHighest: surfaceHigh,
      outline: outline,
      outlineVariant: outline,
      inverseSurface: dark ? const Color(0xFFF4F7FB) : const Color(0xFF10243B),
      onInverseSurface: dark ? AppColors.navyDark : AppColors.onNavy,
      inversePrimary: dark ? AppColors.navy : const Color(0xFF78B7F4),
      shadow: const Color(0xFF020F1D),
      scrim: const Color(0xFF020F1D),
      surfaceTint: Colors.transparent,
    );

    final text = TextTheme(
      displaySmall: const TextStyle(
        fontSize: 32,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      headlineMedium: const TextStyle(
        fontSize: 26,
        height: 1.15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
      ),
      headlineSmall: const TextStyle(
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      titleLarge: const TextStyle(
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: const TextStyle(
        fontSize: 14,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: const TextStyle(fontSize: 16, height: 1.5),
      bodyMedium: const TextStyle(fontSize: 14, height: 1.45),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: semantic.muted,
      ),
      labelLarge: const TextStyle(
        fontSize: 13,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
      labelMedium: const TextStyle(
        fontSize: 12,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      labelSmall: const TextStyle(
        fontSize: 10,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    ).apply(fontFamily: fontFamily, bodyColor: ink, displayColor: ink);
    final bodySmall = text.bodySmall!.copyWith(color: semantic.muted);
    final resolvedText = text.copyWith(bodySmall: bodySmall);

    WidgetStateProperty<Color?> overlay(Color color) =>
        WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return color.withValues(alpha: .12);
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return color.withValues(alpha: .08);
          }
          return null;
        });

    const pill = StadiumBorder();
    final focusSide = BorderSide(color: ink, width: 2);
    final buttonPadding = const EdgeInsets.symmetric(horizontal: AppSpacing.s6);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: semantic.background,
      canvasColor: semantic.background,
      textTheme: resolvedText,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkRipple.splashFactory,
      extensions: [semantic],
      iconTheme: IconThemeData(color: ink, size: AppSizes.iconLg),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: semantic.background,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleSpacing: AppSpacing.s3,
        titleTextStyle: resolvedText.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(AppRadii.md)),
          side: BorderSide(color: outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(64, AppSizes.control)),
          padding: WidgetStatePropertyAll(buttonPadding),
          shape: const WidgetStatePropertyAll(pill),
          elevation: const WidgetStatePropertyAll(0),
          textStyle: WidgetStatePropertyAll(resolvedText.labelLarge),
          iconSize: const WidgetStatePropertyAll(AppSizes.iconMd),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? scheme.primary.withValues(alpha: .4)
                : scheme.primary,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? scheme.onPrimary.withValues(alpha: .85)
                : scheme.onPrimary,
          ),
          overlayColor: overlay(scheme.onPrimary),
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused) ? focusSide : null,
          ),
          animationDuration: AppAnimations.press,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, AppSizes.control),
          padding: buttonPadding,
          shape: pill,
          elevation: 0,
          textStyle: resolvedText.labelLarge,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(64, AppSizes.control)),
          padding: WidgetStatePropertyAll(buttonPadding),
          shape: const WidgetStatePropertyAll(pill),
          textStyle: WidgetStatePropertyAll(resolvedText.labelLarge),
          iconSize: const WidgetStatePropertyAll(AppSizes.iconMd),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? ink.withValues(alpha: .4)
                : ink,
          ),
          overlayColor: overlay(ink),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) return focusSide;
            return BorderSide(
              color: states.contains(WidgetState.disabled)
                  ? semantic.fieldLine.withValues(alpha: .4)
                  : semantic.fieldLine,
              width: 1.5,
            );
          }),
          animationDuration: AppAnimations.press,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 44)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: AppSpacing.s2),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            resolvedText.labelMedium?.copyWith(fontSize: 13, letterSpacing: 0),
          ),
          iconSize: const WidgetStatePropertyAll(AppSizes.iconMd),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? scheme.primary.withValues(alpha: .4)
                : scheme.primary,
          ),
          overlayColor: overlay(scheme.primary),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size.square(AppSizes.tapTarget),
          ),
          iconSize: const WidgetStatePropertyAll(AppSizes.iconLg),
          foregroundColor: WidgetStatePropertyAll(ink),
          overlayColor: overlay(ink),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 2,
          vertical: AppSpacing.s3,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 36,
          minHeight: AppSizes.control,
        ),
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.error)) return scheme.error;
          if (states.contains(WidgetState.focused)) return scheme.primary;
          return semantic.muted;
        }),
        suffixIconColor: semantic.muted,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintStyle: resolvedText.bodyMedium?.copyWith(color: semantic.muted),
        labelStyle: resolvedText.titleSmall?.copyWith(fontSize: 15),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
          final color = states.contains(WidgetState.error)
              ? scheme.error
              : states.contains(WidgetState.focused)
              ? scheme.primary
              : ink;
          return resolvedText.titleSmall!.copyWith(fontSize: 15, color: color);
        }),
        helperStyle: bodySmall,
        errorStyle: bodySmall.copyWith(color: scheme.error),
        errorMaxLines: 3,
        counterStyle: bodySmall,
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: semantic.fieldLine),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: semantic.fieldLine),
        ),
        disabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: semantic.fieldLine.withValues(alpha: .4),
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: .24),
        selectionHandleColor: scheme.primary,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: WidgetStateBorderSide.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BorderSide(color: scheme.primary, width: 1.5)
              : BorderSide(color: semantic.fieldLine, width: 1.5),
        ),
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? scheme.primary : null,
        ),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : semantic.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : surfaceHigh,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : semantic.fieldLine,
        ),
        trackOutlineWidth: const WidgetStatePropertyAll(1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : semantic.fieldLine,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainer,
        circularTrackColor: scheme.surfaceContainer,
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: ink,
        titleTextStyle: resolvedText.titleSmall,
        subtitleTextStyle: bodySmall,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: resolvedText.titleLarge,
        contentTextStyle: resolvedText.bodyMedium,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.lg)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: scheme.surface,
        showDragHandle: true,
        dragHandleColor: semantic.fieldLine.withValues(alpha: .5),
        dragHandleSize: const Size(40, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.lg),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? surfaceHigh : const Color(0xFF10243B),
        contentTextStyle: resolvedText.bodyMedium?.copyWith(
          color: AppColors.onNavy,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: const Color(0xFF78B7F4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.md)),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: dark ? surfaceHigh : const Color(0xFF10243B),
          borderRadius: BorderRadius.circular(AppRadii.xs),
        ),
        textStyle: resolvedText.labelMedium?.copyWith(color: AppColors.onNavy),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          semantic.muted.withValues(alpha: .4),
        ),
        radius: const Radius.circular(AppRadii.pill),
      ),
    );
  }
}
