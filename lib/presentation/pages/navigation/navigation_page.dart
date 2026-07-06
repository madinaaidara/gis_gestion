import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../accueil/accueil_page.dart';
import '../ventes/ventes_page.dart';
import '../produits/produits_page.dart';
import '../credits/credits_page.dart';
import '../historiques/historique_page.dart';
import '../statistiques/statistiques_page.dart';
import '../profil/profil_page.dart';
import '../abonnement/abonnement_page.dart';
import '../../widgets/responsive_navigation.dart';
import '../../widgets/global_search_overlay.dart';
import '../../widgets/search_shortcuts.dart';
import '../../widgets/gis_assistant_host.dart';
import '../../../core/theme/app_colors.dart' as theme;
import '../../viewmodels/products_viewmodel.dart';
import '../../viewmodels/credits_viewmodel.dart';
import '../../viewmodels/assistant_viewmodel.dart';
import '../../../data/repositories/shops_repository.dart';
import '../../../data/repositories/abonnement_repository.dart';
import '../../../core/services/app_refresh_notifier.dart';

class NavigationPage extends StatefulWidget {
  final int indexInitial;

  const NavigationPage({super.key, required this.indexInitial});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  late int _indexActuel;
  late final List<Widget> _pages;

  static const Color _navAccent = theme.AppColors.brandAccent;

  final List<NavDestination> _navDestinations = const [
    NavDestination(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Accueil', color: _navAccent),
    NavDestination(icon: Icons.point_of_sale_outlined, selectedIcon: Icons.point_of_sale_rounded, label: 'Caisse / Vente', color: _navAccent),
    NavDestination(icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2_rounded, label: 'Produits', color: _navAccent),
    NavDestination(icon: Icons.credit_card_outlined, selectedIcon: Icons.credit_card_rounded, label: 'Crédits', color: _navAccent),
    NavDestination(icon: Icons.history_outlined, selectedIcon: Icons.history_rounded, label: 'Historique', color: _navAccent),
    NavDestination(icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart_rounded, label: 'Statistiques', color: _navAccent),
  ];

  static const int profileNavIndex = 6;

  @override
  void initState() {
    super.initState();
    _indexActuel = widget.indexInitial;
    _pages = [
      AccueilPage(onNavigate: _onNavigate),
      const VentePage(),
      const ProduitsPage(),
      const CreditPage(),
      const HistoriquePage(),
      const StatsScreen(),
      const ProfilPage(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapSession());
  }

  Future<void> _bootstrapSession() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || !mounted) return;

    final shopRepo = context.read<ShopsRepository>();
    if (shopRepo.currentShop == null) {
      await shopRepo.checkAndLoadShop(userId);
    }
    final shopId = shopRepo.currentShop?.id;
    if (shopId == null || !mounted) return;

    final aboRepo = context.read<AbonnementRepository>();
    await aboRepo.ensureTrialForShop(shopId);
    if (!mounted) return;

    if (!aboRepo.hasValidSubscription) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const AbonnementPage(blocking: true),
        ),
      );
    }

    if (!mounted) return;
    final shop = shopRepo.currentShop;
    final String? shopIdString = shop?.id;
    if (shopIdString != null) {
      await context.read<AssistantViewModel>().initialize(
            shopId: shopIdString,
            shopName: shop!.nomBoutique,
            devise: shop.devise,
          );
    }
  }

  void _onNavigate(int index) {
    if (index == _indexActuel) return;
    HapticFeedback.selectionClick();
    setState(() => _indexActuel = index);
    _refreshTabData(index);
  }

  void _refreshTabData(int index) {
    if (!mounted) return;
    final scope = switch (index) {
      0 => AppRefreshScope.dashboard,
      1 => AppRefreshScope.sales,
      2 => AppRefreshScope.products,
      3 => AppRefreshScope.credits,
      4 => AppRefreshScope.history,
      5 => AppRefreshScope.stats,
      _ => AppRefreshScope.all,
    };
    context.read<AppRefreshNotifier>().refresh(scope);
  }

  void _onSearchNavigate(int index, {String? productQuery, String? clientQuery}) {
    final shopId = context.read<ShopsRepository>().currentShop?.id;

    if (productQuery != null && productQuery.isNotEmpty && shopId != null) {
      final vm = context.read<ProductsViewModel>();
      vm.initializeCatalog(shopId).then((_) {
        if (mounted) vm.updateSearchQuery(productQuery);
      });
    }

    if (clientQuery != null && clientQuery.isNotEmpty && shopId != null) {
      final cvm = context.read<CreditsViewModel>();
      cvm.loadCredits(shopId).then((_) {
        if (mounted) cvm.updateSearchQuery(clientQuery);
      });
    }

    _onNavigate(index);
  }

  void _openGlobalSearch() {
    GlobalSearchOverlay.show(context, onNavigate: _onSearchNavigate);
  }

  @override
  Widget build(BuildContext context) {
    return SearchShortcuts(
      onOpenSearch: _openGlobalSearch,
      child: GisAssistantHost(
        child: ResponsiveNavigation(
          currentIndex: _indexActuel,
          onNavigate: _onNavigate,
          onSearchNavigate: _onSearchNavigate,
          onOpenSearch: _openGlobalSearch,
          destinations: _navDestinations,
          profileNavIndex: profileNavIndex,
          child: IndexedStack(
            index: _indexActuel,
            children: _pages,
          ),
        ),
      ),
    );
  }
}
