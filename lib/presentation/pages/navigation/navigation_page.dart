import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../accueil/accueil_page.dart';
import '../ventes/ventes_page.dart'; // Remonté en priorité métier (POS de caisse)
import '../produits/produits_page.dart';
import '../credits/credits_page.dart';
import '../historiques/historique_page.dart';
import '../statistiques/statistiques_page.dart';
import '../profil/profil_page.dart';
import '../../widgets/responsive_navigation.dart';
import '../../../core/theme/app_colors.dart' as theme;

/// ============================================
/// NAVIGATION PAGE - GIS Gestion
/// ============================================
/// Arborescence et palette graphique aux standards SaaS premium.
/// Regroupement ordonné par flux d'activité métier (Opérations -> Logistique -> Analyse -> Paramètres).
/// ============================================

class NavigationPage extends StatefulWidget {
  final int indexInitial;

  const NavigationPage({super.key, required this.indexInitial});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage>
    with SingleTickerProviderStateMixin {
  late int _indexActuel;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Palette de couleurs unifiée et harmonisée (Style SaaS Premium discret)
  static const Color colorPrimary = theme.AppColors.primaryIndigo; // Indigo de confiance (Marque)
  static const Color colorSecondary = theme.AppColors.textSecondary; // Gris sobre pour l'archivage
  static const Color colorSuccess = theme.AppColors.primaryGreen; // Vert pour la gestion des stocks sains
  static const Color colorWarning = theme.AppColors.primaryOrange; // Orange d'alerte pour les dettes/crédits

  // 1. FLUX MÉTIER RÉORGANISÉ : Les pages se reconstruisent dynamiquement à chaque clic
  final List<Widget> _pages = [
    const AccueilPage(),       // 0. Tableau de bord général
    const VentePage(),         // 1. Point de Vente (La fonction la plus utilisée au quotidien)
    const ProduitsPage(),      // 2. Catalogue de stock et Base produit
    const CreditPage(),        // 3. Suivi des arriérés de paiement clients
    const HistoriquePage(),    // 4. Journal des flux et transactions passées
    const StatistiquesPage(),  // 5. Analyses comptables et performances de la boutique
    const ProfilPage(),        // 6. Gestion du compte utilisateur et réglages
  ];

  // 2. DESIGN DES ICÔNES DE NAVIGATION HARMONISÉ (Fini l'effet arc-en-ciel)
  final List<NavDestination> _navDestinations = const [
    NavDestination(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      label: 'Accueil',
      color: colorPrimary,
    ),
    NavDestination(
      icon: Icons.point_of_sale_outlined,
      selectedIcon: Icons.point_of_sale_rounded,
      label: 'Caisse / Vente',
      color: colorPrimary, // Même couleur que l'accueil pour asseoir la charte principale
    ),
    NavDestination(
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2_rounded,
      label: 'Produits',
      color: colorSuccess, // Vert discret symbolisant la santé des inventaires
    ),
    NavDestination(
      icon: Icons.credit_card_outlined,
      selectedIcon: Icons.credit_card_rounded,
      label: 'Crédits',
      color: colorWarning, // Orange d'avertissement logique pour le suivi des dettes
    ),
    NavDestination(
      icon: Icons.history_outlined,
      selectedIcon: Icons.history_rounded,
      label: 'Historique',
      color: colorSecondary, // Gris neutre professionnel pour l'archivage des données
    ),
    NavDestination(
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
      label: 'Statistiques',
      color: colorPrimary,
    ),
    NavDestination(
      icon: Icons.person_outlined,
      selectedIcon: Icons.person_rounded,
      label: 'Profil & Réglages',
      color: colorSecondary, // Option secondaire, reste discrète
    ),
  ];

  @override
  void initState() {
    super.initState();
    _indexActuel = widget.indexInitial;

    // Transition fluide cinétique (Inspirée des standards iOS/Material 3)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200), // Vitesse d'exécution rapide pour le confort du vendeur
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.linear,
    );

    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onNavigate(int index) {
    if (index == _indexActuel) return;

    // Amélioration de la réactivité au clic de souris ou tactile
    HapticFeedback.selectionClick();
    _animController.reset();
    _animController.forward();

    setState(() {
      _indexActuel = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveNavigation(
      currentIndex: _indexActuel,
      onNavigate: _onNavigate,
      destinations: _navDestinations,
      child: ClipRect( 
        // Effet de transition haut de gamme combinant un fondu et un micro-zoom cinétique
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _pages[_indexActuel],
          ),
        ),
      ),
    );
  }
}
