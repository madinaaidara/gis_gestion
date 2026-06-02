import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart' as th;

/// ============================================
/// RESPONSIVE NAVIGATION - GIS Gestion
/// ============================================
/// Navigation professionnelle type enterprise:
/// - Desktop (>1200px): Sidebar fixe avec logo + profil
/// - Tablet (600-1200px): Drawer coulissant depuis la gauche
/// - Mobile (<600px): Drawer coulissant depuis la gauche
/// ============================================

class ResponsiveNavigation extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final Function(int) onNavigate;
  final List<NavDestination> destinations;

  const ResponsiveNavigation({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onNavigate,
    required this.destinations,
  });

  @override
  State<ResponsiveNavigation> createState() => _ResponsiveNavigationState();
}

class _ResponsiveNavigationState extends State<ResponsiveNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _sidebarExpanded = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == widget.currentIndex) return;
    HapticFeedback.selectionClick();
    _animController.reset();
    _animController.forward();
    widget.onNavigate(index);
    // Fermer le drawer après navigation
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1200;

        if (isDesktop) {
          return _buildDesktopLayout();
        } else {
          return _buildMobileTabletLayout();
        }
      },
    );
  }

  /// ============================================
  /// DESKTOP LAYOUT - Sidebar fixe large
  /// ============================================
    Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar permanente - Desktop avec sécurité anti-bave pendant l'animation
          ClipRect(
            child: _DesktopSidebar(
              destinations: widget.destinations,
              currentIndex: widget.currentIndex,
              onNavigate: _onItemTapped,
              isExpanded: _sidebarExpanded,
              onToggleExpand: () {
                setState(() {
                  _sidebarExpanded = !_sidebarExpanded;
                });
              },
            ),
          ),
          // Contenu principal
          Expanded(
            child: FadeTransition(
              opacity: _scaleAnimation,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  /// ============================================
  /// MOBILE/TABLET LAYOUT - Drawer coulissant
  /// ============================================
  Widget _buildMobileTabletLayout() {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: th.AppColors.sidebarBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: const Text(
          'GIS Gestion',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: FadeTransition(
        opacity: _scaleAnimation,
        child: widget.child,
      ),
    );
  }

  /// ============================================
  /// DRAWER - Menu coulissant pour mobile/tablette
  /// ============================================
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: th.AppColors.sidebarBg,
      child: SafeArea(
        child: Column(
          children: [
            // Header du drawer avec logo
            Container(
              // Remplacement de .all(20) par des marges adaptées pour éviter le débordement horizontal
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    th.AppColors.primaryIndigo.withOpacity(0.3),
                    th.AppColors.sidebarBg,
                  ],
                ),
              ),
              child: Row(
                children: [
                  // Logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/logo_guiss_gestion1.png',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: th.AppColors.primaryGradient,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.store_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12), // Légèrement réduit de 14 à 12 pour gagner de l'espace
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, // Indique à la colonne de prendre le minimum de place verticale
                      children: [
                        const Text(
                          'GIS Gestion',
                          maxLines: 1, // Empêche de dupliquer les lignes à l'infini
                          overflow: TextOverflow.ellipsis, // Coupe proprement par des "..." si ça dépasse
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18, // Réduit de 20 à 18 pour la sécurité sur mobile
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Gestion de boutique',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis, // Sécurité anti-débordement
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Liste des destinations
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: widget.destinations.length,
                itemBuilder: (context, index) {
                  return _buildDrawerItem(index);
                },
              ),
            ),

            // Footer avec fermer
            _buildDrawerFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(int index) {
    final dest = widget.destinations[index];
    final isSelected = widget.currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _onItemTapped(index),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? dest.color.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: dest.color.withOpacity(0.5),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [dest.color, dest.color.withOpacity(0.8)])
                        : null,
                    color: isSelected ? null : th.AppColors.sidebarHover,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isSelected ? dest.selectedIcon : dest.icon,
                    color: isSelected ? Colors.white : th.AppColors.sidebarText,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    dest.label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : th.AppColors.sidebarText,
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dest.color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          // Bouton fermer
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: th.AppColors.sidebarHover,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.close,
                      color: Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Fermer',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================
/// NAV DESTINATION MODEL
/// ============================================
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

/// ============================================
/// DESKTOP SIDEBAR - Large avec logo + profil
/// ============================================
class _DesktopSidebar extends StatefulWidget {
  final List<NavDestination> destinations;
  final int currentIndex;
  final Function(int) onNavigate;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const _DesktopSidebar({
    required this.destinations,
    required this.currentIndex,
    required this.onNavigate,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  @override
  State<_DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends State<_DesktopSidebar> with SingleTickerProviderStateMixin {
  late AnimationController _avatarAnimController;
  late Animation<double> _avatarScaleAnimation;

  // Données utilisateur depuis Supabase
  String _userName = 'Utilisateur';
  String _userEmail = '';
  String? _userAvatarUrl;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _avatarAnimController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _avatarScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _avatarAnimController, curve: Curves.elasticOut),
    );
    _avatarAnimController.forward();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _avatarAnimController.dispose();
    super.dispose();
  }

  /// ============================================
  /// CHARGEMENT DES DONNÉES UTILISATEUR DEPUIS SUPABASE
  /// ============================================
  Future<void> _loadUserProfile() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        final email = currentUser.email ?? '';
        String nomUtilisateur = 'Utilisateur';
        String? avatarUrl; // Reste à null pour l'instant

        try {
          final profileResponse = await Supabase.instance.client
              .from('profiles')
              .select('full_name') // Retrait de avatar_url pour stopper le bug SQL
              .eq('id', currentUser.id)
              .maybeSingle();

          if (profileResponse != null) {
            nomUtilisateur = profileResponse['full_name'] ?? currentUser.userMetadata?['full_name'] ?? email.split('@').first;
          } else {
            nomUtilisateur = currentUser.userMetadata?['full_name'] ?? email.split('@').first;
          }
        } catch (e) {
          debugPrint('Erreur profil: $e');
          nomUtilisateur = currentUser.userMetadata?['full_name'] ?? email.split('@').first;
        }

        setState(() {
          _userName = nomUtilisateur;
          _userEmail = email;
          _userAvatarUrl = avatarUrl; // Vaut null, le widget affichera l'icône par défaut
          _isLoadingProfile = false;
        });
      } else {
        setState(() => _isLoadingProfile = false);
      }
    } catch (e) {
      debugPrint('Erreur chargement profil: $e');
      setState(() => _isLoadingProfile = false);
    }
  }

  /// ============================================
  /// RÉCUPÉRER LES INITIALES
  /// ============================================
  String _getInitiales() {
    if (_userName.isEmpty) return 'U';
    final parties = _userName.trim().split(' ');
    if (parties.length >= 2) {
      return '${parties[0][0]}${parties[1][0]}'.toUpperCase();
    }
    return _userName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: widget.isExpanded ? 280 : 80,
      decoration: BoxDecoration(
        color: th.AppColors.sidebarBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,

            
            offset: const Offset(5, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header avec logo
          _buildSidebarHeader(),
          const SizedBox(height: 8),
          // Navigation items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: widget.destinations.length,
              itemBuilder: (context, index) {
                return _buildNavItem(index);
              },
            ),
          ),
          // Footer avec profil + toggle
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: AnimatedCrossFade(
        crossFadeState: widget.isExpanded 
            ? CrossFadeState.showFirst 
            : CrossFadeState.showSecond,
        duration: const Duration(milliseconds: 200),
        
        // --- PREMIER ENFANT : Sidebar OUVERTE ---
        firstChild: Container(
          width: 280,
          height: 48, // Aligné sur la hauteur du logo
          child: ClipRect( // Sécurité pour masquer les débordements de texte
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Le Logo placé à gauche avec le padding d'origine (20)
                Positioned(
                  left: 20,
                  child: _buildHeaderLogo(),
                ),
                // Les Textes placés à une coordonnée fixe après le logo
                Positioned(
                  left: 78, // 20 (padding) + 44 (logo) + 14 (SizedBox)
                  right: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'GIS Gestion',
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.clip,
                      ),
                      Text(
                        'Gestion de boutique',
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.clip,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // --- SECOND ENFANT : Sidebar RÉDUITE ---
        secondChild: Container(
          width: 80,
          height: 48,
          alignment: Alignment.center,
          child: _buildHeaderLogo(),
        ),
      ),
    );
  }

  // Petit helper pour éviter de dupliquer le code de l'image du logo
  Widget _buildHeaderLogo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        'assets/images/logo_guiss_gestion1.png',
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: th.AppColors.primaryGradient,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.store_rounded,
              color: Colors.white,
              size: 24,
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final dest = widget.destinations[index];
    final isSelected = widget.currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => widget.onNavigate(index),
          borderRadius: BorderRadius.circular(12),
          hoverColor: th.AppColors.sidebarHover,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? th.AppColors.primaryIndigo.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: th.AppColors.primaryIndigo.withOpacity(0.5),
                      width: 1,
                    )
                  : null,
            ),
            // SÉCURITÉ ABSOLUE : ClipRect + ListTile éliminent définitivement le besoin de Row et ses plantages
            child: ClipRect(
              child: ListTile(
                mouseCursor: SystemMouseCursors.click,
                selected: isSelected,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: widget.isExpanded ? 16 : 8, // Réduction propre du padding pour centrer l'icône
                ),
                
                // 1. L'icône (S'affiche dans les deux états)
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(colors: [dest.color, dest.color.withOpacity(0.8)])
                        : null,
                    color: isSelected ? null : th.AppColors.sidebarHover,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSelected ? dest.selectedIcon : dest.icon,
                    color: isSelected ? Colors.white : th.AppColors.sidebarText,
                    size: 20,
                  ),
                ),

                // 2. Le Texte (Masqué par le ClipRect quand la barre se ferme)
                title: widget.isExpanded
                    ? Text(
                        dest.label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: TextStyle(
                          color: isSelected ? Colors.white : th.AppColors.sidebarText,
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      )
                    : const SizedBox.shrink(), // Rien du tout si fermé

                // 3. Le point indicateur à droite
                trailing: widget.isExpanded && isSelected
                    ? Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: dest.color,
                          shape: BoxShape.circle,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 6),
          
          // ============================================
          // PROFIL UTILISATEUR - FONDU ANIMÉ SÉCURISÉ
          // ============================================
          AnimatedCrossFade(
            crossFadeState: widget.isExpanded 
                ? CrossFadeState.showFirst 
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
            
            // --- ÉTAT 1 : Profil complet (Sidebar ouverte) ---
            firstChild: Container(
              width: 264, // Largeur nette disponible
              height: 60, // On fixe une hauteur stable pour le conteneur du profil
              decoration: BoxDecoration(
                color: th.AppColors.sidebarHover.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _showProfileMenu(context);
                  },
                  borderRadius: BorderRadius.circular(10),
                  // REMPLACEMENT DE LA ROW PAR UN STACK POURÉLIMINER COMPLÈTEMENT L'OVERFLOW
                  child: ClipRect(
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        // Avatar calé à gauche (avec un padding de 10)
                        Positioned(
                          left: 10,
                          child: ScaleTransition(
                            scale: _avatarScaleAnimation,
                            child: _buildAvatar(),
                          ),
                        ),
                        // Zone de texte calée de manière fixe après l'avatar
                        Positioned(
                          left: 54, // 10 (marge) + 34 (largeur avatar estimée) + 10 (espace)
                          right: 32, // Laisse de l'espace pour l'icône de droite
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.clip,
                                maxLines: 1,
                                softWrap: false,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _userEmail.isNotEmpty ? _userEmail : 'Chargement...',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.clip,
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ],
                          ),
                        ),
                        // L'icône des trois points calée à l'extrémité droite
                        Positioned(
                          right: 10,
                          child: Icon(
                            Icons.more_vert,
                            color: Colors.white.withOpacity(0.5),
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // --- ÉTAT 2 : Profil réduit (Sidebar fermée) ---
            secondChild: Container(
              width: 64,
              height: 60, // Même hauteur fixe pour un fondu parfaitement harmonieux
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: th.AppColors.sidebarHover.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _showProfileMenu(context);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Center(
                    child: ScaleTransition(
                      scale: _avatarScaleAnimation,
                      child: _buildAvatar(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 6),
          
          // ============================================
          // BOUTON TOGGLE REDUIRE/AGRANDIR SÉCURISÉ
          // ============================================
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onToggleExpand();
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 36, 
                width: widget.isExpanded ? 264 : 64,
                decoration: BoxDecoration(
                  color: th.AppColors.sidebarHover.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRect(
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Positioned(
                        left: widget.isExpanded ? 8 : 23, 
                        child: Icon(
                          widget.isExpanded
                              ? Icons.chevron_left_rounded
                              : Icons.chevron_right_rounded,
                          color: th.AppColors.sidebarText,
                          size: 18,
                        ),
                      ),
                      if (widget.isExpanded)
                        const Positioned(
                          left: 34, 
                          child: Text(
                            'Réduire',
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ============================================
  /// CONSTRUCTION DE L'AVATAR UTILISATEUR
  /// ============================================
  Widget _buildAvatar() {
    if (_isLoadingProfile) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: th.AppColors.primaryGradient,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    if (_userAvatarUrl != null && _userAvatarUrl!.isNotEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            _userAvatarUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildInitialesAvatar(),
          ),
        ),
      );
    }

    return _buildInitialesAvatar();
  }

  Widget _buildInitialesAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: th.AppColors.primaryGradient,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          _getInitiales(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: th.AppColors.primaryGradient,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: th.AppColors.primaryIndigo.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _getInitiales(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _userName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: th.AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _userEmail,
              style: TextStyle(
                fontSize: 14,
                color: th.AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            // Menu items
            _buildProfileMenuItem(
              icon: Icons.person_outline,
              title: 'Mon Profil',
              subtitle: 'Gérer mes informations',
              color: th.AppColors.primaryIndigo,
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigator.push vers la page profil
              },
            ),
            _buildProfileMenuItem(
              icon: Icons.store_outlined,
              title: 'Ma Boutique',
              subtitle: 'Paramètres de la boutique',
              color: th.AppColors.primaryGreen,
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigator.push vers les paramètres boutique
              },
            ),
            _buildProfileMenuItem(
              icon: Icons.help_outline,
              title: 'Aide & Support',
              subtitle: 'FAQ et assistance',
              color: th.AppColors.primaryOrange,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(height: 32),
            _buildProfileMenuItem(
              icon: Icons.logout,
              title: 'Déconnexion',
              subtitle: 'Se déconnecter de l\'application',
              color: th.AppColors.danger,
              onTap: () async {
                Navigator.pop(context);
                await _deconnecter();
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// ============================================
  /// DÉCONNEXION SUPABASE
  /// ============================================
  Future<void> _deconnecter() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        // Redirection vers login
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      debugPrint('Erreur déconnexion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: th.AppColors.danger,
          ),
        );
      }
    }
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: color,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: th.AppColors.textDark,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: th.AppColors.textMuted,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: th.AppColors.textMuted,
      ),
    );
  }
}