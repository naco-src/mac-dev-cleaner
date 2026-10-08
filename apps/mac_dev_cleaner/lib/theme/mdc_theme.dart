import 'package:flutter/material.dart';

/// Brand seed — calm forest green (safe, trustworthy cleanup).
const Color kMdcBrandSeed = Color(0xFF2D6A4F);

/// Dark-theme accent aligned with developer-tool palettes (run / reclaim).
const Color kMdcDarkAccentSeed = Color(0xFF22C55E);

/// Monospace stack for paths, IDs, and log lines (macOS-friendly).
const List<String> kMdcMonospaceFamily = ['Menlo', 'Courier', 'monospace'];

@immutable
class MdcSemanticColors extends ThemeExtension<MdcSemanticColors> {
  const MdcSemanticColors({
    required this.riskSafeFg,
    required this.riskSafeBg,
    required this.riskConditionalFg,
    required this.riskConditionalBg,
    required this.riskProtectedFg,
    required this.riskProtectedBg,
    required this.logWarning,
  });

  final Color riskSafeFg;
  final Color riskSafeBg;
  final Color riskConditionalFg;
  final Color riskConditionalBg;
  final Color riskProtectedFg;
  final Color riskProtectedBg;
  final Color logWarning;

  static MdcSemanticColors of(BuildContext context) {
    return Theme.of(context).extension<MdcSemanticColors>() ??
        MdcSemanticColors.light(Theme.of(context).colorScheme);
  }

  static MdcSemanticColors light(ColorScheme scheme) {
    return MdcSemanticColors(
      riskSafeFg: const Color(0xFF1B4332),
      riskSafeBg: const Color(0xFFD8F3DC),
      riskConditionalFg: const Color(0xFF9A3412),
      riskConditionalBg: const Color(0xFFFFEDD5),
      riskProtectedFg: const Color(0xFF475569),
      riskProtectedBg: const Color(0xFFE2E8F0),
      logWarning: const Color(0xFFC2410C),
    );
  }

  static MdcSemanticColors dark(ColorScheme scheme) {
    return MdcSemanticColors(
      riskSafeFg: const Color(0xFF86EFAC),
      riskSafeBg: const Color(0xFF14532D),
      riskConditionalFg: const Color(0xFFFDBA74),
      riskConditionalBg: const Color(0xFF7C2D12),
      riskProtectedFg: const Color(0xFFCBD5E1),
      riskProtectedBg: const Color(0xFF334155),
      logWarning: const Color(0xFFFDBA74),
    );
  }

  @override
  MdcSemanticColors copyWith({
    Color? riskSafeFg,
    Color? riskSafeBg,
    Color? riskConditionalFg,
    Color? riskConditionalBg,
    Color? riskProtectedFg,
    Color? riskProtectedBg,
    Color? logWarning,
  }) {
    return MdcSemanticColors(
      riskSafeFg: riskSafeFg ?? this.riskSafeFg,
      riskSafeBg: riskSafeBg ?? this.riskSafeBg,
      riskConditionalFg: riskConditionalFg ?? this.riskConditionalFg,
      riskConditionalBg: riskConditionalBg ?? this.riskConditionalBg,
      riskProtectedFg: riskProtectedFg ?? this.riskProtectedFg,
      riskProtectedBg: riskProtectedBg ?? this.riskProtectedBg,
      logWarning: logWarning ?? this.logWarning,
    );
  }

  @override
  MdcSemanticColors lerp(MdcSemanticColors? other, double t) {
    if (other == null) {
      return this;
    }
    return MdcSemanticColors(
      riskSafeFg: Color.lerp(riskSafeFg, other.riskSafeFg, t)!,
      riskSafeBg: Color.lerp(riskSafeBg, other.riskSafeBg, t)!,
      riskConditionalFg: Color.lerp(
        riskConditionalFg,
        other.riskConditionalFg,
        t,
      )!,
      riskConditionalBg: Color.lerp(
        riskConditionalBg,
        other.riskConditionalBg,
        t,
      )!,
      riskProtectedFg: Color.lerp(riskProtectedFg, other.riskProtectedFg, t)!,
      riskProtectedBg: Color.lerp(riskProtectedBg, other.riskProtectedBg, t)!,
      logWarning: Color.lerp(logWarning, other.logWarning, t)!,
    );
  }
}

extension MdcTextTheme on BuildContext {
  TextStyle? get monoBodySmall {
    final base = Theme.of(this).textTheme.bodySmall;
    if (base == null) {
      return const TextStyle(
        fontFamilyFallback: kMdcMonospaceFamily,
        fontSize: 12,
      );
    }
    return base.copyWith(fontFamilyFallback: kMdcMonospaceFamily);
  }

  TextStyle? get monoLabelSmall {
    final base = Theme.of(this).textTheme.labelSmall;
    if (base == null) {
      return const TextStyle(
        fontFamilyFallback: kMdcMonospaceFamily,
        fontSize: 11,
      );
    }
    return base.copyWith(fontFamilyFallback: kMdcMonospaceFamily);
  }
}

ThemeData buildMdcLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kMdcBrandSeed,
    brightness: Brightness.light,
  );
  return _buildMdcTheme(scheme, MdcSemanticColors.light(scheme));
}

ThemeData buildMdcDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kMdcDarkAccentSeed,
    brightness: Brightness.dark,
    surface: const Color(0xFF0F172A),
  );
  return _buildMdcTheme(scheme, MdcSemanticColors.dark(scheme));
}

ThemeData _buildMdcTheme(ColorScheme scheme, MdcSemanticColors semantic) {
  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.compact,
    extensions: [semantic],
  );

  final outlineVariant = scheme.outlineVariant;

  return base.copyWith(
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: scheme.surfaceTint,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      indicatorColor: scheme.secondaryContainer,
      selectedIconTheme: IconThemeData(color: scheme.onSecondaryContainer),
      selectedLabelTextStyle: TextStyle(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: scheme.onSurfaceVariant,
        fontSize: 12,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: outlineVariant),
      ),
      color: scheme.surfaceContainerLowest,
    ),
    listTileTheme: const ListTileThemeData(
      dense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      horizontalTitleGap: 8,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: scheme.primary,
      unselectedLabelColor: scheme.onSurfaceVariant,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: outlineVariant,
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    chipTheme: ChipThemeData(
      side: BorderSide(color: outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: TextStyle(color: scheme.onSurface, fontSize: 13),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
    ),
    dividerTheme: DividerThemeData(color: outlineVariant, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder()},
    ),
  );
}
