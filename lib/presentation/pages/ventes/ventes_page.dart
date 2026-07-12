import 'package:flutter/material.dart';
import '../../../core/theme/gis_palette.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/produit_model.dart';
import '../../../core/utils/packaging_utils.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../viewmodels/products_viewmodel.dart';
import '../../viewmodels/ventes_viewmodel.dart';
import '../../../data/repositories/shops_repository.dart';
import '../../../core/services/app_refresh_listener.dart';
import '../../../core/services/app_refresh_notifier.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/gis_ui_kit.dart';

class VentePage extends StatefulWidget {
  const VentePage({super.key});

  @override
  State<VentePage> createState() => _VentePageState();
}

class _VentePageState extends State<VentePage> with AppRefreshListener {
  GisPalette get _p => GisPalette.of(context);

  @override
  AppRefreshScope get refreshScope => AppRefreshScope.sales;

  @override
  void onAppRefresh() => _loadData();

  // ============================================================
  // STATE
  // ============================================================

  final searchController = TextEditingController();
  final clientNameController = TextEditingController();
  final clientPhoneController = TextEditingController();
  final amountPaidController = TextEditingController();

  String? shopId;
  String? devise;
  String? shopName;

  final ScrollController _productsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    searchController.dispose();
    clientNameController.dispose();
    clientPhoneController.dispose();
    amountPaidController.dispose();
    _productsScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      if (!mounted) return;
      final shopRepo = Provider.of<ShopsRepository>(context, listen: false);
      await shopRepo.checkAndLoadShop(userId);
      if (!mounted) return;
      if (shopRepo.currentShop == null) return;

      shopId = shopRepo.currentShop!.id;
      devise = shopRepo.currentShop?.devise ?? 'FCFA';
      shopName = shopRepo.currentShop?.nomBoutique;

