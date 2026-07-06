import 'package:flutter/material.dart';
import '../../../core/theme/gis_palette.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../viewmodels/products_viewmodel.dart';
import '../../../data/models/produit_model.dart';
import '../../../data/repositories/products_repository.dart';
import '../../../data/repositories/shops_repository.dart';
import '../../../core/services/app_refresh_listener.dart';
import '../../../core/services/app_refresh_notifier.dart';
import '../../../core/utils/packaging_utils.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../widgets/gis_ui_kit.dart';
import '../../widgets/gis_dashboard_widgets.dart';
import 'produit_form_panel.dart';
import 'produit_guidance_widgets.dart';

/// Catalogue produits — layout épuré type Spotify (liste dense, formulaire en panneau).
class ProduitsPage extends StatefulWidget {
  const ProduitsPage({super.key});

  @override
  State<ProduitsPage> createState() => _ProduitsPageState();
}

class _ProduitsPageState extends State<ProduitsPage> with AppRefreshListener {
  GisPalette get _p => GisPalette.of(context);

  @override
  AppRefreshScope get refreshScope => AppRefreshScope.products;

  @override
  void onAppRefresh() {
    if (shopId != null) {
      context.read<ProductsViewModel>().refreshProducts();
    }
  }


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
        content: Text(msg, style: TextStyle(fontSize: 13)),
        backgroundColor: _p.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _deleteProduct(String id) async {
    final repo = context.read<ProductsRepository>();
    if (await repo.deleteProduct(id) && mounted) {
      await context.read<ProductsViewModel>().refreshProducts();
      refreshAppData(context);
      _snack('Produit supprimé', success: true);
    } else if (mounted) {
      _snack(repo.errorMessage.isNotEmpty ? repo.errorMessage : 'Erreur suppression');
    }
  }

