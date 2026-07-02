import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/gis_palette.dart';
import '../viewmodels/theme_viewmodel.dart';

enum ThemeToggleStyle { icon, pill }

/// Bascule thème sombre / clair — style Supabase / Google (icône accessible partout).
class ThemeToggleButton extends StatelessWidget {
  final bool compact;
  final ThemeToggleStyle style;

  const ThemeToggleButton({
    super.key,
    this.compact = false,
    this.style = ThemeToggleStyle.icon,
  });

  @override
  Widget build(BuildContext context) {
    final themeVm = context.watch<ThemeViewModel>();
    final p = GisPalette.of(context);
    final isDark = themeVm.isDark;

    void toggle() {
      HapticFeedback.selectionClick();
      themeVm.toggle();
    }

    final icon = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) => RotationTransition(
        turns: Tween<double>(begin: 0.75, end: 1).animate(anim),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: Icon(
        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        key: ValueKey(isDark),
        size: compact ? 20 : 22,
        color: style == ThemeToggleStyle.pill ? p.textMute : p.text,
      ),
    );

    if (style == ThemeToggleStyle.pill) {
      return Tooltip(
        message: isDark ? 'Passer en mode clair' : 'Passer en mode sombre',
        waitDuration: const Duration(milliseconds: 400),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: toggle,
            borderRadius: BorderRadius.circular(20),
            hoverColor: p.sidebarHover.withValues(alpha: 0.5),
            child: Ink(
              height: compact ? 36 : 40,
              padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
              decoration: BoxDecoration(
                color: p.surfaceHi.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: p.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  if (!compact) ...[
                    const SizedBox(width: 8),
                    Text(
                      isDark ? 'Mode clair' : 'Mode sombre',
                      style: TextStyle(
                        color: p.textMute,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: isDark ? 'Mode clair' : 'Mode sombre',
      child: IconButton(
        onPressed: toggle,
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
        icon: icon,
      ),
    );
  }
}

/// Coin supérieur droit pour pages auth / onboarding (login, setup boutique…).
class ThemeToggleOverlay extends StatelessWidget {
  final Widget child;

  const ThemeToggleOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 520;
    return Stack(
      children: [
        child,
        Positioned(
          top: 4,
          right: 8,
          child: SafeArea(
            minimum: const EdgeInsets.only(top: 4, right: 4),
            child: ThemeToggleButton(
              style: ThemeToggleStyle.pill,
              compact: narrow,
            ),
          ),
        ),
      ],
    );
  }
}
