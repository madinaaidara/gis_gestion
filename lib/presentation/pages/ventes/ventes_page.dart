import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/produit_model.dart';
import '../../../data/models/category_model.dart';
import '../../../core/utils/packaging_utils.dart';
import '../../viewmodels/products_viewmodel.dart';
import '../../viewmodels/ventes_viewmodel.dart';
import '../../../data/repositories/shops_repository.dart';

class VentePage extends StatefulWidget {
  const VentePage({super.key});

  @override
  State<VentePage> createState() => _VentePageState();
}

class _VentePageState extends State<VentePage> {
  // Palette alignée sur la page Produits
  static const Color _bg = Color(0xFF050505);
  static const Color _surface = Color(0xFF0E0E10);
  static const Color _surfaceHi = Color(0xFF161618);
  static const Color _border = Color(0xFF222226);
  static const Color _borderHi = Color(0xFF2E2E33);
  static const Color _text = Color(0xFFF5F5F7);
  static const Color _textMute = Color(0xFF8A8A92);
  static const Color _textDim = Color(0xFF5C5C63);
  static const Color _accent = Color(0xFF7C5CFF);
  static const Color _accentSoft = Color(0xFFB8A4FF);
  static const Color _danger = Color(0xFFFF4D6D);
  static const Color _success = Color(0xFF22C55E);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _gold = Color(0xFFFBBF24);
  static const Color _info = Color(0xFF3B82F6);

  // ============================================================
  // STATE
  // ============================================================

  final searchController = TextEditingController();
  final clientNameController = TextEditingController();
  final clientPhoneController = TextEditingController();
  final amountPaidController = TextEditingController();

  String? shopId;
  String? devise;

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