      final productsVM = Provider.of<ProductsViewModel>(context, listen: false);
      await productsVM.initializeCatalog(shopId!);

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Erreur chargement: $e');
    }
  }

  void _quickAddToCart(ProduitModel produit) {
    final options = PackagingUtils.saleOptions(produit);
    if (options.isEmpty) return;
    final opt = options.first;
    final price = PackagingUtils.priceForUnit(produit, opt.unite);
    _addToCart(produit, 1, price, opt.unite, opt.factorToBase);
  }

  ProduitModel? _findProductForCartLine(VentesViewModel vm, Map<String, dynamic> item) {
    final productId = item['produit_id']?.toString();
    if (productId == null) return null;

    final productsVm = Provider.of<ProductsViewModel>(context, listen: false);
    for (final p in productsVm.products) {
      if (p.id == productId) return p;
    }

    final stock = (item['stock'] ?? 0.0).toDouble();
    return ProduitModel(
      id: productId,
      nom: item['nom']?.toString() ?? 'Produit',
      stock: stock,
      prixVenteUnitaire: (item['prix_initial'] ?? item['prix_unitaire'] ?? 0).toDouble(),
      prixAchatTotal: 0,
      quantiteParUnite: 1,
      uniteVente: item['unite_vente']?.toString(),
      typeVente: item['type_vente']?.toString(),
    );
  }

  void _openCartLineEditor(VentesViewModel vm, int index, NumberFormat format) {
    if (index < 0 || index >= vm.panier.length) return;
    final product = _findProductForCartLine(vm, vm.panier[index]);
    if (product == null) return;
    _openProductModal(product, cartLineIndex: index);
  }

  void _addToCart(ProduitModel produit, int qty, double price, String selectedUnite, double facteurConversion) {
    final vm = Provider.of<VentesViewModel>(context, listen: false);
    final ok = vm.ajouterAuPanierAvecUnite(produit, qty, price, selectedUnite, facteurConversion);
    if (!ok) {
      _showSnackBar('Stock insuffisant', false);
      return;
    }
    _showSnackBar('✓ ${produit.nom} ajouté', true);
  }

  void _validateSale() async {
    final vm = Provider.of<VentesViewModel>(context, listen: false);

    if (vm.panier.isEmpty) {
      _showSnackBar("Panier vide", false);
      return;
    }
    if (vm.isCreditMode) {
      if (clientNameController.text.trim().isEmpty) {
        _showSnackBar("Nom client requis", false);
        return;
      }
      if (vm.amountPaid > vm.totalTTC) {
        _showSnackBar("Acompte invalide", false);
        return;
      }
    }
    await _executeSale(vm);
  }

  Future<void> _executeSale(VentesViewModel vm) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showSnackBar("Session expirée", false);
      return;
    }

    final receipt = await vm.executerEncaissement(
      shopId!,
      user.id,
      clientNameController.text.trim(),
      clientPhoneController.text.trim(),
    );

    if (receipt != null) {
      _showSnackBar(vm.isCreditMode ? "✓ Crédit enregistré" : "✓ Vente enregistrée", true);
      clientNameController.clear();
      clientPhoneController.clear();
      amountPaidController.clear();
      if (vm.isCreditMode) vm.setAmountPaid(0);
      if (mounted) {
        await Provider.of<ProductsViewModel>(context, listen: false).refreshProducts();
        refreshAppData(context);
      }
    } else {
      _showSnackBar("Erreur d'enregistrement", false);
    }
  }

  // ============================================================
  // BUILD ROOT
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.currency(locale: 'fr_FR', symbol: devise ?? 'FCFA', decimalDigits: 0);
    final isCatalogLoading = context.watch<ProductsViewModel>().isLoading;
    final isMobile = !ResponsiveUtils.useDesktopPosLayout(context);

    if (isCatalogLoading) {
      return Scaffold(
        backgroundColor: _p.bg,
        body:  Center(child: CircularProgressIndicator(color: _p.accent)),
      );
    }

    return Scaffold(
      backgroundColor: _p.bg,
      body: SafeArea(
        child: isMobile ? _buildMobileLayout(format) : _buildDesktopLayout(format),
      ),
    );
  }

  // ============================================================
  // LAYOUT MOBILE
  // ============================================================

  Widget _buildMobileLayout(NumberFormat format) {
    return Column(
      children: [
        _buildPosHero(format),
        _buildSearchBar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: _buildCategoryRow(),
        ),
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSegmentedTabBar(),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildProductsCatalog(format),
                      _buildCartShell(format),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LAYOUT DESKTOP
  // ============================================================

  Widget _buildDesktopLayout(NumberFormat format) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPosHero(format, isWide: true),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildCatalogShell(format),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildCartShell(format),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogShell(NumberFormat format) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: _p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _p.border.withValues(alpha: isDark ? 0.55 : 0.35)),
        boxShadow: isDark
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 6))]
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Row(
              children: [
                Icon(Icons.grid_view_rounded, size: 14, color: _p.success),
                const SizedBox(width: 6),
                Text(
                  'Catalogue',
                  style: GoogleFonts.plusJakartaSans(
                    color: _p.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Consumer<ProductsViewModel>(
                  builder: (_, vm, __) => Text(
                    '${vm.products.length} prod.',
                    style: TextStyle(color: _p.textMute, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
            child: _buildSearchBar(isPadding: false),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4, left: 14, right: 14),
            child: _buildCategoryRow(pad: 0),
          ),
          Expanded(child: _buildProductsCatalog(format, inset: false)),
        ],
      ),
    );
  }

  Widget _buildCartShell(NumberFormat format) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: _p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _p.border.withValues(alpha: isDark ? 0.55 : 0.35)),
        boxShadow: isDark
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 6))]
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildCart(format),
    );
  }

  // ============================================================
  // HERO POS
  // ============================================================

  Color _productAccent(String seed) {
    final palette = [_p.success, _p.info, _p.accent, _p.warning, _p.gold];
    return palette[seed.hashCode.abs() % palette.length];
  }

  Widget _buildPosHero(NumberFormat format, {bool isWide = false}) {
    final timeLabel = DateFormat('HH:mm', 'fr_FR').format(DateTime.now());

    return Padding(
      padding: EdgeInsets.fromLTRB(isWide ? 0 : 16, 0, isWide ? 0 : 16, 2),
      child: Consumer2<ProductsViewModel, VentesViewModel>(
        builder: (context, productsVm, ventesVm, _) {
          final qtyPanier = ventesVm.panier.fold<int>(
            0,
            (s, i) => s + ((i['quantite'] ?? 1) as int),
          );
          final stats = <String>[
            '${productsVm.products.length} prod.',
            '$qtyPanier panier',
            if (ventesVm.panier.isNotEmpty)
              '${ventesVm.margePercentage.toStringAsFixed(0)}% marge',
          ].join(' · ');

          return Row(
            children: [
              Icon(Icons.point_of_sale_rounded, size: 15, color: _p.success),
              const SizedBox(width: 6),
              Text(
                ' · $timeLabel',
                style: TextStyle(color: _p.textMute, fontSize: 11, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stats,
                  style: TextStyle(color: _p.textMute, fontSize: 11, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
              if (ventesVm.panier.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  format.format(ventesVm.totalTTC),
                  style: GoogleFonts.plusJakartaSans(
                    color: _p.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(Icons.refresh_rounded, size: 17, color: _p.textMute),
                  tooltip: 'Actualiser',
                  onPressed: _loadData,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar({bool isPadding = true}) {
    return GisSearchField(
      controller: searchController,
      hint: 'Rechercher un produit…',
      padding: isPadding ? const EdgeInsets.fromLTRB(16, 8, 16, 4) : EdgeInsets.zero,
      onChanged: (v) => context.read<ProductsViewModel>().updateSearchQuery(v.trim()),
      onClear: () {
        searchController.clear();
        context.read<ProductsViewModel>().updateSearchQuery('');
        setState(() {});
      },
    );
  }

  // ============================================================
  // CATEGORY CHIPS (purement visuel — placeholder cohérent)
  // ============================================================

  Widget _buildCategoryRow({double? pad}) {
    return Consumer<ProductsViewModel>(
      builder: (context, vm, _) {
        final tabs = <(String?, String)>[(null, 'Tout'), ...vm.categories.map((c) => (c.id, c.nom))];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: pad ?? 16),
          child: Row(
            children: tabs.map((tab) {
              final selected = vm.selectedCategoryId == tab.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 20),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    vm.selectCategory(tab.$1);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tab.$2,
                        style: TextStyle(
                          color: selected ? _p.success : _p.textMute,
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 3,
                        width: selected ? 32 : 0,
                        decoration: BoxDecoration(
                          color: _p.success,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ============================================================
  // SEGMENTED TAB BAR (mobile)
  // ============================================================

  Widget _buildSegmentedTabBar() {
    return Consumer<VentesViewModel>(
      builder: (context, vm, _) {
        final count = vm.panier.length;
        return Container(
          height: 46,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _p.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _p.border),
          ),
          child: TabBar(
            indicator: BoxDecoration(
              color: _p.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _p.success.withValues(alpha: 0.35)),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: _p.success,
            unselectedLabelColor: _p.textMute,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            tabs: [
              const Tab(
                height: 38,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.grid_view_rounded, size: 15),
                    SizedBox(width: 6),
                    Text('Produits'),
                  ],
                ),
              ),
              Tab(
                height: 38,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 15),
                    const SizedBox(width: 6),
                    const Text('Panier'),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _p.success,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // PRODUCTS GRID (POS)
  // ============================================================

  Widget _buildProductsCatalog(NumberFormat format, {bool inset = true}) {
    return Consumer2<ProductsViewModel, VentesViewModel>(
      builder: (context, productsVm, ventesVm, _) {
        if (productsVm.products.isEmpty) {
          return _buildEmptyState('Aucun produit', 'Ajoutez des produits à votre catalogue', Icons.inventory_2_outlined);
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final crossAxisCount = w >= 1100 ? 5 : (w >= 850 ? 4 : (w >= 560 ? 3 : 2));
            const spacing = 8.0;

            return GridView.builder(
              controller: _productsScrollController,
              padding: EdgeInsets.fromLTRB(inset ? 16 : 10, 4, inset ? 16 : 10, 12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: 1.55,
              ),
              itemCount: productsVm.products.length,
              itemBuilder: (_, index) => _buildProductTile(productsVm.products[index], format, ventesVm),
            );
          },
        );
      },
    );
  }

  Widget _buildProductTile(ProduitModel p, NumberFormat format, VentesViewModel ventesVm) {
    final stockDispo = ventesVm.stockDisponible(p);
    final pAffiche = p.copyWith(stock: stockDispo < 0 ? 0 : stockDispo);
    final isOutOfStock = stockDispo <= 0;
    final unite = p.uniteVente ?? 'pièce';
    final level = PackagingUtils.stockLevel(pAffiche);
    final stockColor = level == StockLevel.rupture
        ? _p.danger
        : (level == StockLevel.faible ? _p.warning : _p.success);
    final stockIcon = level == StockLevel.rupture
        ? '✗'
        : (level == StockLevel.faible ? '!' : '✓');
    var texteStock = PackagingUtils.formatStock(pAffiche);
    if (stockDispo < p.stock) {
      texteStock = '$texteStock dispo';
    }

    final accent = _productAccent(p.nom);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inCart = ventesVm.panier.any((i) => i['produit_id'] == p.id);
    final prixLabel = '${format.format(p.prixVenteUnitaire)} / $unite';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isOutOfStock ? null : () => _openProductModal(p),
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: isOutOfStock ? _p.surfaceHi : _p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: inCart
                  ? accent.withValues(alpha: 0.5)
                  : (isOutOfStock ? _p.border.withValues(alpha: 0.45) : _p.border.withValues(alpha: isDark ? 0.5 : 0.35)),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: isOutOfStock ? _p.border : accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 7, 6, 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                p.nom,
                                style: TextStyle(
                                  color: isOutOfStock ? _p.textMute : _p.text,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isOutOfStock)
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    _quickAddToCart(p);
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Icon(Icons.add_rounded, color: accent, size: 16),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          prixLabel,
                          style: GoogleFonts.plusJakartaSans(
                            color: isOutOfStock ? _p.textDim : accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: stockColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '$stockIcon $texteStock',
                            style: TextStyle(fontSize: 9, color: stockColor, fontWeight: FontWeight.w600, height: 1.1),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: _p.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _p.border, width: 0.5),
              ),
              child: Icon(icon, color: _p.textDim, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style:  TextStyle(
                color: _p.text,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style:  TextStyle(color: _p.textMute, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MODAL PRODUIT
  // ============================================================

  void _openProductModal(ProduitModel product, {int? cartLineIndex}) {
    final ventesVm = Provider.of<VentesViewModel>(context, listen: false);
    final isEdit = cartLineIndex != null;
    Map<String, dynamic>? cartItem;
    if (isEdit) {
      cartItem = ventesVm.panier[cartLineIndex];
    }

    final qtyController = TextEditingController(
      text: isEdit ? '${cartItem!['quantite'] ?? 1}' : '1',
    );
    final saleOptions = PackagingUtils.saleOptions(product);
    if (saleOptions.isEmpty) return;

    final cartUnite = cartItem?['unite_vente']?.toString();
    final initialOption = isEdit && cartUnite != null
        ? saleOptions.firstWhere(
            (o) => o.unite == cartUnite,
            orElse: () => saleOptions.first,
          )
        : saleOptions.first;

    final initialPrice = isEdit
        ? (cartItem!['prix_unitaire'] ?? 0).toDouble()
        : PackagingUtils.priceForUnit(product, initialOption.unite);

    final priceController = TextEditingController(
      text: PackagingUtils.formatSalePrice(initialPrice),
    );

    final lineQty = isEdit ? ((cartItem!['quantite'] ?? 1) as num).toDouble() : 0.0;
    final lineFactor = isEdit ? (cartItem!['facteur_conversion'] ?? 1.0).toDouble() : 0.0;
    final double maxStock = isEdit
        ? ventesVm.stockDisponible(product) + lineQty * lineFactor
        : ventesVm.stockDisponible(product);

    String baseUnite = product.uniteVente ?? 'pièce';
    String selectedUnite = initialOption.unite;
    double facteurConversion = initialOption.factorToBase;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (stateContext, setModalState) {
          int currentQty = int.tryParse(qtyController.text) ?? 1;
          double currentPrice = double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0;

          void updateUnite(SaleUnitOption option) {
            setModalState(() {
              selectedUnite = option.unite;
              facteurConversion = option.factorToBase;
              currentPrice = PackagingUtils.priceForUnit(product, option.unite);
              priceController.text = PackagingUtils.formatSalePrice(currentPrice);
            });
          }

          double totalLigne = currentQty * currentPrice;
          double stockNecessaire = currentQty * facteurConversion;
          bool stockDepasse = stockNecessaire > maxStock;
          final stockProgress = (maxStock > 0 ? stockNecessaire / maxStock : 0.0).clamp(0.0, 1.0);

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(stateContext).size.height * 0.92,
            ),
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 20,
              bottom: 24 + MediaQuery.of(stateContext).viewInsets.bottom,
            ),
            decoration:  BoxDecoration(
              color: _p.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: Border(top: BorderSide(color: _p.borderStrong, width: 0.5)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: _p.borderStrong,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _p.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _p.accent.withOpacity(0.2)),
                      ),
                      child:  Icon(Icons.inventory_2_rounded, color: _p.accentSoft, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isEdit ? 'Modifier la ligne' : 'Nouvelle vente',
                            style: TextStyle(
                              color: _p.textMute,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            product.nom,
                            style: TextStyle(
                              color: _p.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 6, height: 6,
                                decoration: BoxDecoration(
                                  color: maxStock > 0 ? _p.success : _p.danger,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                PackagingUtils.formatStock(product),
                                style:  TextStyle(
                                  color: _p.textMute,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                if (saleOptions.length > 1) ...[
                  _buildFieldLabel('Vendre par'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: saleOptions.map((opt) {
                      final active = selectedUnite == opt.unite;
                      final factorLabel = PackagingUtils.saleOptionChipLabel(opt, baseUnite);
                      return InkWell(
                        onTap: () => updateUnite(opt),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? _p.accent.withOpacity(0.15) : _p.surfaceHi,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active ? _p.accent.withOpacity(0.45) : _p.border,
                            ),
                          ),
                          child: Text(
                            factorLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                              color: active ? _p.accentSoft : _p.textMute,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel("Prix unitaire"),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: _p.surfaceHi,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _p.border, width: 0.5),
                      ),
                      child: TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        style:  TextStyle(
                          color: _p.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          suffix: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              '${devise ?? 'FCFA'} / $selectedUnite',
                              style:  TextStyle(
                                color: _p.textMute,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Quantity stepper
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel("Quantité"),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildStepperButton(
                                Icons.remove_rounded,
                                currentQty > 1,
                                () {
                                  qtyController.text = (currentQty - 1).toString();
                                  setModalState(() {});
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _p.surfaceHi,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _p.border, width: 0.5),
                                  ),
                                  child: TextField(
                                    controller: qtyController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style:  TextStyle(
                                      color: _p.text,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                    onChanged: (_) => setModalState(() {}),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStepperButton(
                                Icons.add_rounded,
                                (currentQty + 1) * facteurConversion <= maxStock,
                                () {
                                  if ((currentQty + 1) * facteurConversion <= maxStock) {
                                    qtyController.text = (currentQty + 1).toString();
                                    setModalState(() {});
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel("Sous-total"),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: _p.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _p.accent.withOpacity(0.3), width: 0.5),
                            ),
                            child: Center(
                              child: Text(
                                NumberFormat.currency(locale: 'fr_FR', symbol: devise ?? 'FCFA', decimalDigits: 0).format(totalLigne),
                                style:  TextStyle(
                                  color: _p.accentSoft,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Stock indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _p.surfaceHi,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _p.border, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                 Text(
                                  "STOCK",
                                  style: TextStyle(
                                    color: _p.textDim,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "${PackagingUtils.formatQuantityBase(stockNecessaire)} / ${PackagingUtils.formatQuantityBase(maxStock)} $baseUnite",
                                  style: TextStyle(
                                    color: stockDepasse ? _p.danger : _p.textMute,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            if (product.hasPackagingIntermediaire || product.quantiteParUnite > 1) ...[
                              const SizedBox(height: 4),
                              Text(
                                "Disponible : ${PackagingUtils.formatStock(product)}",
                                style:  TextStyle(color: _p.textDim, fontSize: 10),
                              ),
                            ],
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: stockProgress,
                                backgroundColor: _p.border,
                                color: stockDepasse ? _p.danger : (stockProgress > 0.7 ? _p.gold : _p.success),
                                minHeight: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (stockDepasse) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _p.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _p.danger.withOpacity(0.3), width: 0.5),
                    ),
                    child:  Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 16, color: _p.danger),
                        SizedBox(width: 8),
                        Text(
                          "Stock insuffisant pour cette quantité",
                          style: TextStyle(
                            color: _p.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    if (isEdit)
                      OutlinedButton(
                        onPressed: () {
                          ventesVm.modifierQuantite(cartLineIndex, 0);
                          Navigator.pop(modalContext);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          side: BorderSide(color: _p.danger.withValues(alpha: 0.4)),
                          foregroundColor: _p.danger,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, size: 18),
                      ),
                    if (isEdit) const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(modalContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: _p.border, width: 0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          foregroundColor: _p.textMute,
                        ),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: stockDepasse || currentPrice <= 0
                            ? null
                            : () {
                                Navigator.pop(modalContext);
                                if (isEdit) {
                                  final ok = ventesVm.mettreAJourLignePanier(
                                    cartLineIndex,
                                    currentQty,
                                    currentPrice,
                                    selectedUnite,
                                    facteurConversion,
                                  );
                                  if (!ok) _showSnackBar('Stock insuffisant', false);
                                } else {
                                  _addToCart(product, currentQty, currentPrice, selectedUnite, facteurConversion);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: _p.success,
                          disabledBackgroundColor: _p.surfaceHi,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isEdit ? Icons.check_rounded : Icons.add_shopping_cart_rounded,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isEdit ? 'Enregistrer' : 'Ajouter au panier',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          );
        },
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label.toUpperCase(),
      style:  TextStyle(
        color: _p.textDim,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildStepperButton(IconData icon, bool enabled, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40, height: 44,
          decoration: BoxDecoration(
            color: enabled ? _p.accent.withOpacity(0.1) : _p.surfaceHi,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled ? _p.accent.withOpacity(0.3) : _p.border,
              width: 0.5,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? _p.accentSoft : _p.textDim,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CART
  // ============================================================

  Widget _buildCart(NumberFormat format) {
    return Consumer<VentesViewModel>(
      builder: (context, vm, _) {
        return Column(
          children: [
            _buildCartHeader(vm),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (vm.panier.isEmpty)
                    SizedBox(
                      height: 48,
                      child: _buildEmptyCart(),
                    )
                  else
                    ...vm.panier.asMap().entries.map(
                      (e) => Padding(
                        padding: EdgeInsets.fromLTRB(16, e.key == 0 ? 8 : 0, 16, 8),
                        child: _buildCartLine(vm, e.key, format),
                      ),
                    ),
                  if (vm.isCreditMode && vm.panier.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _buildCreditFields(vm, format),
                    ),
                  ],
                ],
              ),
            ),
            _buildCartFooter(vm, format),
          ],
        );
      },
    );
  }

  Widget _buildCreditFields(VentesViewModel vm, NumberFormat format) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPremiumField(
          clientNameController,
          'Nom du client',
          Icons.person_outline_rounded,
          isRequired: true,
        ),
        const SizedBox(height: 8),
        _buildPremiumField(
          amountPaidController,
          'Acompte',
          Icons.account_balance_wallet_outlined,
          suffix: devise,
          isNumber: true,
          onChanged: (v) => vm.setAmountPaid(double.tryParse(v) ?? 0),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _p.gold.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _p.gold.withValues(alpha: 0.25), width: 0.5),
          ),
          child: Row(
            children: [
              Icon(Icons.hourglass_bottom_rounded, color: _p.gold, size: 14),
              const SizedBox(width: 8),
              Text('Reste à payer', style: TextStyle(color: _p.textMute, fontSize: 11, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                format.format(vm.montantRestant),
                style: TextStyle(color: _p.gold, fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCartLine(VentesViewModel vm, int index, NumberFormat format) {
    final item = vm.panier[index];
    final prixActuel = (item['prix_unitaire'] ?? 0).toDouble();
    final qty = (item['quantite'] ?? 1) as int;
    final totalLigne = prixActuel * qty;
    final uniteVente = item['unite_vente'] ?? 'pièce';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openCartLineEditor(vm, index, format),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: _p.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _p.border.withValues(alpha: 0.5), width: 0.5),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: _p.success,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _p.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Center(
                            child: Text(
                              '$qty',
                              style: TextStyle(color: _p.success, fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item['nom'] ?? '',
                                style: TextStyle(color: _p.text, fontWeight: FontWeight.w600, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${format.format(prixActuel)} / $uniteVente · ${format.format(totalLigne)}',
                                style: TextStyle(color: _p.textMute, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.edit_note_rounded, size: 18, color: _p.textMute),
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

  Widget _buildEmptyCart() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 16, color: _p.textDim.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Panier vide',
              style: TextStyle(color: _p.textMute, fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartHeader(VentesViewModel vm) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _p.border.withValues(alpha: 0.5), width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long_rounded, color: _p.success, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              vm.panier.isEmpty
                  ? 'Ticket'
                  : 'Ticket · ${vm.panier.length} ligne${vm.panier.length > 1 ? 's' : ''}',
              style: GoogleFonts.plusJakartaSans(
                color: _p.text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (vm.panier.isNotEmpty)
            InkWell(
              onTap: () => vm.viderPanier(),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.delete_outline_rounded, color: _p.danger, size: 16),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // CART FOOTER
  // ============================================================

  Widget _buildCartFooter(VentesViewModel vm, NumberFormat format) {
    final modeCredit = vm.isCreditMode;
    final isEmpty = vm.panier.isEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _p.border.withValues(alpha: 0.5), width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TOTAL',
                      style: TextStyle(
                        color: _p.success.withValues(alpha: 0.85),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    if (!isEmpty)
                      Text(
                        'Marge ${format.format(vm.benefice)}',
                        style: TextStyle(
                          color: vm.isPerte ? _p.danger : _p.gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                format.format(vm.totalTTC),
                style: GoogleFonts.plusJakartaSans(
                  color: _p.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 40,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: _p.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _p.border, width: 0.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSegmentedItem(
                    'Espèces',
                    Icons.payments_rounded,
                    !modeCredit,
                    _p.success,
                    isEmpty ? () {} : () => vm.setCreditMode(false),
                  ),
                ),
                Expanded(
                  child: _buildSegmentedItem(
                    'Crédit',
                    Icons.schedule_rounded,
                    modeCredit,
                    _p.gold,
                    isEmpty ? () {} : () => vm.setCreditMode(true),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: isEmpty ? null : _validateSale,
              style: ElevatedButton.styleFrom(
                backgroundColor: modeCredit ? _p.gold : _p.success,
                disabledBackgroundColor: _p.surfaceHi,
                disabledForegroundColor: _p.textDim,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    modeCredit ? Icons.receipt_long_rounded : Icons.point_of_sale_rounded,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    modeCredit ? 'VALIDER CRÉDIT' : 'ENCAISSER',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedItem(String label, IconData icon, bool active, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: active
                ? Border.all(color: color.withOpacity(0.4), width: 0.5)
                : Border.all(color: Colors.transparent, width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: active ? color : _p.textMute),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? color : _p.textMute,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isNumber = false,
    String? suffix,
    bool isRequired = false,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _p.border, width: 0.5),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style:  TextStyle(color: _p.text, fontSize: 13, fontWeight: FontWeight.w600),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint + (isRequired ? " *" : ""),
          hintStyle:  TextStyle(color: _p.textDim, fontSize: 13, fontWeight: FontWeight.w500),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(icon, size: 16, color: _p.textMute),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixText: suffix,
          suffixStyle:  TextStyle(color: _p.textMute, fontSize: 11, fontWeight: FontWeight.w600),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  // ============================================================
  // SNACK
  // ============================================================

  void _showSnackBar(String message, bool isSuccess) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                isSuccess ? Icons.check_rounded : Icons.error_outline_rounded,
                color: Colors.white, size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? _p.success : _p.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 0,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
