import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/gis_palette.dart';
import '../../core/theme/gis_theme_ext.dart';
import 'global_search_overlay.dart';
import 'responsive_navigation.dart';
import 'gis_assistant_host.dart';
import 'theme_toggle_button.dart';

/// Barre supérieure style Spotify : titre page + recherche globale.
class SpotifyTopBar extends StatelessWidget {
  final int currentIndex;
  final List<NavDestination> destinations;
  final void Function(int navIndex, {String? productQuery, String? clientQuery}) onNavigate;
  final VoidCallback? onOpenSearch;

  const SpotifyTopBar({
    super.key,
    required this.currentIndex,
    required this.destinations,
    required this.onNavigate,
    this.onOpenSearch,
  });

  String get _pageTitle {
    if (currentIndex < destinations.length) return destinations[currentIndex].label;
    if (currentIndex == 6) return 'Profil';
    return 'Gis Gestion';
  }

  void _openSearch(BuildContext context) {
    if (onOpenSearch != null) {
      onOpenSearch!();
    } else {
      GlobalSearchOverlay.show(context, onNavigate: onNavigate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = GisPalette.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 900;

    return Container(
      height: compact ? 56 : 64,
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 28),
      decoration: BoxDecoration(
        color: p.topBarBg,
        border: Border(bottom: BorderSide(color: p.border)),
        boxShadow: p.isDark(context)
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          if (!compact)
            Text(
              _pageTitle,
              style: GoogleFonts.plusJakartaSans(
                color: p.text,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          const Spacer(),
          const ThemeToggleButton(compact: true),
          const GisAssistantToolbarButton(),
          _SearchPill(compact: compact, onTap: () => _openSearch(context)),
        ],
      ),
    );
  }
}

class _SearchPill extends StatefulWidget {
  final bool compact;
  final VoidCallback onTap;

  const _SearchPill({required this.compact, required this.onTap});

  @override
  State<_SearchPill> createState() => _SearchPillState();
}

class _SearchPillState extends State<_SearchPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = GisPalette.of(context);
    if (widget.compact) {
      return IconButton(
        onPressed: widget.onTap,
        icon: Icon(Icons.search_rounded, color: p.text),
        tooltip: 'Rechercher (Ctrl+K)',
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 280,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: p.isDark(context) ? p.surfaceHi : p.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _hovered ? p.accent.withValues(alpha: 0.4) : p.border),
            boxShadow: p.isDark(context) ? null : p.cardShadow(context).take(1).toList(),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 20, color: p.textMute),
              const SizedBox(width: 10),
              Text(
                'Rechercher…  Ctrl+K',
                style: GoogleFonts.plusJakartaSans(
                  color: p.textMute,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