  void _editCartLinePrice(VentesViewModel vm, int index, NumberFormat format) {
    final item = vm.panier[index];
    final unite = item['unite_vente'] ?? 'pièce';
    final controller = TextEditingController(
      text: (item['prix_unitaire'] ?? 0).toDouble().toStringAsFixed(0),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prix — ${item['nom']}',
                style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: const TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  suffixText: '${devise ?? 'FCFA'} / $unite',
                  filled: true,
                  fillColor: _surfaceHi,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final v = double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
                    if (v <= 0) return;
                    vm.modifierPrixLigne(index, v);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 800;

    if (isCatalogLoading) {
      return Scaffold(
        backgroundColor: _bg,
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
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
        _buildHeader(format),
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
                      _buildProductsList(format),
                      _buildCart(format),
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
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildHeader(format),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: _buildSearchBar(isPadding: false),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _buildCategoryRow(),
              ),
              Expanded(child: _buildProductsList(format)),
            ],
          ),
        ),
        Container(
          width: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x00FFFFFF), _borderHi, Color(0x00FFFFFF)],
            ),
          ),
        ),
        SizedBox(width: 420, child: _buildCart(format)),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(NumberFormat format) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 800;

    return Container(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 20, 16, isMobile ? 16 : 20, 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_accent, Color(0xFF5B3FE6)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CAISSE',
                style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.2),
              ),
              Text('Vente rapide', style: TextStyle(color: _textMute, fontSize: 11)),
            ],
          ),
          const Spacer(),
          _buildIconButton(Icons.refresh_rounded, _loadData, tooltip: 'Actualiser'),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap, {String? tooltip}) {
    final btn = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border, width: 0.5),
        ),
        child: Icon(icon, color: _text, size: 16),
      ),
    );
    if (tooltip != null) return Tooltip(message: tooltip, child: btn);
    return btn;
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar({bool isPadding = true}) {
    return Padding(
      padding: isPadding ? const EdgeInsets.fromLTRB(16, 8, 16, 4) : EdgeInsets.zero,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border, width: 0.5),
        ),
        child: TextField(
          controller: searchController,
          onChanged: (v) => context.read<ProductsViewModel>().updateSearchQuery(v.trim()),
          style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Rechercher un produit…',
            hintStyle: TextStyle(color: _textDim, fontSize: 13, fontWeight: FontWeight.w500),
            border: InputBorder.none,
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 14, right: 8),
              child: Icon(Icons.search_rounded, size: 18, color: _textMute),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16, color: _textMute),
                    onPressed: () {
                      searchController.clear();
                      context.read<ProductsViewModel>().updateSearchQuery('');
                      setState(() {});
                    },
                  )
                : const SizedBox.shrink(),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY CHIPS (purement visuel — placeholder cohérent)
  // ============================================================

  Widget _buildCategoryRow() {
    return Consumer<ProductsViewModel>(
      builder: (context, vm, _) {
        return SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCategoryChip(
                label: 'Tout',
                icon: Icons.apps_rounded,
                isActive: vm.selectedCategoryId == null,
                onTap: () => vm.selectCategory(null),
              ),
              ...vm.categories.map(
                (CategoryModel cat) => _buildCategoryChip(
                  label: cat.nom,
                  icon: Icons.label_outline_rounded,
                  isActive: vm.selectedCategoryId == cat.id,
                  onTap: () => vm.selectCategory(cat.id),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? _accent.withOpacity(0.12) : _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? _accent.withOpacity(0.4) : _border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: isActive ? _accentSoft : _textMute),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? _accentSoft : _textMute,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SEGMENTED TAB BAR (mobile)
  // ============================================================

  Widget _buildSegmentedTabBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          color: _accent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: _accent.withOpacity(0.35)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: _accentSoft,
        unselectedLabelColor: _textMute,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(height: 36, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.inventory_2_rounded, size: 14),
            SizedBox(width: 6),
            Text('Produits'),
          ])),
          Tab(height: 36, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.shopping_bag_outlined, size: 14),
            SizedBox(width: 6),
            Text('Panier'),
          ])),
        ],
      ),
    );
  }

  // ============================================================
  // PRODUCTS LIST (MOBILE)
  // ============================================================

  Widget _buildProductsList(NumberFormat format) {
    return Consumer2<ProductsViewModel, VentesViewModel>(
      builder: (context, productsVm, ventesVm, _) {
        if (productsVm.products.isEmpty) {
          return _buildEmptyState('Aucun produit', 'Ajoutez des produits à votre catalogue', Icons.inventory_2_outlined);
        }

        return ListView.builder(
          controller: _productsScrollController,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: productsVm.products.length,
          itemBuilder: (_, index) => _buildProductListItem(productsVm.products[index], format, ventesVm),
        );
      },
    );
  }

  Widget _buildProductListItem(ProduitModel p, NumberFormat format, VentesViewModel ventesVm) {
    final stockDispo = ventesVm.stockDisponible(p);
    final pAffiche = p.copyWith(stock: stockDispo < 0 ? 0 : stockDispo);
    final isOutOfStock = stockDispo <= 0;
    final unite = p.uniteVente ?? 'pièce';
    final level = PackagingUtils.stockLevel(pAffiche);
    final stockColor = level == StockLevel.rupture
        ? _danger
        : (level == StockLevel.faible ? _warning : _success);
    final stockIcon = level == StockLevel.rupture
        ? '✗'
        : (level == StockLevel.faible ? '!' : '✓');
    var texteStock = PackagingUtils.formatStock(pAffiche);
    if (stockDispo < p.stock) {
      texteStock = '$texteStock dispo';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isOutOfStock ? null : () => _quickAddToCart(p),
          onLongPress: isOutOfStock ? null : () => _openProductModal(p),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _accent.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.inventory_2_rounded, color: _accentSoft, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nom,
                        style: TextStyle(
                          color: isOutOfStock ? _textMute : _text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${format.format(p.prixVenteUnitaire)} / $unite',
                        style: TextStyle(
                          color: isOutOfStock ? _textDim : _text,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: isOutOfStock ? null : () => _openProductModal(p),
                  icon: Icon(Icons.tune_rounded, size: 18, color: isOutOfStock ? _textDim : _accentSoft),
                  tooltip: 'Prix, unité & quantité',
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: stockColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: stockColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(stockIcon, style: TextStyle(fontSize: 10, color: stockColor)),
                      const SizedBox(width: 4),
                      Text(
                        texteStock,
                        style: TextStyle(fontSize: 10, color: stockColor),
                      ),
                    ],
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
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border, width: 0.5),
              ),
              child: Icon(icon, color: _textDim, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: _text,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: _textMute, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MODAL PRODUIT
  // ============================================================

  void _openProductModal(ProduitModel product) {
    final qtyController = TextEditingController(text: "1");
    final saleOptions = PackagingUtils.saleOptions(product);
    final initialOption = saleOptions.first;

    final priceController = TextEditingController(
      text: PackagingUtils.priceForUnit(product, initialOption.unite).toStringAsFixed(0),
    );
    final ventesVm = Provider.of<VentesViewModel>(context, listen: false);
    final double maxStock = ventesVm.stockDisponible(product);

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
              priceController.text = currentPrice.toStringAsFixed(0);
            });
          }

          double totalLigne = currentQty * currentPrice;
          double stockNecessaire = currentQty * facteurConversion;
          bool stockDepasse = stockNecessaire > maxStock;
          final stockProgress = (maxStock > 0 ? stockNecessaire / maxStock : 0.0).clamp(0.0, 1.0);

          return Container(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 20,
              bottom: 24 + MediaQuery.of(stateContext).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: Border(top: BorderSide(color: _borderHi, width: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: _borderHi,
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
                        color: _accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _accent.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.inventory_2_rounded, color: _accentSoft, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            product.nom,
                            style: const TextStyle(
                              color: _text,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 6, height: 6,
                                decoration: BoxDecoration(
                                  color: maxStock > 0 ? _success : _danger,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                PackagingUtils.formatStock(product),
                                style: const TextStyle(
                                  color: _textMute,
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
                      final factorLabel = opt.factorToBase == 1
                          ? opt.label
                          : '${opt.label} (×${opt.factorToBase.toStringAsFixed(opt.factorToBase % 1 == 0 ? 0 : 1)} $baseUnite)';
                      return InkWell(
                        onTap: () => updateUnite(opt),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? _accent.withOpacity(0.15) : _surfaceHi,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active ? _accent.withOpacity(0.45) : _border,
                            ),
                          ),
                          child: Text(
                            factorLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                              color: active ? _accentSoft : _textMute,
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
                        color: _surfaceHi,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _border, width: 0.5),
                      ),
                      child: TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          suffix: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              '${devise ?? 'FCFA'} / $selectedUnite',
                              style: const TextStyle(
                                color: _textMute,
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
                                    color: _surfaceHi,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _border, width: 0.5),
                                  ),
                                  child: TextField(
                                    controller: qtyController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: _text,
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
                              color: _accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _accent.withOpacity(0.3), width: 0.5),
                            ),
                            child: Center(
                              child: Text(
                                NumberFormat.currency(locale: 'fr_FR', symbol: devise ?? 'FCFA', decimalDigits: 0).format(totalLigne),
                                style: const TextStyle(
                                  color: _accentSoft,
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
                    color: _surfaceHi,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border, width: 0.5),
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
                                const Text(
                                  "STOCK",
                                  style: TextStyle(
                                    color: _textDim,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "${stockNecessaire.toStringAsFixed(stockNecessaire % 1 == 0 ? 0 : 1)} / ${maxStock.toStringAsFixed(maxStock % 1 == 0 ? 0 : 1)} $baseUnite",
                                  style: TextStyle(
                                    color: stockDepasse ? _danger : _textMute,
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
                                style: const TextStyle(color: _textDim, fontSize: 10),
                              ),
                            ],
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: stockProgress,
                                backgroundColor: _border,
                                color: stockDepasse ? _danger : (stockProgress > 0.7 ? _gold : _success),
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
                      color: _danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _danger.withOpacity(0.3), width: 0.5),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 16, color: _danger),
                        SizedBox(width: 8),
                        Text(
                          "Stock insuffisant pour cette quantité",
                          style: TextStyle(
                            color: _danger,
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
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(modalContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: _border, width: 0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          foregroundColor: _textMute,
                        ),
                        child: const Text(
                          "Annuler",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: stockDepasse || currentPrice <= 0 ? null : () {
                          Navigator.pop(modalContext);
                          _addToCart(product, currentQty, currentPrice, selectedUnite, facteurConversion);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: _accent,
                          disabledBackgroundColor: _surfaceHi,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_shopping_cart_rounded,
                              size: 16,
                              color: stockDepasse ? _textDim : Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Ajouter au panier",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                color: stockDepasse ? _textDim : Colors.white,
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
          );
        },
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: _textDim,
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
            color: enabled ? _accent.withOpacity(0.1) : _surfaceHi,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled ? _accent.withOpacity(0.3) : _border,
              width: 0.5,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? _accentSoft : _textDim,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CART
  // ============================================================

  Widget _buildCart(NumberFormat format) {
    return Container(
      color: _bg,
      child: Consumer<VentesViewModel>(
        builder: (context, vm, _) {
          if (vm.panier.isEmpty) {
            return _buildEmptyCart();
          }

          return Column(
            children: [
              _buildCartHeader(vm),
              Expanded(child: _buildCartItems(vm, format)),
              _buildCartFooter(vm, format),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border, width: 0.5),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 32,
                color: _textDim.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Panier vide",
              style: TextStyle(
                color: _text,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Tapez un produit pour l'ajouter · crayon pour le prix",
              style: TextStyle(color: _textMute, fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartHeader(VentesViewModel vm) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: _border, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shopping_bag_rounded, color: _accentSoft, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "PANIER",
                  style: TextStyle(
                    color: _text,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "${vm.panier.length}",
                        style: const TextStyle(
                          color: _accentSoft,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      vm.panier.length > 1 ? "articles" : "article",
                      style: const TextStyle(
                        color: _textMute,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => vm.viderPanier(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _danger.withOpacity(0.2), width: 0.5),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: _danger, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(VentesViewModel vm, NumberFormat format) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: vm.panier.length,
      itemBuilder: (context, index) {
        final item = vm.panier[index];
        final prixActuel = (item['prix_unitaire'] ?? 0).toDouble();
        final qty = (item['quantite'] ?? 1) as int;
        final totalLigne = prixActuel * qty;
        final uniteVente = item['unite_vente'] ?? 'pièce';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border, width: 0.5),
          ),
          child: Row(
            children: [
              // Qty badge
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "$qty",
                    style: const TextStyle(
                      color: _accentSoft,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Item info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item['nom'] ?? '',
                      style: const TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    InkWell(
                      onTap: () => _editCartLinePrice(vm, index, format),
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${format.format(prixActuel)} / $uniteVente',
                            style: const TextStyle(
                              color: _textMute,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.edit_outlined, size: 12, color: _accentSoft.withOpacity(0.8)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Stepper
              Row(
                children: [
                  _buildMiniStepper(
                    Icons.remove_rounded,
                    () => vm.modifierQuantite(index, qty - 1),
                  ),
                  const SizedBox(width: 6),
                  _buildMiniStepper(
                    Icons.add_rounded,
                    () => vm.modifierQuantite(index, qty + 1),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Total
              SizedBox(
                width: 80,
                child: Text(
                  format.format(totalLigne),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStepper(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          width: 26, height: 26,
          decoration: BoxDecoration(
            color: _surfaceHi,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: _border, width: 0.5),
          ),
          child: Icon(icon, size: 12, color: _text),
        ),
      ),
    );
  }

  // ============================================================
  // CART FOOTER
  // ============================================================

  Widget _buildCartFooter(VentesViewModel vm, NumberFormat format) {
    final modeCredit = vm.isCreditMode;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: _bg,
        border: const Border(top: BorderSide(color: _border, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Total hero
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _accent.withOpacity(0.12),
                  _accent.withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accent.withOpacity(0.25), width: 0.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "TOTAL",
                      style: TextStyle(
                        color: _accentSoft.withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${vm.panier.length} article${vm.panier.length > 1 ? 's' : ''}",
                      style: const TextStyle(
                        color: _textMute,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  format.format(vm.totalTTC),
                  style: const TextStyle(
                    color: _text,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Payment mode segmented
          Container(
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border, width: 0.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSegmentedItem(
                    "Espèces",
                    Icons.payments_rounded,
                    !modeCredit,
                    _accent,
                    () => vm.setCreditMode(false),
                  ),
                ),
                Expanded(
                  child: _buildSegmentedItem(
                    "Crédit",
                    Icons.schedule_rounded,
                    modeCredit,
                    _gold,
                    () => vm.setCreditMode(true),
                  ),
                ),
              ],
            ),
          ),

          if (modeCredit) ...[
            const SizedBox(height: 14),
            _buildPremiumField(
              clientNameController,
              "Nom du client",
              Icons.person_outline_rounded,
              isRequired: true,
            ),
            const SizedBox(height: 8),
            _buildPremiumField(
              amountPaidController,
              "Acompte",
              Icons.account_balance_wallet_outlined,
              suffix: devise,
              isNumber: true,
              onChanged: (v) => vm.setAmountPaid(double.tryParse(v) ?? 0),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _gold.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _gold.withOpacity(0.25), width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: _gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(Icons.hourglass_bottom_rounded, color: _gold, size: 14),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Reste à payer",
                    style: TextStyle(
                      color: _textMute,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    format.format(vm.montantRestant),
                    style: const TextStyle(
                      color: _gold,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // CTA
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _validateSale,
              style: ElevatedButton.styleFrom(
                backgroundColor: modeCredit ? _gold : _accent,
                disabledBackgroundColor: _surfaceHi,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    modeCredit ? Icons.receipt_long_rounded : Icons.point_of_sale_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    modeCredit ? "VALIDER LE CRÉDIT" : "ENCAISSER",
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 0.8,
                      color: Colors.white,
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
              Icon(icon, size: 14, color: active ? color : _textMute),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? color : _textMute,
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
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint + (isRequired ? " *" : ""),
          hintStyle: const TextStyle(color: _textDim, fontSize: 13, fontWeight: FontWeight.w500),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(icon, size: 16, color: _textMute),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixText: suffix,
          suffixStyle: const TextStyle(color: _textMute, fontSize: 11, fontWeight: FontWeight.w600),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? _success : _danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 0,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
