import 'package:flutter/material.dart';

import 'gis_palette.dart';

/// Helpers décoratifs — cohérents en mode sombre et clair.
extension GisThemeExt on GisPalette {
  bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  List<Color> get accentGradient => [accent, Color.lerp(accent, const Color(0xFF5B3FE6), 0.5)!];

  LinearGradient accentLinear({Alignment begin = Alignment.topLeft, Alignment end = Alignment.bottomRight}) =>
      LinearGradient(begin: begin, end: end, colors: accentGradient);

  List<BoxShadow> cardShadow(BuildContext context) {
    if (isDark(context)) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.02),
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
    ];
  }

  BoxDecoration cardDecoration(BuildContext context, {double radius = 14, Color? color, bool bordered = true}) {
    return BoxDecoration(
      color: color ?? surface,
      borderRadius: BorderRadius.circular(radius),
      border: bordered ? Border.all(color: border) : null,
      boxShadow: cardShadow(context),
    );
  }

  BoxDecoration heroDecoration(BuildContext context, {double radius = 16}) {
    if (isDark(context)) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.28),
            surfaceHi,
            surface,
          ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      );
    }
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderStrong),
      boxShadow: cardShadow(context),
    );
  }

  InputDecoration searchInputDecoration({
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: textMute, fontSize: 13, fontWeight: FontWeight.w500),
      border: InputBorder.none,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
    );
  }
}

InputDecorationTheme gisInputDecorationTheme(GisPalette p) {
  return InputDecorationTheme(
    filled: true,
    fillColor: p.surfaceHi,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: TextStyle(color: p.textMute, fontSize: 14),
    labelStyle: TextStyle(color: p.textMute, fontSize: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: p.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: p.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: p.accent, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: p.danger),
    ),
  );
}
