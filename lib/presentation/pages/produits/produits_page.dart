import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../viewmodels/products_viewmodel.dart';
import '../../../data/models/produit_model.dart';
import '../../../data/repositories/products_repository.dart';
import '../../../data/repositories/shops_repository.dart';
import '../../../core/utils/packaging_utils.dart';
import 'produit_form_panel.dart';
import 'produit_guidance_widgets.dart';

/// Catalogue produits — layout épuré type Spotify (liste dense, formulaire en panneau).
class ProduitsPage extends StatefulWidget {
  const ProduitsPage({super.key});

  @override
  State<ProduitsPage> createState() => _ProduitsPageState();
}

class _ProduitsPageState extends State<ProduitsPage> {
  static const Color _bg = Color(0xFF050505);
  static const Color _surface = Color(0xFF0E0E10);
  static const Color _surfaceHi = Color(0xFF161618);
  static const Color _border = Color(0xFF222226);
  static const Color _text = Color(0xFFF5F5F7);
  static const Color _textMute = Color(0xFF8A8A92);
  static const Color _textDim = Color(0xFF5C5C63);
  static const Color _accent = Color(0xFF7C5CFF);
  static const Color _danger = Color(0xFFFF4D6D);

  final rechercheController = TextEditingController();
  bool _filterGrossisteOnly = false;
  String? shopId;
  String? devise;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeAndLoad());
  }

  @override
  void dispose() {
    rechercheController.dispose();
    super.dispose();
  }

  Future<void> _initializeAndLoad() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final shopsRepo = context.read<ShopsRepository>();
      await shopsRepo.checkAndLoadShop(userId);
      if (!mounted || shopsRepo.currentShop?.id == null) return;

      setState(() {
        shopId = shopsRepo.currentShop!.id;
        devise = shopsRepo.currentShop!.devise;
      });
      await context.read<ProductsViewModel>().initializeCatalog(shopId!);
    } catch (e) {
      debugPrint('Erreur initialisation produits: $e');
    }
  }

  List<ProduitModel> _displayList(ProductsViewModel vm) {
    var list = vm.products;
    if (_filterGrossisteOnly) {
      list = list.where((p) => p.approvisionneViaGrossiste || p.vendEnGros).toList();
    }
    if (vm.stockFaibleFilterOnly) {
      list = list.where((p) => PackagingUtils.stockLevel(p) == StockLevel.faible).toList();
    }
    return list;
  }

  Future<void> _openForm({ProduitModel? product}) async {
    if (shopId == null) return;
    final vm = context.read<ProductsViewModel>();
    final ok = await ProduitFormPanel.open(
      context,
      shopId: shopId!,
      devise: devise ?? 'FCFA',
      categories: vm.categories,
      editProduct: product,
    );
    if (ok == true && mounted) {
      _snack(product != null ? 'Produit modifié' : 'Produit ajouté', success: true);
    }
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 13)),
        backgroundColor: _surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _deleteProduct(String id) async {
    final repo = context.read<ProductsRepository>();
    if (await repo.deleteProduct(id) && mounted) {
      await context.read<ProductsViewModel>().refreshProducts();
      _snack('Produit supprimé', success: true);
    } else if (mounted) {
      _snack(repo.errorMessage.isNotEmpty ? repo.errorMessage : 'Erreur suppression');
    }
  }

  void _confirmDelete(ProduitModel p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: _border)),
        title: const Text('Supprimer ce produit ?', style: TextStyle(color: _text, fontSize: 16)),
        content: Text('« ${p.nom} » sera retiré du catalogue.', style: const TextStyle(color: _textMute, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler', style: TextStyle(color: _textMute))),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (p.id != null) _deleteProduct(p.id!);
            },
            style: FilledButton.styleFrom(backgroundColor: _danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showFilters(ProductsViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Afficher seulement…', style: GoogleFonts.plusJakartaSans(color: _text, fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('Choisissez ce que vous voulez voir dans la liste.', style: TextStyle(color: _textDim, fontSize: 12)),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Produits achetés chez le grossiste', style: TextStyle(color: _text, fontSize: 13)),
              subtitle: const Text('Cartons, sacs, gros conditionnements', style: TextStyle(color: _textDim, fontSize: 11)),
              value: _filterGrossisteOnly,
              activeTrackColor: ProduitUi.accent.withValues(alpha: 0.5),
              activeThumbColor: ProduitUi.accent,
              onChanged: (v) {
                setState(() => _filterGrossisteOnly = v);
                Navigator.pop(ctx);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Produits bientôt finis', style: TextStyle(color: _text, fontSize: 13)),
              subtitle: const Text('Stock faible — pensez à racheter', style: TextStyle(color: _textDim, fontSize: 11)),
              value: vm.stockFaibleFilterOnly,
              activeTrackColor: ProduitUi.warning.withValues(alpha: 0.5),
              activeThumbColor: ProduitUi.warning,
              onChanged: (v) {
                if (vm.stockFaibleFilterOnly != v) vm.toggleStockFaibleFilter();
                setState(() {});
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(ProduitModel p) {
    final d = devise ?? 'FCFA';
    final unite = p.uniteVente ?? 'pièce';
    final cout = p.quantiteParUnite > 0 ? p.prixAchatTotal / p.quantiteParUnite : 0.0;
    final marge = p.prixVenteUnitaire - cout;
    final stockText = PackagingUtils.formatStock(p);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: ProduitUi.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.inventory_2_outlined, color: ProduitUi.accentSoft, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.nom, style: GoogleFonts.plusJakartaSans(color: _text, fontSize: 18, fontWeight: FontWeight.w800)),
                        if (p.categoryNom?.isNotEmpty == true)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(p.categoryNom!, style: const TextStyle(color: _textDim, fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                  ProduitStockBadge(product: p),
                ],
              ),
              const SizedBox(height: 14),
              ProduitHelpTip(
                color: ProduitUi.accent,
                title: 'En bref',
                message: 'Prix client : ${p.prixVenteUnitaire.toStringAsFixed(0)} $d par $unite. '
                    '${ProduitUi.gainSimple(marge, d, unite)}',
              ),
              const SizedBox(height: 12),
              ProduitInfoTile(
                label: 'Prix pour le client',
                value: '${p.prixVenteUnitaire.toStringAsFixed(0)} $d / $unite',
                color: ProduitUi.vente,
                icon: Icons.sell_outlined,
              ),
              ProduitInfoTile(
                label: 'Ce que ça vous coûte (achat)',
                value: cout > 0 ? '${cout.toStringAsFixed(0)} $d / $unite' : 'Non renseigné',
                color: ProduitUi.achat,
                icon: Icons.shopping_bag_outlined,
              ),
              ProduitInfoTile(
                label: 'Il en reste',
                value: stockText,
                color: ProduitUi.stockColor(p),
                icon: Icons.warehouse_outlined,
              ),
              if (p.fournisseur?.isNotEmpty == true)
                ProduitInfoTile(
                  label: 'Fournisseur',
                  value: p.fournisseur!,
                  color: _textMute,
                  icon: Icons.local_shipping_outlined,
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _openForm(product: p);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Modifier'),
                      style: OutlinedButton.styleFrom(foregroundColor: _text, side: const BorderSide(color: _border)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDelete(p);
                    },
                    style: IconButton.styleFrom(backgroundColor: _danger.withValues(alpha: 0.2), foregroundColor: _danger),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final isLoading = context.watch<ProductsViewModel>().isLoading;

    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: isWide
          ? null
          : FloatingActionButton(
              onPressed: () => _openForm(),
              backgroundColor: _accent,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildToolbar(isWide),
                const ProduitWelcomeStrip(),
                _buildCategoryStrip(),
                _buildStatsLine(),
                const ProduitStockLegend(),
                Expanded(child: isWide ? _buildDesktopList() : _buildMobileList()),
              ],
            ),
    );
  }

  Widget _buildToolbar(bool isWide) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, isWide ? 8 : 12, isWide ? 24 : 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _border),
              ),
              child: TextField(
                controller: rechercheController,
                onChanged: (v) => context.read<ProductsViewModel>().updateSearchQuery(v.trim()),
                style: const TextStyle(color: _text, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Chercher un produit…',
                  hintStyle: TextStyle(color: _textDim, fontSize: 13),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: _textMute),
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Consumer<ProductsViewModel>(
            builder: (context, vm, _) {
              final hasFilter = _filterGrossisteOnly || vm.stockFaibleFilterOnly;
              return IconButton(
                onPressed: () => _showFilters(vm),
                icon: Badge(
                  isLabelVisible: hasFilter,
                  smallSize: 8,
                  child: const Icon(Icons.tune_rounded, color: _textMute),
                ),
                tooltip: 'Filtres',
              );
            },
          ),
          if (isWide) ...[
            const SizedBox(width: 4),
            FilledButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Ajouter'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryStrip() {
    return Consumer<ProductsViewModel>(
      builder: (context, vm, _) => SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _catChip('Tout', vm.selectedCategoryId == null, () => vm.selectCategory(null)),
            ...vm.categories.map((c) => _catChip(c.nom, vm.selectedCategoryId == c.id, () => vm.selectCategory(c.id))),
          ],
        ),
      ),
    );
  }

  Widget _catChip(String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: active ? Colors.black : _textMute, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
        selected: active,
        onSelected: (_) {
          HapticFeedback.selectionClick();
          onTap();
        },
        backgroundColor: _surfaceHi,
        selectedColor: Colors.white,
        showCheckmark: false,
        side: BorderSide(color: active ? Colors.white : _border),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildStatsLine() {
    return Consumer<ProductsViewModel>(
      builder: (context, vm, _) {
        final alerts = vm.faibleCatalog + vm.ruptureCatalog;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
          child: Row(
            children: [
              Text(
                '${vm.totalCatalog} produit${vm.totalCatalog > 1 ? 's' : ''}',
                style: const TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(' · ', style: TextStyle(color: _textDim.withValues(alpha: 0.6))),
              Text(
                '${vm.enStockCatalog} en stock',
                style: const TextStyle(color: ProduitUi.success, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              if (alerts > 0) ...[
                Text(' · ', style: TextStyle(color: _textDim.withValues(alpha: 0.6))),
                Text(
                  '$alerts à surveiller',
                  style: const TextStyle(color: ProduitUi.warning, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopList() {
    return Consumer<ProductsViewModel>(
      builder: (context, vm, _) {
        if (vm.products.isEmpty) return _emptyState(vm);
        final items = _displayList(vm);
        if (items.isEmpty) return _emptyFilter();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              child: Row(
                children: [
                  _colHeader('#', width: 36),
                  _colHeader('Produit', flex: 4),
                  _colHeader('Prix client', flex: 2),
                  _colHeader('Il en reste', flex: 2),
                  _colHeader('', flex: 1),
                ],
              ),
            ),
            const Divider(height: 1, color: _border),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: _border, indent: 24, endIndent: 24),
                itemBuilder: (_, i) => _desktopRow(items[i], i + 1),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _colHeader(String t, {int flex = 1, double? width}) {
    final child = Text(t.toUpperCase(), style: const TextStyle(color: _textDim, fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w600));
    if (width != null) return SizedBox(width: width, child: child);
    return Expanded(flex: flex, child: child);
  }

  Widget _desktopRow(ProduitModel p, int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDetails(p),
        hoverColor: _surfaceHi,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text('$index', style: const TextStyle(color: _textDim, fontSize: 13)),
              ),
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: ProduitUi.stockColor(p).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: ProduitUi.stockColor(p).withValues(alpha: 0.25)),
                      ),
                      child: Icon(Icons.inventory_2_outlined, size: 18, color: ProduitUi.stockColor(p)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.nom, style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(
                            [if (p.categoryNom?.isNotEmpty == true) p.categoryNom!, p.uniteVente ?? 'pièce'].join(' · '),
                            style: const TextStyle(color: _textDim, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${p.prixVenteUnitaire.toStringAsFixed(0)} ${devise ?? 'FCFA'}',
                  style: const TextStyle(color: ProduitUi.vente, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    ProduitStockBadge(product: p),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        PackagingUtils.formatStock(p),
                        style: TextStyle(color: ProduitUi.stockColor(p), fontSize: 11, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz_rounded, color: _textMute, size: 20),
                    color: _surfaceHi,
                    onSelected: (a) {
                      if (a == 'edit') _openForm(product: p);
                      if (a == 'delete') _confirmDelete(p);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                      const PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: _danger))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return Consumer<ProductsViewModel>(
      builder: (context, vm, _) {
        if (vm.products.isEmpty) return _emptyState(vm);
        final items = _displayList(vm);
        if (items.isEmpty) return _emptyFilter();

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 2),
          itemBuilder: (_, i) {
            final p = items[i];
            final stockColor = ProduitUi.stockColor(p);

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showDetails(p),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: stockColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: stockColor.withValues(alpha: 0.25)),
                        ),
                        child: Icon(Icons.inventory_2_outlined, color: stockColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.nom, style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(
                              '${p.prixVenteUnitaire.toStringAsFixed(0)} ${devise ?? 'FCFA'} / ${p.uniteVente ?? 'pièce'}',
                              style: const TextStyle(color: ProduitUi.vente, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ProduitStockBadge(product: p),
                          const SizedBox(height: 4),
                          Text(
                            PackagingUtils.formatStock(p),
                            style: TextStyle(color: stockColor, fontSize: 10, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyState(ProductsViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ProduitUi.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront_rounded, size: 40, color: ProduitUi.accentSoft),
            ),
            const SizedBox(height: 20),
            Text('Commencez ici', style: GoogleFonts.plusJakartaSans(color: _text, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              'Ajoutez ce que vous vendez dans votre boutique.\nL\'application calcule le reste pour vous.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textMute, fontSize: 13, height: 1.45),
            ),
            const SizedBox(height: 24),
            _emptyStep('1', 'Le produit', 'Nom, ex. « Riz 25 kg »', ProduitUi.accent),
            _emptyStep('2', 'Les prix', 'Combien vous payez et vendez', ProduitUi.achat),
            _emptyStep('3', 'La quantité', 'Combien il en reste en rayon', ProduitUi.stock),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajouter mon premier produit'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyStep(String num, String title, String sub, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: Text(num, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
                Text(sub, style: const TextStyle(color: _textDim, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyFilter() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 40, color: _textDim),
          const SizedBox(height: 12),
          const Text('Rien trouvé', style: TextStyle(color: _textMute, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Essayez un autre mot ou enlevez les filtres', style: TextStyle(color: _textDim, fontSize: 12)),
        ],
      ),
    );
  }
}
