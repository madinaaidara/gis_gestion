// lib/presentation/pages/ventes/vente_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/produit_model.dart';
import '../../viewmodels/products_viewmodel.dart';
import '../../viewmodels/ventes_viewmodel.dart';
import '../../../data/repositories/shops_repository.dart';

class VentePage extends StatefulWidget {
  const VentePage({super.key});

  @override
  State<VentePage> createState() => _VentePageState();
}

class _VentePageState extends State<VentePage> {
  // ===== PALETTE DARK PREMIUM =====
  static const Color _bg = Color(0xFF050505);
  static const Color _surface = Color(0xFF0E0E10);
  static const Color _surfaceHi = Color(0xFF161618);
  static const Color _border = Color(0xFF222226);
  static const Color _text = Color(0xFFF5F5F7);
  static const Color _textMute = Color(0xFF8A8A92);
  static const Color _textDim = Color(0xFF5C5C63);
  static const Color _accent = Color(0xFF7C5CFF);
  static const Color _gold = Color(0xFFFFC857);
  static const Color _danger = Color(0xFFFF4D6D);
  static const Color _success = Color(0xFF22C55E);
  static const Color _borderHi = Color(0xFF7C5CFF);

  final searchController = TextEditingController();
  final clientNameController = TextEditingController();
  final clientPhoneController = TextEditingController();
  final amountPaidController = TextEditingController();

  String? shopId;
  String? devise;
  String? selectedCategoryId;

  double todaySales = 0;
  int todayTransactions = 0;
  double todayProfit = 0;

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

      final shopRepo = Provider.of<ShopsRepository>(context, listen: false);
      await shopRepo.checkAndLoadShop(userId);
      if (shopRepo.currentShop == null) return;

      shopId = shopRepo.currentShop!.id;

