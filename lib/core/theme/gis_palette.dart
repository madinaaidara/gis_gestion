import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'gis_theme_ext.dart';

/// Palette complète Gis Gestion — sombre (défaut Spotify) ou claire.
@immutable
class GisPalette extends ThemeExtension<GisPalette> {
  final Color bg;
  final Color scaffold;
  final Color surface;
  final Color surfaceHi;
  final Color surfaceMuted;
  final Color border;
  final Color borderStrong;
  final Color text;
  final Color textMute;
  final Color textDim;
  final Color accent;
  final Color accentSoft;
  final Color success;
  final Color danger;
  final Color warning;
  final Color info;
  final Color gold;
  final Color sidebarBg;
  final Color sidebarHover;
  final Color sidebarActive;
  final Color sidebarText;
  final Color sidebarTextSelected;
  final Color sidebarBorder;
  final Color topBarBg;

  const GisPalette({
    required this.bg,
    required this.scaffold,
    required this.surface,
    required this.surfaceHi,
    required this.surfaceMuted,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.textMute,
    required this.textDim,
    required this.accent,
    required this.accentSoft,
    required this.success,
    required this.danger,
    required this.warning,
    required this.info,
    required this.gold,
    required this.sidebarBg,
    required this.sidebarHover,
    required this.sidebarActive,
    required this.sidebarText,
    required this.sidebarTextSelected,
    required this.sidebarBorder,
    required this.topBarBg,
  });

  /// Mode sombre — défaut (style Spotify / Linear).
  static const dark = GisPalette(
    bg: Color(0xFF0A0A0B),
    scaffold: Color(0xFF0A0A0B),
    surface: Color(0xFF141416),
    surfaceHi: Color(0xFF1C1C1F),
    surfaceMuted: Color(0xFF101012),
    border: Color(0xFF2C2C30),
    borderStrong: Color(0xFF3D3D44),
    text: Color(0xFFFAFAFA),
    textMute: Color(0xFFA8A8B0),
    textDim: Color(0xFF909098),
    accent: Color(0xFF7C5CFF),
    accentSoft: Color(0xFFB8A4FF),
    success: Color(0xFF22C55E),
    danger: Color(0xFFFF4D6D),
    warning: Color(0xFFF59E0B),
    info: Color(0xFF3B82F6),
    gold: Color(0xFFFBBF24),
    sidebarBg: Color(0xFF000000),
    sidebarHover: Color(0xFF1C1C1C),
    sidebarActive: Color(0xFF282828),
    sidebarText: Color(0xFFB3B3B3),
    sidebarTextSelected: Color(0xFFFFFFFF),
    sidebarBorder: Color(0xFF1F1F1F),
    topBarBg: Color(0xFF0A0A0B),
  );

  /// Mode clair — style admin Shopify (contraste élevé).
  static const light = GisPalette(
    bg: Color(0xFFF1F2F4),
    scaffold: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceHi: Color(0xFFF6F6F7),
    surfaceMuted: Color(0xFFFAFAFA),
    border: Color(0xFFE1E3E5),
    borderStrong: Color(0xFFC9CCCF),
    text: Color(0xFF1A1A1A),
    textMute: Color(0xFF616161),
    textDim: Color(0xFF757575),
    accent: Color(0xFF7C5CFF),
    accentSoft: Color(0xFF6366F1),
    success: Color(0xFF22C55E),
    danger: Color(0xFFEF4444),
    warning: Color(0xFFF59E0B),
    info: Color(0xFF3B82F6),
    gold: Color(0xFFFBBF24),
    sidebarBg: Color(0xFFFFFFFF),
    sidebarHover: Color(0xFFF6F6F7),
    sidebarActive: Color(0xFFF1F1F1),
    sidebarText: Color(0xFF303030),
    sidebarTextSelected: Color(0xFF1A1A1A),
    sidebarBorder: Color(0xFFE1E3E5),
    topBarBg: Color(0xFFFFFFFF),
  );

  static GisPalette of(BuildContext context) {
    return Theme.of(context).extension<GisPalette>() ?? dark;
  }

