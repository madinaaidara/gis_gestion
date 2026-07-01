import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart' as th;
import 'global_search_overlay.dart';
import 'responsive_navigation.dart';
import 'gis_assistant_host.dart';

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
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 900;

    return Container(
      height: compact ? 52 : 64,
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 24),
      decoration: const BoxDecoration(
        color: Color(0xFF050505),
        border: Border(bottom: BorderSide(color: Color(0xFF1A1A1A), width: 1)),
      ),
      child: Row(
        children: [
          if (!compact)
            Text(
              _pageTitle,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          const Spacer(),
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
    if (widget.compact) {
      return IconButton(
        onPressed: widget.onTap,
        icon: const Icon(Icons.search_rounded, color: Colors.white),
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
            color: _hovered ? Colors.white : th.AppColors.sidebarText,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 20, color: _hovered ? Colors.black : th.AppColors.sidebarBg),
              const SizedBox(width: 10),
              Text(
                'Rechercher…  Ctrl+K',
                style: GoogleFonts.plusJakartaSans(
                  color: _hovered ? Colors.black54 : th.AppColors.sidebarBg.withValues(alpha: 0.7),
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