      final productsVM = Provider.of<ProductsViewModel>(context, listen: false);
      await productsVM.initializeCatalog(shopId!);
      await _loadStats();

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Erreur chargement: $e');
    }
  }

  Future<void> _loadStats() async {
    if (shopId == null) return;
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();

      final response = await Supabase.instance.client
          .from('ventes')
          .select('montant_total, benefice_reel')
          .eq('shop_id', shopId!)
          .gte('created_at', startOfDay);

      final data = List<Map<String, dynamic>>.from(response);

      double sales = 0;
      double profit = 0;
      for (final v in data) {
        sales += (v['montant_total'] ?? 0).toDouble();
        profit += (v['benefice_reel'] ?? 0).toDouble();
      }

      if (mounted) {
        setState(() {
          todaySales = sales;
          todayTransactions = data.length;
          todayProfit = profit;
        });
      }
    } catch (e) {
      debugPrint('Erreur stats: $e');
    }
  }

  void _addToCart(ProduitModel produit, int qty, double price) {
    final vm = Provider.of<VentesViewModel>(context, listen: false);

    final indexExistant = vm.panier.indexWhere((item) => item['produit_id'] == produit.id);
    final int qtyDansPanier = indexExistant >= 0 ? (vm.panier[indexExistant]['quantite'] ?? 0) as int : 0;

    if ((qty + qtyDansPanier) > produit.stock) {
      _showSnackBar("Stock: ${produit.stock.toInt()} restant(s)", false);
      return;
    }

    vm.ajouterAuPanier(produit, qty, price);
    _showSnackBar("✓ ${produit.nom} ajouté", true);
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
      await _loadStats();
      if (mounted) {
        await Provider.of<ProductsViewModel>(context, listen: false).refreshProducts();
      }
    } else {
      _showSnackBar("Erreur d'enregistrement", false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.currency(locale: 'fr_FR', symbol: devise ?? 'FCFA', decimalDigits: 0);
    final isCatalogLoading = context.watch<ProductsViewModel>().isLoading;
    final isMobile = MediaQuery.of(context).size.width < 800;

    if (isCatalogLoading) {
      return Scaffold(
        backgroundColor: _bg,
        body: const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2)),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: isMobile ? _buildMobileLayout(format) : _buildDesktopLayout(format),
      ),
    );
  }

  // ==================== LAYOUT MOBILE ====================
  Widget _buildMobileLayout(NumberFormat format) {
    return Column(
      children: [
        _buildHeader(format),
        _buildSearchBar(),
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.inventory_2), text: 'Produits'),
                    Tab(icon: Icon(Icons.shopping_cart), text: 'Panier'),
                  ],
                  indicatorColor: _accent,
                  labelColor: _accent,
                  unselectedLabelColor: _textMute,
                ),
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

  // ==================== LAYOUT DESKTOP ====================
  Widget _buildDesktopLayout(NumberFormat format) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildHeader(format),
              _buildSearchBar(),
              _buildCategoryFilters(),
              Expanded(child: _buildProductsGrid(format)),
            ],
          ),
        ),
        Container(width: 1, color: _border),
        Container(width: 400, child: _buildCart(format)),
      ],
    );
  }

  // ==================== HEADER ====================
  Widget _buildHeader(NumberFormat format) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [_accent, Color(0xFF5B3FE6)]), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("CAISSE", style: TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.bold)),
            Text("Point de vente", style: TextStyle(color: _textMute, fontSize: 10)),
          ]),
          const Spacer(),
          _buildStatBadge(format.format(todaySales), Icons.trending_up, _success),
          const SizedBox(width: 6),
          _buildStatBadge("$todayTransactions", Icons.receipt, _accent),
          const SizedBox(width: 6),
          if (!isMobile) _buildStatBadge(format.format(todayProfit), Icons.wallet, _gold),
          const SizedBox(width: 6),
          _buildIconButton(Icons.refresh_rounded, _loadData),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Row(children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(color: _text, fontSize: 10, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
        child: Icon(icon, color: _text, size: 14),
      ),
    );
  }

  // ==================== SEARCH ====================
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        height: 40,
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
        child: TextField(
          controller: searchController,
          onChanged: (v) => context.read<ProductsViewModel>().updateSearchQuery(v.trim()),
          style: const TextStyle(color: _text, fontSize: 13),
          decoration: InputDecoration(
            hintText: "Rechercher...",
            hintStyle: const TextStyle(fontSize: 12, color: _textDim),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, size: 16, color: _textMute),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
    );
  }

  // ==================== CATEGORY FILTERS ====================
  Widget _buildCategoryFilters() {
    return Consumer<ProductsViewModel>(
      builder: (context, vm, _) {
        return SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: vm.categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              if (index == 0) return _buildFilterChip("Tous", null, vm.selectedCategoryId);
              final cat = vm.categories[index - 1];
              return _buildFilterChip(cat.nom, cat.id, vm.selectedCategoryId);
            },
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String? id, String? selectedId) {
    final isSelected = (id == null && selectedId == null) || (id != null && id == selectedId);
    return GestureDetector(
      onTap: () => context.read<ProductsViewModel>().selectCategory(id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _accent : _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _accent : _border),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : _textMute)),
      ),
    );
  }

  // ==================== PRODUCTS LIST ====================
  // ==================== PRODUCTS LIST (VERSION COMPACTE) ====================
  Widget _buildProductsList(NumberFormat format) {
    return Consumer<ProductsViewModel>(
      builder: (context, vm, _) {
        if (vm.products.isEmpty) {
          return const Center(child: Text("Aucun produit", style: TextStyle(color: _textMute)));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Padding réduit
          itemCount: vm.products.length,
          itemBuilder: (_, index) {
            final p = vm.products[index];
            final isOutOfStock = p.stock <= 0;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // Padding interne réduit
              leading: Container(
                width: 32, height: 32, // Plus petit
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.inventory_2, color: _accent, size: 16),
              ),
              title: Text(
                p.nom,
                style: const TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                "Stock: ${p.stock.toInt()}",
                style: TextStyle(
                  color: isOutOfStock ? _danger : _textMute,
                  fontSize: 9,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    format.format(p.prixVenteUnitaire),
                    style: const TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isOutOfStock ? _surfaceHi : _accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 10,
                      color: isOutOfStock ? _textDim : Colors.white,
                    ),
                  ),
                ],
              ),
              onTap: isOutOfStock ? null : () => _openProductModal(p),
            );
          },
        );
      },
    );
  }

  // ==================== PRODUCTS GRID (DESKTOP) ====================
  Widget _buildProductsGrid(NumberFormat format) {
    return Consumer<ProductsViewModel>(
      builder: (context, vm, _) {
        if (vm.products.isEmpty) {
          return const Center(child: Text("Aucun produit", style: TextStyle(color: _textMute)));
        }

        return GridView.builder(
          controller: _productsScrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3.2, // Changé de 2.5 à 3.2 pour plus de compacité
            crossAxisSpacing: 8,    // Réduit de 12 à 8
            mainAxisSpacing: 8,     // Réduit de 12 à 8
          ),
          itemCount: vm.products.length,
          itemBuilder: (_, index) {
            final p = vm.products[index];
            final isOutOfStock = p.stock <= 0;

            return InkWell(
              onTap: isOutOfStock ? null : () => _openProductModal(p),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Padding réduit
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(10), // Réduit de 12 à 10
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32, // Réduit de 44 à 32
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6), // Réduit de 10 à 6
                      ),
                      child: Icon(Icons.inventory_2, color: _accent, size: 16), // Réduit de 20 à 16
                    ),
                    const SizedBox(width: 8), // Réduit de 12 à 8
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            p.nom,
                            style: TextStyle(
                              color: isOutOfStock ? _textMute : _text,
                              fontSize: 11, // Réduit de 13 à 11
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isOutOfStock ? "Rupture" : "Stock: ${p.stock.toInt()}",
                            style: TextStyle(
                              color: isOutOfStock ? _danger : _textMute,
                              fontSize: 9, // Réduit de 11 à 9
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          format.format(p.prixVenteUnitaire),
                          style: const TextStyle(
                            color: _accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 11, // Réduit de 13 à 11
                          ),
                        ),
                        const SizedBox(height: 2), // Réduit de 4 à 2
                        Container(
                          padding: const EdgeInsets.all(3), // Réduit de 5 à 3
                          decoration: BoxDecoration(
                            color: isOutOfStock ? _surfaceHi : _accent,
                            borderRadius: BorderRadius.circular(4), // Réduit de 6 à 4
                          ),
                          child: Icon(
                            Icons.add,
                            size: 10, // Réduit de 12 à 10
                            color: isOutOfStock ? _textDim : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== CART ====================
  Widget _buildCart(NumberFormat format) {
    return Consumer<VentesViewModel>(
      builder: (context, vm, _) {
        if (vm.panier.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.shopping_cart_outlined, size: 48, color: _textDim),
              const SizedBox(height: 12),
              const Text("Panier vide", style: TextStyle(color: _textMute, fontSize: 14)),
              const SizedBox(height: 4),
              const Text("Ajoutez des articles", style: TextStyle(color: _textDim, fontSize: 12)),
            ]),
          );
        }

        return Column(
          children: [
            _buildCartHeader(vm),
            Expanded(child: _buildCartItems(vm, format)),
            _buildCartFooter(vm, format),
          ],
        );
      },
    );
  }

  Widget _buildCartHeader(VentesViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: _accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.shopping_bag, color: _accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("PANIER", style: TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.bold)),
            Text("${vm.panier.length} article(s)", style: const TextStyle(color: _textMute, fontSize: 11)),
          ])),
          InkWell(
            onTap: () => vm.viderPanier(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _danger.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.delete_outline, color: _danger, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(VentesViewModel vm, NumberFormat format) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: vm.panier.length,
      itemBuilder: (context, index) {
        final item = vm.panier[index];
        final prixActuel = (item['prix_unitaire'] ?? 0).toDouble();
        final qty = (item['quantite'] ?? 1) as int;
        final totalLigne = prixActuel * qty;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: _surfaceHi, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
          child: Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item['nom'] ?? '', style: const TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 12), maxLines: 1),
                  Text(format.format(prixActuel), style: TextStyle(color: _textMute, fontSize: 10)),
                ]),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => vm.modifierQuantite(index, qty - 1),
                    icon: Icon(Icons.remove_circle_outline, size: 18, color: _accent),
                    padding: EdgeInsets.zero,
                  ),
                  Text("$qty", style: const TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 12)),
                  IconButton(
                    onPressed: () => vm.modifierQuantite(index, qty + 1),
                    icon: Icon(Icons.add_circle_outline, size: 18, color: _accent),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Text(format.format(totalLigne), style: const TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartFooter(VentesViewModel vm, NumberFormat format) {
    final modeCredit = vm.isCreditMode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _surface, border: const Border(top: BorderSide(color: _border))),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("TOTAL", style: TextStyle(color: _textMute, fontSize: 12, fontWeight: FontWeight.w600)),
            Text(format.format(vm.totalTTC), style: const TextStyle(color: _accent, fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPaymentButton("Espèces", !modeCredit, _accent, () {
                  vm.setCreditMode(false);
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPaymentButton("Crédit", modeCredit, _gold, () {
                  vm.setCreditMode(true);
                }),
              ),
            ],
          ),
          if (modeCredit) ...[
            const SizedBox(height: 12),
            _buildTextField(clientNameController, "Nom client *"),
            const SizedBox(height: 8),
            _buildTextField(amountPaidController, "Acompte", isNumber: true, onChanged: (v) => vm.setAmountPaid(double.tryParse(v) ?? 0)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _gold.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("Reste à payer", style: TextStyle(color: _textMute, fontSize: 11)),
                Text(format.format(vm.montantRestant), style: TextStyle(color: _gold, fontSize: 14, fontWeight: FontWeight.bold)),
              ]),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _validateSale,
              style: ElevatedButton.styleFrom(backgroundColor: modeCredit ? _gold : _accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: Text(modeCredit ? "VALIDER CRÉDIT" : "ENCAISSER", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton(String label, bool isSelected, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : _surfaceHi,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : _border),
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: isSelected ? color : _textMute, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isNumber = false, Function(String)? onChanged}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: _text, fontSize: 13),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _textDim, fontSize: 12),
        filled: true,
        fillColor: _surfaceHi,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  // ==================== PRODUCT MODAL ====================
  void _openProductModal(ProduitModel product) {
    final qtyController = TextEditingController(text: "1");
    final priceController = TextEditingController(text: product.prixVenteUnitaire.toStringAsFixed(0));
    final double maxStock = product.stock;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (stateContext, setModalState) {
          int currentQty = int.tryParse(qtyController.text) ?? 1;
          double currentPrice = double.tryParse(priceController.text) ?? 0;
          double totalLigne = currentQty * currentPrice;
          bool stockDepasse = currentQty > maxStock;

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: _surface, borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _borderHi, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: _accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.shopping_cart, color: _accent, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(product.nom, style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1),
                      Text("Stock: ${product.stock.toInt()}", style: const TextStyle(color: _textMute, fontSize: 12)),
                    ])),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text("Prix", style: TextStyle(color: _textMute, fontSize: 11)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.bold),
                          onChanged: (_) => setModalState(() {}),
                          decoration: InputDecoration(
                            suffixText: devise,
                            filled: true,
                            fillColor: _surfaceHi,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text("Quantité", style: TextStyle(color: _textMute, fontSize: 11)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: currentQty > 1 ? () {
                                qtyController.text = (currentQty - 1).toString();
                                setModalState(() {});
                              } : null,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: currentQty > 1 ? _accent.withOpacity(0.1) : _surfaceHi, borderRadius: BorderRadius.circular(6)),
                                child: Icon(Icons.remove, size: 14, color: currentQty > 1 ? _accent : _textDim),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: TextField(
                                controller: qtyController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.bold),
                                onChanged: (_) => setModalState(() {}),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: _surfaceHi,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: currentQty < maxStock ? () {
                                qtyController.text = (currentQty + 1).toString();
                                setModalState(() {});
                              } : null,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: currentQty < maxStock ? _accent.withOpacity(0.1) : _surfaceHi, borderRadius: BorderRadius.circular(6)),
                                child: Icon(Icons.add, size: 14, color: currentQty < maxStock ? _accent : _textDim),
                              ),
                            ),
                          ],
                        ),
                      ]),
                    ),
                  ],
                ),
                if (stockDepasse) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _danger.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Row(children: [
                      Icon(Icons.warning, size: 14, color: _danger),
                      SizedBox(width: 8),
                      Text("Stock insuffisant", style: TextStyle(color: _danger, fontSize: 11)),
                    ]),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _surfaceHi, borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text("TOTAL", style: TextStyle(color: _textMute, fontSize: 11)),
                    Text(NumberFormat.currency(locale: 'fr_FR', symbol: devise ?? 'FCFA', decimalDigits: 0).format(totalLigne), style: const TextStyle(color: _accent, fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(modalContext),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10), side: BorderSide(color: _border)),
                        child: const Text("Annuler"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: stockDepasse ? null : () {
                          Navigator.pop(modalContext);
                          _addToCart(product, currentQty, currentPrice);
                        },
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10), backgroundColor: _accent),
                        child: const Text("Ajouter au panier"),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(stateContext).viewInsets.bottom),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSnackBar(String message, bool isSuccess) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? _success : _danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}