  @override
  GisPalette copyWith({
    Color? bg,
    Color? scaffold,
    Color? surface,
    Color? surfaceHi,
    Color? surfaceMuted,
    Color? border,
    Color? borderStrong,
    Color? text,
    Color? textMute,
    Color? textDim,
    Color? accent,
    Color? accentSoft,
    Color? success,
    Color? danger,
    Color? warning,
    Color? info,
    Color? gold,
    Color? sidebarBg,
    Color? sidebarHover,
    Color? sidebarActive,
    Color? sidebarText,
    Color? sidebarTextSelected,
    Color? sidebarBorder,
    Color? topBarBg,
  }) {
    return GisPalette(
      bg: bg ?? this.bg,
      scaffold: scaffold ?? this.scaffold,
      surface: surface ?? this.surface,
      surfaceHi: surfaceHi ?? this.surfaceHi,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      text: text ?? this.text,
      textMute: textMute ?? this.textMute,
      textDim: textDim ?? this.textDim,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      gold: gold ?? this.gold,
      sidebarBg: sidebarBg ?? this.sidebarBg,
      sidebarHover: sidebarHover ?? this.sidebarHover,
      sidebarActive: sidebarActive ?? this.sidebarActive,
      sidebarText: sidebarText ?? this.sidebarText,
      sidebarTextSelected: sidebarTextSelected ?? this.sidebarTextSelected,
      sidebarBorder: sidebarBorder ?? this.sidebarBorder,
      topBarBg: topBarBg ?? this.topBarBg,
    );
  }

  @override
  GisPalette lerp(ThemeExtension<GisPalette>? other, double t) {
    if (other is! GisPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return GisPalette(
      bg: l(bg, other.bg),
      scaffold: l(scaffold, other.scaffold),
      surface: l(surface, other.surface),
      surfaceHi: l(surfaceHi, other.surfaceHi),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      border: l(border, other.border),
      borderStrong: l(borderStrong, other.borderStrong),
      text: l(text, other.text),
      textMute: l(textMute, other.textMute),
      textDim: l(textDim, other.textDim),
      accent: l(accent, other.accent),
      accentSoft: l(accentSoft, other.accentSoft),
      success: l(success, other.success),
      danger: l(danger, other.danger),
      warning: l(warning, other.warning),
      info: l(info, other.info),
      gold: l(gold, other.gold),
      sidebarBg: l(sidebarBg, other.sidebarBg),
      sidebarHover: l(sidebarHover, other.sidebarHover),
      sidebarActive: l(sidebarActive, other.sidebarActive),
      sidebarText: l(sidebarText, other.sidebarText),
      sidebarTextSelected: l(sidebarTextSelected, other.sidebarTextSelected),
      sidebarBorder: l(sidebarBorder, other.sidebarBorder),
      topBarBg: l(topBarBg, other.topBarBg),
    );
  }
}

ThemeData _buildGisTheme({required GisPalette p, required Brightness brightness}) {
  final inputTheme = gisInputDecorationTheme(p);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: p.bg,
    extensions: [p],
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: p.accent,
      brightness: brightness,
      surface: p.surface,
      primary: p.accent,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: brightness == Brightness.dark ? p.topBarBg : p.scaffold,
      foregroundColor: p.text,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: inputTheme,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.text,
        side: BorderSide(color: p.borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.border),
      ),
      titleTextStyle: TextStyle(color: p.text, fontSize: 17, fontWeight: FontWeight.w700),
      contentTextStyle: TextStyle(color: p.textMute, fontSize: 14),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.surfaceHi,
      contentTextStyle: TextStyle(color: p.text, fontSize: 13),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(color: p.border, thickness: 1),
    chipTheme: ChipThemeData(
      backgroundColor: p.surfaceHi,
      selectedColor: p.accent.withValues(alpha: 0.18),
      labelStyle: TextStyle(color: p.text, fontSize: 13),
      side: BorderSide(color: p.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.accent,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
    iconTheme: IconThemeData(color: p.textMute),
  );
}

ThemeData gisLightTheme() => _buildGisTheme(p: GisPalette.light, brightness: Brightness.light);

ThemeData gisDarkTheme() => _buildGisTheme(p: GisPalette.dark, brightness: Brightness.dark);
