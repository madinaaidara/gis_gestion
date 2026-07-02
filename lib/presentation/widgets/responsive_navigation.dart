import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart' as th;
import '../../core/theme/app_surface.dart';
import '../../core/theme/gis_palette.dart';

import 'global_search_overlay.dart';
import 'spotify_top_bar.dart';
import 'gis_assistant_host.dart';
import 'theme_toggle_button.dart';

/// Navigation responsive style Spotify / SaaS premium :
/// - Desktop : sidebar + top bar recherche
/// - Mobile : bottom nav compact + drawer menu
class ResponsiveNavigation extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final Function(int) onNavigate;
  final void Function(int index, {String? productQuery, String? clientQuery})? onSearchNavigate;
  final VoidCallback? onOpenSearch;
  final List<NavDestination> destinations;
  final int profileNavIndex;

  const ResponsiveNavigation({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onNavigate,
    this.onSearchNavigate,
    this.onOpenSearch,
    required this.destinations,
    this.profileNavIndex = 6,
  });

  @override
  State<ResponsiveNavigation> createState() => _ResponsiveNavigationState();
}

class _ResponsiveNavigationState extends State<ResponsiveNavigation> {
  GisPalette get _p => GisPalette.of(context);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _sidebarExpanded = true;

  void _onItemTapped(int index) {
    if (index == widget.currentIndex) return;
    HapticFeedback.selectionClick();
    widget.onNavigate(index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _handleSearchNavigate(int index, {String? productQuery, String? clientQuery}) {
    if (widget.onSearchNavigate != null) {
      widget.onSearchNavigate!(index, productQuery: productQuery, clientQuery: clientQuery);
    } else {
      widget.onNavigate(index);
    }
  }

  void _openSearch() {
    if (widget.onOpenSearch != null) {
      widget.onOpenSearch!();
    } else {
      GlobalSearchOverlay.show(context, onNavigate: _handleSearchNavigate);
    }
  }

  static const _mobileTabs = [
    (0, Icons.home_outlined, Icons.home_rounded, 'Accueil'),
    (1, Icons.point_of_sale_outlined, Icons.point_of_sale_rounded, 'Caisse'),
    (2, Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Produits'),
    (5, Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Stats'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return Scaffold(
            backgroundColor: AppSurface.bg,
            body: Row(
              children: [
                _DesktopSidebar(
                  destinations: widget.destinations,
                  currentIndex: widget.currentIndex,
                  profileNavIndex: widget.profileNavIndex,
                  onNavigate: _onItemTapped,
                  isExpanded: _sidebarExpanded,
                  onToggleExpand: () {
                    HapticFeedback.selectionClick();
                    setState(() => _sidebarExpanded = !_sidebarExpanded);
                  },
                ),
                Expanded(
                  child: Column(
                    children: [
                      SpotifyTopBar(
                        currentIndex: widget.currentIndex,
                        destinations: widget.destinations,
                        onNavigate: _handleSearchNavigate,
                        onOpenSearch: _openSearch,
                      ),
                      Expanded(child: widget.child),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final isBottomTab = _mobileTabs.any((t) => t.$1 == widget.currentIndex);
        final bottomIndex = isBottomTab
            ? _mobileTabs.indexWhere((t) => t.$1 == widget.currentIndex)
            : 4;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppSurface.bg,
          appBar: AppBar(
            backgroundColor: _p.scaffold,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.menu_rounded, color: AppSurface.text),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            title: Text(
              _mobilePageTitle(),
              style: GoogleFonts.plusJakartaSans(
                color: AppSurface.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            actions: [
              const ThemeToggleButton(compact: true),
              const GisAssistantToolbarButton(compact: true),
              IconButton(
                icon: Icon(Icons.search_rounded, color: AppSurface.text),
                tooltip: 'Rechercher (Ctrl+K)',
                onPressed: _openSearch,
              ),
            ],
          ),
          drawer: _MobileDrawer(
            destinations: widget.destinations,
            currentIndex: widget.currentIndex,
            profileNavIndex: widget.profileNavIndex,
            onNavigate: _onItemTapped,
          ),
          body: widget.child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: bottomIndex.clamp(0, 4),
            backgroundColor: _p.scaffold,
            indicatorColor: _p.sidebarActive,
            height: 64,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (i) {
              if (i == 4) {
                _scaffoldKey.currentState?.openDrawer();
                return;
              }
              _onItemTapped(_mobileTabs[i].$1);
            },
            destinations: [
              for (final t in _mobileTabs)
                NavigationDestination(
                  icon: Icon(t.$2, color: _p.sidebarText),
                  selectedIcon: Icon(t.$3, color: _p.sidebarTextSelected),
                  label: t.$4,
                ),
              NavigationDestination(
                icon: Icon(Icons.menu_rounded, color: _p.sidebarText),
                selectedIcon: Icon(Icons.menu_rounded, color: _p.sidebarTextSelected),
                label: 'Menu',
              ),
            ],
          ),
        );
      },
    );
  }

  String _mobilePageTitle() {
    if (widget.currentIndex < widget.destinations.length) {
      return widget.destinations[widget.currentIndex].label;
    }
    if (widget.currentIndex == widget.profileNavIndex) return 'Profil';
    return 'Gis Gestion';
  }
}

class NavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Color color;

  const NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.color,
  });
}

// ─── Desktop sidebar ─────────────────────────────────────────────────────────

class _DesktopSidebar extends StatefulWidget {
  final List<NavDestination> destinations;
  final int currentIndex;
  final int profileNavIndex;
  final Function(int) onNavigate;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const _DesktopSidebar({
    required this.destinations,
    required this.currentIndex,
    required this.profileNavIndex,
    required this.onNavigate,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  static const expandedWidth = 240.0;
  static const collapsedWidth = 72.0;

  @override
  State<_DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends State<_DesktopSidebar> with SingleTickerProviderStateMixin {
  GisPalette get _p => GisPalette.of(context);

  late AnimationController _widthCtrl;
  late Animation<double> _widthAnim;

  String _userName = 'Utilisateur';
  String _userEmail = '';
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _widthCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: widget.isExpanded ? 1.0 : 0.0,
    );
    _widthAnim = CurvedAnimation(parent: _widthCtrl, curve: Curves.easeInOutCubic);
    _loadUserProfile();
  }

  @override
  void didUpdateWidget(covariant _DesktopSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      widget.isExpanded ? _widthCtrl.forward() : _widthCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _widthCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _loadingProfile = false);
        return;
      }
      var name = user.userMetadata?['full_name']?.toString() ?? user.email?.split('@').first ?? 'Utilisateur';
      try {
        final row = await Supabase.instance.client
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .maybeSingle();
        if (row?['full_name'] != null) name = row!['full_name'].toString();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _userName = name;
          _userEmail = user.email ?? '';
          _loadingProfile = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  String _initials() {
    final parts = _userName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _widthAnim,
      builder: (context, _) {
        final t = _widthAnim.value;
        final width = _DesktopSidebar.collapsedWidth +
            (_DesktopSidebar.expandedWidth - _DesktopSidebar.collapsedWidth) * t;

        return ClipRect(
          child: SizedBox(
            width: width,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _p.sidebarBg,
                border: Border(right: BorderSide(color: _p.sidebarBorder, width: 1)),
              ),
              child: Column(
                children: [
                  _buildHeader(t),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: widget.destinations.length,
                      itemBuilder: (_, i) => _navItem(i, t),
                    ),
                  ),
                  _buildProfile(t),
                  _buildThemeRow(t),
                  _buildToggle(t),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(double t) {
    return SizedBox(
      height: 64,
      child: t < 0.5
          ? Center(child: _logo(36))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _logo(36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Opacity(
                      opacity: ((t - 0.3) / 0.7).clamp(0.0, 1.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gis Gestion',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: _p.sidebarTextSelected,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Gestion boutique',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _p.sidebarText,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _logo(double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        'assets/images/logo_guiss_gestion1.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: th.AppColors.brandAccent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.store_rounded, color: Colors.white, size: size * 0.55),
        ),
      ),
    );
  }

  Widget _navItem(int index, double t) {
    final dest = widget.destinations[index];
    final selected = widget.currentIndex == index;
    final iconColor = selected ? _p.accent : _p.sidebarText;
    final collapsed = t < 0.5;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Tooltip(
        message: collapsed ? dest.label : '',
        waitDuration: const Duration(milliseconds: 400),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => widget.onNavigate(index),
            hoverColor: _p.sidebarHover,
            splashColor: _p.accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 40,
              decoration: BoxDecoration(
                color: selected ? _p.sidebarActive : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: selected ? 3 : 0,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _p.accent,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                    ),
                  ),
                  Expanded(
                    child: collapsed
                        ? Center(
                            child: Icon(
                              selected ? dest.selectedIcon : dest.icon,
                              size: 22,
                              color: iconColor,
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Icon(selected ? dest.selectedIcon : dest.icon, size: 20, color: iconColor),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Opacity(
                                    opacity: t.clamp(0.0, 1.0),
                                    child: Text(
                                      dest.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: selected ? _p.sidebarTextSelected : _p.sidebarText,
                                        fontSize: 13.5,
                                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfile(double t) {
    final active = widget.currentIndex == widget.profileNavIndex;
    final collapsed = t < 0.5;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Material(
        color: active ? _p.sidebarActive : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onNavigate(widget.profileNavIndex);
          },
          hoverColor: _p.sidebarHover,
          child: SizedBox(
            height: 48,
            child: collapsed
                ? Center(child: _avatar(32))
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Opacity(
                      opacity: t.clamp(0.0, 1.0),
                      child: Row(
                        children: [
                          _avatar(32),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _p.sidebarTextSelected,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _userEmail.isNotEmpty ? _userEmail : 'Mon profil',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _p.sidebarText,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: active ? th.AppColors.brandAccent : _p.sidebarText,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _avatar(double size) {
    if (_loadingProfile) {
      return SizedBox(
        width: size,
        height: size,
        child: const CircularProgressIndicator(strokeWidth: 2, color: th.AppColors.brandAccent),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [th.AppColors.brandAccent, Color(0xFF5B3FD4)]),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          _initials(),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildThemeRow(double t) {
    final collapsed = t < 0.5;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: collapsed
          ? const Center(child: ThemeToggleButton(compact: true))
          : Align(
              alignment: Alignment.centerLeft,
              child: Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: const ThemeToggleButton(style: ThemeToggleStyle.pill, compact: true),
              ),
            ),
    );
  }

  Widget _buildToggle(double t) {
    final collapsed = t < 0.5;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: _p.sidebarHover.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onToggleExpand,
          hoverColor: _p.sidebarActive,
          child: SizedBox(
            height: 36,
            child: collapsed
                ? Center(
                    child: Icon(Icons.chevron_right_rounded, color: _p.sidebarText, size: 20),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(Icons.chevron_left_rounded, color: _p.sidebarText, size: 20),
                        const SizedBox(width: 8),
                        Opacity(
                          opacity: t,
                          child: Text(
                            'Réduire',
                            style: TextStyle(
                              color: _p.sidebarText,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Mobile drawer ───────────────────────────────────────────────────────────

class _MobileDrawer extends StatefulWidget {
  final List<NavDestination> destinations;
  final int currentIndex;
  final int profileNavIndex;
  final Function(int) onNavigate;

  const _MobileDrawer({
    required this.destinations,
    required this.currentIndex,
    required this.profileNavIndex,
    required this.onNavigate,
  });

  @override
  State<_MobileDrawer> createState() => _MobileDrawerState();
}

class _MobileDrawerState extends State<_MobileDrawer> {
  GisPalette get _p => GisPalette.of(context);

  String _userName = 'Utilisateur';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    var name = user.email?.split('@').first ?? 'Utilisateur';
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();
      if (row?['full_name'] != null) name = row!['full_name'].toString();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _userName = name;
        _userEmail = user.email ?? '';
      });
    }
  }

  String _initials() {
    final parts = _userName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _p.sidebarBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/logo_guiss_gestion1.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gis Gestion',
                          style: GoogleFonts.plusJakartaSans(
                            color: _p.sidebarTextSelected,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Gestion boutique',
                          style: TextStyle(color: _p.sidebarText, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: _p.sidebarBorder, height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                itemCount: widget.destinations.length,
                itemBuilder: (_, i) => _drawerItem(i),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ThemeToggleButton(style: ThemeToggleStyle.pill, compact: true),
              ),
            ),
            _drawerProfile(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(int index) {
    final dest = widget.destinations[index];
    final selected = widget.currentIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => widget.onNavigate(index),
          splashColor: _p.accent.withValues(alpha: 0.10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: selected ? _p.sidebarActive : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: selected ? 3 : 0,
                  height: 44,
                  color: _p.accent,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          selected ? dest.selectedIcon : dest.icon,
                          color: selected ? _p.accent : _p.sidebarText,
                          size: 22,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            dest.label,
                            style: GoogleFonts.plusJakartaSans(
                              color: selected ? _p.sidebarTextSelected : _p.sidebarText,
                              fontSize: 14,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _drawerProfile() {
    final active = widget.currentIndex == widget.profileNavIndex;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Material(
        color: active ? _p.sidebarActive : _p.sidebarHover.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => widget.onNavigate(widget.profileNavIndex),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [th.AppColors.brandAccent, Color(0xFF5B3FD4)]),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      _initials(),
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: TextStyle(color: _p.sidebarTextSelected, fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _userEmail,
                        style: TextStyle(color: _p.sidebarText, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: active ? th.AppColors.brandAccent : _p.sidebarText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