  void _confirmDelete(ProduitModel p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side:  BorderSide(color: _p.border)),
        title:  Text('Supprimer ce produit ?', style: TextStyle(color: _p.text, fontSize: 16)),
        content: Text('« ${p.nom} » sera retiré du catalogue.', style:  TextStyle(color: _p.textMute, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child:  Text('Annuler', style: TextStyle(color: _p.textMute))),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (p.id != null) _deleteProduct(p.id!);
            },
            style: FilledButton.styleFrom(backgroundColor: _p.danger),
            child: Text('Supprimer'),
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
        decoration: BoxDecoration(color: _p.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _p.border)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Afficher seulement…', style: GoogleFonts.plusJakartaSans(color: _p.text, fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
             Text('Choisissez ce que vous voulez voir dans la liste.', style: TextStyle(color: _p.textDim, fontSize: 12)),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title:  Text('Produits achetés chez le grossiste', style: TextStyle(color: _p.text, fontSize: 13)),
              subtitle:  Text('Cartons, sacs, gros conditionnements', style: TextStyle(color: _p.textDim, fontSize: 11)),
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
              title:  Text('Produits bientôt finis', style: TextStyle(color: _p.text, fontSize: 13)),
              subtitle:  Text('Stock faible — pensez à racheter', style: TextStyle(color: _p.textDim, fontSize: 11)),
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
        decoration: BoxDecoration(color: _p.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _p.border)),
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
                    child: Icon(Icons.inventory_2_outlined, color: ProduitUi.accentSoft, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.nom, style: GoogleFonts.plusJakartaSans(color: _p.text, fontSize: 18, fontWeight: FontWeight.w800)),
                        if (p.categoryNom?.isNotEmpty == true)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(p.categoryNom!, style:  TextStyle(color: _p.textDim, fontSize: 12)),
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
                color: ProduitUi.stockColor(context, p),
                icon: Icons.warehouse_outlined,
              ),
              if (p.fournisseur?.isNotEmpty == true)
                ProduitInfoTile(
                  label: 'Fournisseur',
                  value: p.fournisseur!,
                  color: _p.textMute,
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
                      icon: Icon(Icons.edit_outlined, size: 18),
                      label: Text('Modifier'),
                      style: OutlinedButton.styleFrom(foregroundColor: _p.text, side:  BorderSide(color: _p.border)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDelete(p);
                    },
                    style: IconButton.styleFrom(backgroundColor: _p.danger.withValues(alpha: 0.2), foregroundColor: _p.danger),
                    icon: Icon(Icons.delete_outline_rounded),
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
    final isWide = ResponsiveUtils.isTwoColumnWide(context);
    final pad = ResponsiveUtils.pageHorizontalPadding(context);
    final bottomInset = ResponsiveUtils.scrollBottomInset(context);

    return Scaffold(
      backgroundColor: _p.bg,
      floatingActionButton: isWide
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openForm(),
              backgroundColor: _p.success,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Ajouter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
      body: Consumer<ProductsViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading && vm.products.isEmpty) {
            return Center(child: CircularProgressIndicator(color: _p.accent, strokeWidth: 2.5));
          }

          final items = _displayList(vm);

          return RefreshIndicator(
            onRefresh: () => vm.refreshProducts(),
            color: _p.accent,
            backgroundColor: _p.surface,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(child: _buildPageHeader(isWide, pad)),
                SliverToBoxAdapter(child: _buildSearchRow(isWide, pad, vm)),
                SliverToBoxAdapter(child: _buildSummaryRow(vm, pad)),
                SliverToBoxAdapter(child: _buildCategoryTabs(vm, pad)),
                if (vm.products.isEmpty)
                  SliverFillRemaining(hasScrollBody: false, child: _emptyState(vm))
                else if (items.isEmpty)
                  SliverFillRemaining(hasScrollBody: false, child: _emptyFilter())
                else
                  SliverToBoxAdapter(child: _buildProductsPanel(items, pad)),
                SliverToBoxAdapter(child: SizedBox(height: bottomInset)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageHeader(bool isWide, double pad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 20, pad, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gérez vos articles, prix et niveaux de stock',
                  style: TextStyle(color: _p.textMute, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (isWide)
            FilledButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Ajouter un produit'),
              style: FilledButton.styleFrom(
                backgroundColor: _p.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(ProductsViewModel vm, double pad) {
    final total = vm.totalCatalog;
    final ok = vm.enStockCatalog;
    final faible = vm.faibleCatalog;
    final rupture = vm.ruptureCatalog;
    final okPct = total > 0 ? ok / total : 0.0;
    final faiblePct = total > 0 ? faible / total : 0.0;
    final rupturePct = total > 0 ? rupture / total : 0.0;

    final cards = [
      (
        label: 'Total produits',
        value: '$total',
        footer: 'Dans le catalogue',
        progress: 1.0,
        icon: Icons.inventory_2_rounded,
        gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
      ),
      (
        label: 'En stock',
        value: '$ok',
        footer: 'Stock sain',
        progress: okPct,
        icon: Icons.check_circle_rounded,
        gradient: const [Color(0xFF22C55E), Color(0xFF16A34A)],
      ),
      (
        label: 'Stock faible',
        value: '$faible',
        footer: faible > 0 ? 'À réapprovisionner' : 'Aucune alerte',
        progress: faiblePct,
        icon: Icons.warning_amber_rounded,
        gradient: const [Color(0xFFF97316), Color(0xFFEA580C)],
      ),
      (
        label: 'Ruptures',
        value: '$rupture',
        footer: rupture > 0 ? 'Action urgente' : 'Tout est disponible',
        progress: rupturePct,
        icon: Icons.error_outline_rounded,
        gradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
      ),
    ];

    return GisFourKpiRow(
      horizontalPadding: pad,
      cards: [
        for (final c in cards)
          GisKpiCardItem(
            label: c.label,
            value: c.value,
            footerLabel: c.footer,
            footerProgress: c.progress,
            icon: c.icon,
            gradient: c.gradient,
          ),
      ],
    );
  }

  Widget _buildSearchRow(bool isWide, double pad, ProductsViewModel vm) {
    final hasFilter = _filterGrossisteOnly || vm.stockFaibleFilterOnly;

    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 0, pad, 12),
      child: Row(
        children: [
          Expanded(
            child: GisSearchField(
              controller: rechercheController,
              hint: 'Chercher un produit…',
              padding: EdgeInsets.zero,
              onChanged: (v) => vm.updateSearchQuery(v.trim()),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: _p.surfaceHi,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _showFilters(vm),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: hasFilter ? _p.success : _p.border),
                ),
                child: Badge(
                  isLabelVisible: hasFilter,
                  smallSize: 8,
                  child: Icon(Icons.tune_rounded, color: hasFilter ? _p.success : _p.textMute),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(ProductsViewModel vm, double pad) {
    final tabs = <(String?, String)>[(null, 'Tout'), ...vm.categories.map((c) => (c.id, c.nom))];

    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 0, pad, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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
      ),
    );
  }

  Widget _buildProductsPanel(List<ProduitModel> items, double pad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 0, pad, 8),
      child: GisEdukaPanel(
        title: 'Liste des produits',
        subtitle: '${items.length} article${items.length > 1 ? 's' : ''} affiché${items.length > 1 ? 's' : ''}',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _legendDot('OK', _p.success),
            const SizedBox(width: 10),
            _legendDot('Faible', _p.warning),
            const SizedBox(width: 10),
            _legendDot('Rupture', _p.danger),
          ],
        ),
        child: Column(
          children: [
            _buildTableHeader(),
            const SizedBox(height: 8),
            ...items.asMap().entries.map((e) => _buildProductRow(e.value, e.key + 1)),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: _p.textDim, fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Row(
      children: [
        SizedBox(width: 36, child: Text('#', style: TextStyle(color: _p.textMute, fontSize: 11, fontWeight: FontWeight.w600))),
        Expanded(flex: 4, child: Text('Produit', style: TextStyle(color: _p.textMute, fontSize: 11, fontWeight: FontWeight.w600))),
        Expanded(flex: 2, child: Text('Prix', style: TextStyle(color: _p.textMute, fontSize: 11, fontWeight: FontWeight.w600))),
        Expanded(flex: 2, child: Text('Stock', style: TextStyle(color: _p.textMute, fontSize: 11, fontWeight: FontWeight.w600))),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildProductRow(ProduitModel p, int index) {
    final stockColor = ProduitUi.stockColor(context, p);
    final statusLabel = ProduitUi.stockLabelSimple(p);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDetails(p),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: stockColor.withValues(alpha: 0.12),
                child: Text('$index', style: TextStyle(color: stockColor, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: stockColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: stockColor.withValues(alpha: 0.2)),
                      ),
                      child: Icon(Icons.inventory_2_outlined, size: 18, color: stockColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.nom,
                            style: TextStyle(color: _p.text, fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            [if (p.categoryNom?.isNotEmpty == true) p.categoryNom!, p.uniteVente ?? 'pièce'].join(' · '),
                            style: TextStyle(color: _p.textDim, fontSize: 11),
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
                  style: TextStyle(color: ProduitUi.vente, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: stockColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(color: stockColor, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      PackagingUtils.formatStock(p),
                      style: TextStyle(color: _p.textDim, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz_rounded, color: _p.textMute, size: 20),
                color: _p.surfaceHi,
                onSelected: (a) {
                  if (a == 'edit') _openForm(product: p);
                  if (a == 'delete') _confirmDelete(p);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: _p.danger))),
                ],
              ),
            ],
          ),
        ),
      ),
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
                color: _p.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.storefront_rounded, size: 40, color: _p.success),
            ),
            const SizedBox(height: 20),
            Text('Commencez ici', style: GoogleFonts.plusJakartaSans(color: _p.text, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Ajoutez ce que vous vendez dans votre boutique.\nL\'application calcule le reste pour vous.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _p.textMute, fontSize: 13, height: 1.45),
            ),
            const SizedBox(height: 24),
            _emptyStep('1', 'Le produit', 'Nom, ex. « Riz 25 kg »', _p.accent),
            _emptyStep('2', 'Les prix', 'Combien vous payez et vendez', ProduitUi.achat),
            _emptyStep('3', 'La quantité', 'Combien il en reste en rayon', ProduitUi.stock),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajouter mon premier produit'),
              style: FilledButton.styleFrom(
                backgroundColor: _p.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                Text(sub, style: TextStyle(color: _p.textDim, fontSize: 11)),
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
          Icon(Icons.search_off_rounded, size: 40, color: _p.textDim),
          const SizedBox(height: 12),
           Text('Rien trouvé', style: TextStyle(color: _p.textMute, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
           Text('Essayez un autre mot ou enlevez les filtres', style: TextStyle(color: _p.textDim, fontSize: 12)),
        ],
      ),
    );
  }
}
