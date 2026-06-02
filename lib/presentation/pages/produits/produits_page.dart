import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';

// COUCHES ARCHITECTURALES
import '../../viewmodels/products_viewmodel.dart';
import '../../../data/models/produit_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/categories_repository.dart';
import '../../../data/repositories/products_repository.dart';
import '../../../data/repositories/shops_repository.dart';

/// ============================================
/// PRODUITS PAGE - DARK PREMIUM EDITION
/// Design noir dominant cohérent avec la page de vente
/// ============================================

class ProduitsPage extends StatefulWidget {
  const ProduitsPage({super.key});

  @override
  State<ProduitsPage> createState() => _ProduitsPageState();
}

class _ProduitsPageState extends State<ProduitsPage> with TickerProviderStateMixin {
  // ===== PALETTE DARK PREMIUM (cohérente avec la page vente) =====
  static const Color _bg = Color(0xFF050505);          // fond global
  static const Color _surface = Color(0xFF0E0E10);     // cartes / panels
  static const Color _surfaceHi = Color(0xFF161618);   // élévation
  static const Color _border = Color(0xFF222226);      // bordures fines
  static const Color _borderHi = Color(0xFF2E2E33);
  static const Color _text = Color(0xFFF5F5F7);
  static const Color _textMute = Color(0xFF8A8A92);
  static const Color _textDim = Color(0xFF5C5C63);
  static const Color _accent = Color(0xFF7C5CFF);      // violet premium
  static const Color _accentSoft = Color(0xFFB8A4FF);
  static const Color _danger = Color(0xFFFF4D6D);
  static const Color _success = Color(0xFF22C55E);
  static const Color _warning = Color(0xFFF59E0B);

  // Contrôleurs
  final nomController = TextEditingController();
  final descriptionController = TextEditingController();
  final rechercheController = TextEditingController();
  final nomCategorieController = TextEditingController();
  final quantiteAchatController = TextEditingController();
  final prixAchatTotalController = TextEditingController();
  final prixVenteUnitaireController = TextEditingController();
  final stockActuelController = TextEditingController();
  final fournisseurController = TextEditingController();
  final telephoneFournisseurController = TextEditingController();

  String? selectedCategorieId;
  String selectedTypeVente = 'unite';
  String selectedUniteAchat = 'pièce';
  String selectedUniteVente = 'pièce';

  String? shopId;
  String? devise;

  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeAndLoad());
  }

  Future<void> _initializeAndLoad() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final shopsRepo = Provider.of<ShopsRepository>(context, listen: false);
      await shopsRepo.checkAndLoadShop(userId);

      if (shopsRepo.currentShop != null) {
        setState(() {
          shopId = shopsRepo.currentShop!.id;
          devise = shopsRepo.currentShop!.devise;
        });
        if (shopId != null) {
          await Provider.of<ProductsViewModel>(context, listen: false).initializeCatalog(shopId!);
        }
      }
    } catch (e) {
      debugPrint('Erreur initialisation: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(Icons.error_outline_rounded, color: _danger, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
        ]),
        backgroundColor: _surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle_outline_rounded, color: _success, size: 18),
          const SizedBox(width: 10),
          Text(message, style: const TextStyle(fontSize: 13)),
        ]),
        backgroundColor: _surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  double calculerCoutUnitaire() {
    final qte = double.tryParse(quantiteAchatController.text.trim()) ?? 0;
    final prixTotal = double.tryParse(prixAchatTotalController.text.trim()) ?? 0;
    if (qte <= 0 || prixTotal <= 0) return 0;
    return prixTotal / qte;
  }

  double calculerMargeUnitaire() {
    final cout = calculerCoutUnitaire();
    final vente = double.tryParse(prixVenteUnitaireController.text.trim()) ?? 0;
    return vente - cout;
  }

  bool get estProfitable => calculerMargeUnitaire() >= 0;

  void viderChamps() {
    nomController.clear();
    descriptionController.clear();
    quantiteAchatController.clear();
    prixAchatTotalController.clear();
    prixVenteUnitaireController.clear();
    stockActuelController.clear();
    fournisseurController.clear();
    telephoneFournisseurController.clear();
    selectedCategorieId = null;
    selectedTypeVente = 'unite';
    selectedUniteAchat = 'pièce';
    selectedUniteVente = 'pièce';
  }

  Future<void> _ajouterCategorie() async {
    if (shopId == null) return;
    final nom = nomCategorieController.text.trim();
    if (nom.isEmpty) {
      _showErrorSnackBar('Le nom de la catégorie est requis');
      return;
    }
    try {
      final categoryRepo = Provider.of<CategoriesRepository>(context, listen: false);
      final newCategory = CategoryModel(shopId: shopId, nom: nom, description: '');
      final bool success = await categoryRepo.addCategory(newCategory);
      if (success) {
        nomCategorieController.clear();
        if (mounted) {
          await Provider.of<ProductsViewModel>(context, listen: false).initializeCatalog(shopId!);
        }
        _showSuccessSnackBar('Catégorie ajoutée');
      } else {
        _showErrorSnackBar('Erreur lors de l\'ajout');
      }
    } catch (e) {
      debugPrint('Erreur ajout catégorie: $e');
    }
  }

  Future<void> _supprimerCategorie(String id) async {
    try {
      final prods = await Supabase.instance.client
          .from('products')
          .select('id')
          .eq('category_id', id);
      if ((prods as List).isNotEmpty) {
        _showErrorSnackBar('Des produits utilisent cette catégorie');
        return;
      }
      await Supabase.instance.client.from('categories').delete().eq('id', id);
      if (mounted && shopId != null) {
        await Provider.of<ProductsViewModel>(context, listen: false).initializeCatalog(shopId!);
      }
      _showSuccessSnackBar('Catégorie supprimée');
    } catch (e) {
      debugPrint('Erreur suppression catégorie: $e');
    }
  }

  Future<void> ajouterProduit() async {
    if (shopId == null) return;
    final venteUnitaire = double.tryParse(prixVenteUnitaireController.text.trim()) ?? 0;
    final double quantiteParUnite = double.tryParse(quantiteAchatController.text.trim()) ?? 1;
    final double stockSaisi = double.tryParse(stockActuelController.text.trim()) ?? 0;
    final double stockReelEnPieces = stockSaisi * quantiteParUnite;

    try {
      final productsViewModel = Provider.of<ProductsViewModel>(context, listen: false);
      final productsRepo = Provider.of<ProductsRepository>(context, listen: false);

      String? nomCategorieTrouve;
      if (selectedCategorieId != null) {
        final catMatch = productsViewModel.categories.firstWhere(
          (c) => c.id == selectedCategorieId,
          orElse: () => const CategoryModel(nom: 'Non classé'),
        );
        nomCategorieTrouve = catMatch.nom;
      }

      final newProduct = ProduitModel(
        shopId: shopId,
        categoryId: selectedCategorieId,
        categoryNom: nomCategorieTrouve,
        nom: nomController.text.trim(),
        description: descriptionController.text.trim(),
        typeVente: selectedTypeVente,
        prixAchatTotal: double.tryParse(prixAchatTotalController.text.trim()) ?? 0,
        prixVenteUnitaire: venteUnitaire,
        uniteAchat: selectedUniteAchat,
        uniteVente: selectedUniteVente,
        quantiteParUnite: quantiteParUnite,
        stock: stockReelEnPieces,
        fournisseur: fournisseurController.text.trim(),
        telephoneFournisseur: telephoneFournisseurController.text.trim(),
      );

      final bool success = await productsRepo.addProduct(newProduct);
      if (success) {
        viderChamps();
        if (mounted) {
          await Provider.of<ProductsViewModel>(context, listen: false).refreshProducts();
        }
        _showSuccessSnackBar('Produit ajouté');
      } else {
        _showErrorSnackBar(productsRepo.errorMessage);
      }
    } catch (e) {
      debugPrint('Erreur ajout produit: $e');
    }
  }

  Future<void> modifierProduit(String id) async {
    final venteUnitaire = double.tryParse(prixVenteUnitaireController.text.trim()) ?? 0;
    final double quantiteParUnite = double.tryParse(quantiteAchatController.text.trim()) ?? 1;
    final double stockSaisi = double.tryParse(stockActuelController.text.trim()) ?? 0;
    final double stockReelEnPieces = stockSaisi * quantiteParUnite;

    try {
      final productsRepo = Provider.of<ProductsRepository>(context, listen: false);
      final Map<String, dynamic> updatedFields = {
        'category_id': selectedCategorieId,
        'nom': nomController.text.trim(),
        'description': descriptionController.text.trim(),
        'type_vente': selectedTypeVente,
        'prix_achat_total': double.tryParse(prixAchatTotalController.text.trim()) ?? 0,
        'prix_vente_unitaire': venteUnitaire,
        'unite_achat': selectedUniteAchat,
        'unite_vente': selectedUniteVente,
        'quantite_par_unite': quantiteParUnite,
        'stock': stockReelEnPieces,
        'fournisseur': fournisseurController.text.trim(),
        'telephone_fournisseur': telephoneFournisseurController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      final bool success = await productsRepo.updateProduct(id, updatedFields);
      if (success) {
        viderChamps();
        if (mounted) {
          await Provider.of<ProductsViewModel>(context, listen: false).refreshProducts();
        }
        _showSuccessSnackBar('Produit modifié');
      } else {
        _showErrorSnackBar(productsRepo.errorMessage);
      }
    } catch (e) {
      debugPrint('Erreur modification produit: $e');
    }
  }

  Future<void> supprimerProduit(String id) async {
    try {
      final productsRepo = Provider.of<ProductsRepository>(context, listen: false);
      final bool success = await productsRepo.deleteProduct(id);
      if (success && mounted) {
        await Provider.of<ProductsViewModel>(context, listen: false).refreshProducts();
        _showSuccessSnackBar('Produit supprimé');
      }
    } catch (e) {
      debugPrint('Erreur suppression produit: $e');
    }
  }

  void _confirmerSuppression(String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: _border)),
        title: const Text('Supprimer ?', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text('Cette action est irréversible.', style: TextStyle(color: _textMute, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler', style: TextStyle(color: _textMute)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              supprimerProduit(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _danger, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  List<String> getUnitesAchat(String type) {
    switch (type) {
      case 'poids': return ['sac', 'kg', 'g'];
      case 'volume': return ['bidon', 'litre', 'ml'];
      case 'colis': return ['carton', 'paquet', 'sac'];
      default: return ['sac', 'carton', 'pièce', 'bouteille'];
    }
  }

  List<String> getUnitesVente(String type) {
    switch (type) {
      case 'poids': return ['kg', 'g'];
      case 'volume': return ['litre', 'ml'];
      case 'colis': return ['pièce', 'unité'];
      default: return ['pièce', 'unité', 'bouteille'];
    }
  }

  String getUniteVenteDefaut(String type) {
    switch (type) {
      case 'poids': return 'kg';
      case 'volume': return 'litre';
      default: return 'pièce';
    }
  }

  String getLabelUnite(String unite) {
    switch (unite) {
      case 'kg': return 'kg';
      case 'g': return 'g';
      case 'litre': return 'L';
      default: return unite;
    }
  }

  IconData _getIcon(String? nom) {
    switch (nom) {
      case 'Alimentation': return Icons.lunch_dining;
      case 'Boissons': return Icons.local_cafe;
      case 'Hygiène': return Icons.spa;
      case 'Maison': return Icons.home;
      default: return Icons.category;
    }
  }

  // ===========================================================================
  // BUILD PRINCIPAL
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final isCatalogLoading = context.watch<ProductsViewModel>().isLoading;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: isCatalogLoading
            ? const Center(child: CircularProgressIndicator(color: _accent))
            : Column(
                children: [
                  _buildHeader(),
                  _buildStatsBar(),
                  const SizedBox(height: 8),
                  _buildFilterBar(),
                  const SizedBox(height: 8),
                  Expanded(child: isMobile ? _buildProductsListMobile() : _buildProductsListDesktop()),
                ],
              ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ===========================================================================
  // HEADER AVEC RECHERCHE
  // ===========================================================================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_accent, Color(0xFF5B3FE6)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("PRODUITS", style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  Text("Gestion du catalogue", style: TextStyle(color: _textMute, fontSize: 11)),
                ],
              ),
              const Spacer(),
              // Bouton Catégories (AJOUTÉ)
              _buildIconButton(
                icon: Icons.category_rounded, 
                onTap: () => _afficherModalCategories(),
                color: _accent,
              ),
              const SizedBox(width: 8),
              _buildIconButton(
                icon: Icons.refresh_rounded, 
                onTap: () => _initializeAndLoad(),
                color: _textMute,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barre de recherche...
          Container(
            height: 44,
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
            child: TextField(
              controller: rechercheController,
              onChanged: (v) => context.read<ProductsViewModel>().updateSearchQuery(v.trim()),
              style: const TextStyle(color: _text, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Rechercher un produit...",
                hintStyle: const TextStyle(fontSize: 13, color: _textDim),
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: _textMute),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Modifier _buildIconButton pour accepter une couleur
  Widget _buildIconButton({required IconData icon, required VoidCallback onTap, Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Icon(icon, color: color ?? _text, size: 18),
      ),
    );
  }

  // ===========================================================================
  // MODAL GESTION CATÉGORIES
  void _afficherModalCategories() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: const Border(top: BorderSide(color: _border)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surfaceHi,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: _border)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _accent.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.category_rounded, color: _accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Text("Catégories", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _text))),
                  IconButton(onPressed: () => Navigator.pop(_), icon: Icon(Icons.close_rounded, color: _textMute)),
                ],
              ),
            ),
            // Formulaire ajout
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: nomCategorieController,
                      style: const TextStyle(color: _text),
                      decoration: InputDecoration(
                        hintText: "Nouvelle catégorie...",
                        hintStyle: TextStyle(color: _textDim),
                        filled: true,
                        fillColor: _surfaceHi,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _border)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _ajouterCategorie,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            const Divider(color: _border, height: 1),
            // Liste des catégories
            Expanded(
              child: Consumer<ProductsViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.categories.isEmpty) {
                    return const Center(child: Text("Aucune catégorie", style: TextStyle(color: _textMute)));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: viewModel.categories.length,
                    itemBuilder: (ctx, index) {
                      final cat = viewModel.categories[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: _surfaceHi, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
                        child: Row(
                          children: [
                            Icon(_getIcon(cat.nom), color: _accentSoft, size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Text(cat.nom, style: const TextStyle(color: _text, fontSize: 14))),
                            IconButton(
                              onPressed: () => _supprimerCategorie(cat.id.toString()),
                              icon: Icon(Icons.delete_outline_rounded, color: _danger, size: 18),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ===========================================================================
  // STATS BAR
  // ===========================================================================
  Widget _buildStatsBar() {
    return Consumer<ProductsViewModel>(
      builder: (context, viewModel, child) {
        int total = viewModel.products.length;
        int rupture = 0;
        int faible = 0;
        for (var p in viewModel.products) {
          if (p.stock <= 0) rupture++;
          else if (p.stock <= (p.quantiteParUnite > 1 ? p.quantiteParUnite * 0.2 : 5)) faible++;
        }
        int enStock = total - rupture;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _buildStatCard('Total', total, _accent),
              const SizedBox(width: 8),
              _buildStatCard('Stock', enStock, _success),
              const SizedBox(width: 8),
              _buildStatCard('Alerte', faible, _warning),
              const SizedBox(width: 8),
              _buildStatCard('Rupture', rupture, _danger),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: _textDim)),
            Text('$value', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // FILTRES CATÉGORIES
  // ===========================================================================
  Widget _buildFilterBar() {
    return Consumer<ProductsViewModel>(
      builder: (context, viewModel, child) {
        return SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: viewModel.categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              if (index == 0) return _buildFilterChip('Tous', null, viewModel.selectedCategoryId);
              final cat = viewModel.categories[index - 1];
              return _buildFilterChip(cat.nom, cat.id, viewModel.selectedCategoryId);
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _accent : _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _accent : _border),
        ),
        child: Center(
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? Colors.white : _textMute)),
        ),
      ),
    );
  }

  // ===========================================================================
  // LISTE PRODUITS
  // ===========================================================================
  Widget _buildProductCard(ProduitModel p) {
    final double stockVal = p.stock;
    final double prixVente = p.prixVenteUnitaire;
    final double prixAchat = p.prixAchatTotal;
    final double quantiteParUnite = p.quantiteParUnite;
    final double coutUnitaire = quantiteParUnite > 0 ? prixAchat / quantiteParUnite : 0.0;
    final double marge = prixVente - coutUnitaire;
    final bool profitable = marge >= 0;
    final String cat = p.categoryNom ?? 'Non classé';
    final bool isRupture = stockVal <= 0;
    final bool isFaible = !isRupture && stockVal <= (quantiteParUnite > 1 ? quantiteParUnite * 0.2 : 5);

    Color stockColor = _success;
    String stockIcon = "✓";
    if (isRupture) { stockColor = _danger; stockIcon = "✗"; }
    else if (isFaible) { stockColor = _warning; stockIcon = "!"; }

    String texteStock = "";
    if (stockVal >= quantiteParUnite && quantiteParUnite > 1) {
      texteStock = "${(stockVal / quantiteParUnite).toStringAsFixed(1)} ${p.uniteAchat ?? 'colis'}";
    } else {
      texteStock = "${stockVal.toStringAsFixed(0)} ${p.uniteVente ?? 'pièce'}";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _afficherDetails(p),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _accent.withOpacity(0.2)),
                ),
                child: Icon(_getIcon(cat), color: _accentSoft, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nom, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: _accent.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                          child: Text(cat, style: TextStyle(fontSize: 10, color: _accentSoft)),
                        ),
                        const SizedBox(width: 8),
                        Text('${prixVente.toStringAsFixed(0)} ${devise ?? 'FCFA'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _text)),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            Icon(profitable ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 12, color: profitable ? _success : _danger),
                            const SizedBox(width: 2),
                            Text('${marge.toStringAsFixed(0)}', style: TextStyle(fontSize: 10, color: profitable ? _success : _danger)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: stockColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: stockColor.withOpacity(0.2))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [Text(stockIcon, style: TextStyle(fontSize: 10, color: stockColor)), const SizedBox(width: 4), Text(texteStock, style: TextStyle(fontSize: 10, color: stockColor))]),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: _textMute, size: 20),
                color: _surfaceHi,  // Fond gris clair
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _border),
                ),
                onSelected: (action) {
                  if (action == 'edit') _afficherFormulaire(produit: p.toJson());
                  else if (action == 'delete') _confirmerSuppression(p.id ?? '');
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: _accent),
                        SizedBox(width: 12),
                        Text('Modifier', style: TextStyle(color: _text, fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: _danger),
                        SizedBox(width: 12),
                        Text('Supprimer', style: TextStyle(color: _danger, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 64, height: 64, decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: _border)), child: Icon(Icons.inventory_2_outlined, size: 28, color: _textDim)),
          const SizedBox(height: 16),
          const Text("Aucun produit", style: TextStyle(color: _textMute, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text("Ajoutez votre premier produit", style: TextStyle(color: _textDim, fontSize: 12)),
        ],
      ),
    );
  }

  // ===========================================================================
  // DÉTAILS PRODUIT
  // ===========================================================================
  void _afficherDetails(ProduitModel p) {
    final double prixAchat = p.prixAchatTotal;
    final double quantiteParUnite = p.quantiteParUnite;
    final double prixVente = p.prixVenteUnitaire;
    final double coutUnitaire = quantiteParUnite > 0 ? prixAchat / quantiteParUnite : 0.0;
    final double marge = prixVente - coutUnitaire;
    final bool profitable = marge >= 0;
    final double stockVal = p.stock;
    final String uniteAchat = p.uniteAchat ?? 'colis';
    final String uniteVente = p.uniteVente ?? 'pièce';

    String texteStock = "";
    if (uniteAchat == uniteVente) texteStock = "${stockVal.toStringAsFixed(0)} $uniteVente";
    else if (quantiteParUnite > 1 && stockVal >= quantiteParUnite) texteStock = "${(stockVal / quantiteParUnite).toStringAsFixed(1)} $uniteAchat";
    else texteStock = "${stockVal.toStringAsFixed(0)} $uniteVente";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: _border)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _borderHi, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(width: 48, height: 48, decoration: BoxDecoration(color: _accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: _accent.withOpacity(0.2))), child: Icon(_getIcon(p.categoryNom), color: _accentSoft, size: 24)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.nom, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _text)), Text(p.categoryNom ?? 'Non classé', style: TextStyle(fontSize: 11, color: _textMute))])),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: (profitable ? _success : _danger).withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: (profitable ? _success : _danger).withOpacity(0.2))),
                  child: Row(children: [Icon(profitable ? Icons.trending_up : Icons.trending_down, color: profitable ? _success : _danger), const SizedBox(width: 12), Expanded(child: Text(profitable ? 'Bénéfice de ${marge.toStringAsFixed(0)} $devise par $uniteVente' : 'Perte de ${marge.abs().toStringAsFixed(0)} $devise par $uniteVente', style: TextStyle(color: profitable ? _success : _danger)))]),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Prix achat lot', '${prixAchat.toStringAsFixed(0)} $devise', Icons.shopping_cart_outlined),
                const SizedBox(height: 12),
                _buildDetailRow('Conditionnement', '$quantiteParUnite $uniteVente / $uniteAchat', Icons.inventory_2_outlined),
                const SizedBox(height: 12),
                _buildDetailRow('Prix vente', '${prixVente.toStringAsFixed(0)} $devise / $uniteVente', Icons.sell_outlined),
                const SizedBox(height: 12),
                _buildDetailRow('Stock actuel', texteStock, Icons.tag_rounded),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, height: 44, child: OutlinedButton(onPressed: () => Navigator.pop(_), style: OutlinedButton.styleFrom(side: BorderSide(color: _border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Fermer'))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(children: [Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: _accent.withOpacity(0.08), borderRadius: BorderRadius.circular(6)), child: Icon(icon, size: 14, color: _accent)), const SizedBox(width: 10), Text('$label :', style: TextStyle(fontSize: 12, color: _textMute)), const Spacer(), Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _text))]);
  }

  // ===========================================================================
  // FORMULAIRE PRODUIT
  // ===========================================================================
  void _afficherFormulaire({Map<String, dynamic>? produit}) {
    final isEdit = produit != null;
    
    // Initialisation des contrôleurs (inchangée)
    if (isEdit) {
      nomController.text = produit['nom']?.toString() ?? '';
      descriptionController.text = produit['description']?.toString() ?? '';
      selectedTypeVente = produit['type_vente']?.toString() ?? 'unite';
      prixAchatTotalController.text = produit['prix_achat_total']?.toString() ?? '';
      prixVenteUnitaireController.text = produit['prix_vente_unitaire']?.toString() ?? '';
      final double quantiteParUnite = double.tryParse(produit['quantite_par_unite']?.toString() ?? '1') ?? 1;
      quantiteAchatController.text = quantiteParUnite.toStringAsFixed(0);
      final double stockBrut = double.tryParse(produit['stock']?.toString() ?? '0') ?? 0;
      final double stockConverti = quantiteParUnite > 1 ? stockBrut / quantiteParUnite : stockBrut;
      stockActuelController.text = stockConverti.toStringAsFixed(1).replaceAll('.0', '');
      selectedUniteAchat = produit['unite_achat']?.toString() ?? getUnitesAchat(selectedTypeVente).first;
      selectedUniteVente = produit['unite_vente']?.toString() ?? getUniteVenteDefaut(selectedTypeVente);
      selectedCategorieId = produit['category_id']?.toString();
      fournisseurController.text = produit['fournisseur']?.toString() ?? '';
      telephoneFournisseurController.text = produit['telephone_fournisseur']?.toString() ?? '';
    } else {
      viderChamps();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        maxChildSize: 0.96,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          constraints: const BoxConstraints(maxWidth: 540),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: const Border(top: BorderSide(color: _border)),
          ),
          child: Consumer<ProductsViewModel>(
            builder: (context, viewModel, child) {
              return StatefulBuilder(
                builder: (ctx, setModalState) {
                  // 🔥 FONCTION POUR RECALCULER LE BÉNÉFICE
                  void refreshBenefice() {
                    setModalState(() {});  // Rafraîchit uniquement le modal
                  }

                  return Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        decoration: BoxDecoration(
                          color: _surfaceHi,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          border: const Border(bottom: BorderSide(color: _border)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(isEdit ? Icons.edit_note : Icons.add_box, color: _accent, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isEdit ? 'Modifier le produit' : 'Nouveau produit',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _text),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: Icon(Icons.close_rounded, color: _textMute, size: 20),
                            ),
                          ],
                        ),
                      ),
                      // Corps du formulaire
                      Expanded(
                        child: SingleChildScrollView(
                          controller: controller,
                          padding: EdgeInsets.only(
                            left: 20, right: 20, top: 20,
                            bottom: MediaQuery.of(ctx).viewInsets.bottom + 80,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section 1: Informations générales
                              _buildSectionTitle('Informations générales'),
                              const SizedBox(height: 12),
                              _buildField(
                                controller: nomController,
                                label: 'Nom du produit',
                                hint: 'Ex: Riz brisé',
                                icon: Icons.label_outline,
                                onChanged: (_) => refreshBenefice(),
                              ),
                              const SizedBox(height: 14),
                              _buildDropdown(
                                value: selectedCategorieId,
                                label: 'Catégorie',
                                hint: 'Sélectionnez',
                                icon: Icons.grid_view,
                                items: viewModel.categories.map((c) => DropdownMenuItem(
                                  value: c.id?.toString(),
                                  child: Text(c.nom, style: const TextStyle(fontSize: 13)),
                                )).toList(),
                                onChanged: (v) => setModalState(() => selectedCategorieId = v),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Section 2: Type de vente
                              _buildSectionTitle('Type de vente'),
                              const SizedBox(height: 12),
                              _buildTypeVenteSelector(setModalState),
                              
                              const SizedBox(height: 14),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDropdown(
                                      value: selectedUniteAchat,
                                      label: 'Unité d\'achat',
                                      hint: 'Ex: Carton',
                                      icon: Icons.shopping_bag,
                                      items: getUnitesAchat(selectedTypeVente).map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                                      onChanged: (v) => setModalState(() => selectedUniteAchat = v ?? 'colis'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildDropdown(
                                      value: selectedUniteVente,
                                      label: 'Unité de vente',
                                      hint: 'Ex: Pièce',
                                      icon: Icons.sell,
                                      items: getUnitesVente(selectedTypeVente).map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                                      onChanged: (v) => setModalState(() => selectedUniteVente = v ?? 'pièce'),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Section 3: Achat & Stock (avec recalcul)
                              _buildSectionTitle('Achat & Stock'),
                              const SizedBox(height: 12),
                              
                              Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: _buildField(
                                      controller: quantiteAchatController,
                                      label: 'Contenu par lot',
                                      hint: 'Ex: 24',
                                      icon: Icons.inventory_2,
                                      keyboardType: TextInputType.number,
                                      suffix: '$selectedUniteVente / $selectedUniteAchat',
                                      onChanged: (_) => refreshBenefice(), // 🔥 Recalcule le bénéfice
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 4,
                                    child: _buildField(
                                      controller: prixAchatTotalController,
                                      label: 'Prix d\'achat',
                                      hint: 'Coût total',
                                      icon: Icons.price_change,
                                      keyboardType: TextInputType.number,
                                      suffix: devise ?? 'FCFA',
                                      onChanged: (_) => refreshBenefice(), // 🔥 Recalcule le bénéfice
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 14),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildField(
                                      controller: prixVenteUnitaireController,
                                      label: 'Prix de vente',
                                      hint: 'Prix unitaire',
                                      icon: Icons.monetization_on,
                                      keyboardType: TextInputType.number,
                                      suffix: devise ?? 'FCFA',
                                      onChanged: (_) => refreshBenefice(), // 🔥 Recalcule le bénéfice
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildField(
                                      controller: stockActuelController,
                                      label: 'Stock',
                                      hint: 'Quantité',
                                      icon: Icons.tag,
                                      keyboardType: TextInputType.number,
                                      suffix: selectedUniteAchat,
                                      onChanged: (_) => refreshBenefice(), // 🔥 Recalcule le bénéfice
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // 🔥 CALCULATEUR DE BÉNÉFICE (se met à jour en temps réel)
                              _buildCalculateurIntelligent(refreshBenefice),
                              
                              const SizedBox(height: 24),
                              
                              // Section 4: Fournisseur
                              _buildSectionTitle('Fournisseur'),
                              const SizedBox(height: 12),
                              _buildField(
                                controller: fournisseurController,
                                label: 'Nom du fournisseur',
                                hint: 'Nom du grossiste',
                                icon: Icons.local_shipping,
                                onChanged: (_) => refreshBenefice(),
                              ),
                              const SizedBox(height: 14),
                              _buildField(
                                controller: telephoneFournisseurController,
                                label: 'Téléphone',
                                hint: 'Contact',
                                icon: Icons.phone,
                                keyboardType: TextInputType.phone,
                                onChanged: (_) => refreshBenefice(),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Bouton d'enregistrement
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (nomController.text.trim().isEmpty) {
                                      _showErrorSnackBar('Nom requis');
                                      return;
                                    }
                                    Navigator.pop(ctx);
                                    isEdit
                                        ? modifierProduit(produit['id'].toString())
                                        : ajouterProduit();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _accent,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: Text(
                                    isEdit ? 'Enregistrer' : 'Ajouter au catalogue',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(children: [Container(width: 4, height: 18, decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 10), Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textMute))]);
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? suffix,
    ValueChanged<String>? onChanged,  // ← Ajouter ce paramètre
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textDim)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _text),
          onChanged: onChanged,  // ← Connecter le callback
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 12, color: _textDim),
            filled: true,
            fillColor: _surfaceHi,
            prefixIcon: Icon(icon, size: 16, color: _accent),
            suffixText: suffix,
            suffixStyle: const TextStyle(fontSize: 11, color: _textMute),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _accent)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({required String? value, required String label, required String hint, required IconData icon, required List<DropdownMenuItem<String>> items, required ValueChanged<String?> onChanged}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textDim)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: _surfaceHi, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down, color: _textMute),
            hint: Row(children: [Icon(icon, size: 16, color: _accent), const SizedBox(width: 8), Expanded(child: Text(hint, style: TextStyle(color: _textDim, fontSize: 12)))]),
            items: items,
            onChanged: onChanged,
            dropdownColor: _surfaceHi,
            style: const TextStyle(color: _text, fontSize: 13),
          ),
        ),
      ),
    ]);
  }

  Widget _buildTypeVenteSelector(void Function(void Function()) setModal) {
    return Row(
      children: [
        _buildTypeOption('unite', 'Unité', Icons.apps_rounded, setModal),
        const SizedBox(width: 6),
        _buildTypeOption('colis', 'Colis', Icons.inventory_2_outlined, setModal),
        const SizedBox(width: 6),
        _buildTypeOption('poids', 'Poids', Icons.scale_outlined, setModal),
        const SizedBox(width: 6),
        _buildTypeOption('volume', 'Volume', Icons.water_drop_outlined, setModal),
      ],
    );
  }

  Widget _buildTypeOption(String value, String label, IconData icon, void Function(void Function()) setModal) {
    final isSelected = selectedTypeVente == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setModal(() {
            selectedTypeVente = value;
            selectedUniteAchat = getUnitesAchat(value).first;
            selectedUniteVente = getUniteVenteDefaut(value);
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? _accent : _surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? _accent : _border),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 14, color: isSelected ? Colors.white : _textMute), const SizedBox(width: 6), Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : _textMute))]),
        ),
      ),
    );
  }

  Widget _buildCalculateurIntelligent(VoidCallback refreshBenefice) {
    // Calculs en temps réel à partir des contrôleurs
    final qteAchat = double.tryParse(quantiteAchatController.text.trim()) ?? 0;
    final prixAchat = double.tryParse(prixAchatTotalController.text.trim()) ?? 0;
    final prixVente = double.tryParse(prixVenteUnitaireController.text.trim()) ?? 0;
    
    final coutUnitaire = qteAchat > 0 && prixAchat > 0 ? prixAchat / qteAchat : 0;
    final marge = prixVente - coutUnitaire;
    final margePourcent = coutUnitaire > 0 ? (marge / coutUnitaire) * 100 : 0;
    final profitable = marge >= 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (profitable ? _success : _danger).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (profitable ? _success : _danger).withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(profitable ? Icons.trending_up : Icons.trending_down, color: profitable ? _success : _danger, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  profitable ? '✅ Produit profitable' : '⚠️ Marge négative',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: profitable ? _success : _danger),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (profitable ? _success : _danger).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${margePourcent.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: profitable ? _success : _danger),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoChip('Coût unitaire', '${coutUnitaire.toStringAsFixed(0)} $devise', _textMute),
              _buildInfoChip('Prix vente', '${prixVente.toStringAsFixed(0)} $devise', _textMute),
              _buildInfoChip('Marge', '${marge.toStringAsFixed(0)} $devise', profitable ? _success : _danger),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: coutUnitaire > 0 ? (prixVente / (coutUnitaire * 2)).clamp(0.0, 1.0) : 0.5,
              backgroundColor: Colors.grey.withOpacity(0.2),
              color: profitable ? _success : _danger,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          if (coutUnitaire == 0 && prixAchat > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '⚠️ Le contenu par lot ne peut pas être 0',
                style: TextStyle(fontSize: 9, color: _warning),
              ),
            ),
          if (prixAchat == 0 && qteAchat > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '⚠️ Renseignez le prix d\'achat pour calculer la marge',
                style: TextStyle(fontSize: 9, color: _warning),
              ),
            ),
          if (prixVente == 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '⚠️ Renseignez le prix de vente',
                style: TextStyle(fontSize: 9, color: _warning),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 9, color: _textDim)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, right: 16),
      child: FloatingActionButton(
        onPressed: () => _afficherFormulaire(),
        backgroundColor: _accent,  // Violet visible
        elevation: 4,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  // ===========================================================================
// LISTE PRODUITS MOBILE AVEC BOUTONS
// ===========================================================================
  Widget _buildProductsListMobile() {
    return Consumer<ProductsViewModel>(
      builder: (context, vm, _) {
        if (vm.products.isEmpty) return _buildEmptyState();

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: vm.products.length,
          itemBuilder: (_, index) {
            final p = vm.products[index];
            final prixVente = p.prixVenteUnitaire;
            final String cat = p.categoryNom ?? 'Non classé';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  // Contenu principal (cliquable pour détails)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_getIcon(cat), color: _accentSoft, size: 22),
                    ),
                    title: Text(
                      p.nom,
                      style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      cat,
                      style: TextStyle(color: _textMute, fontSize: 11),
                    ),
                    trailing: Text(
                      '${prixVente.toStringAsFixed(0)} ${devise ?? 'FCFA'}',
                      style: const TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onTap: () => _afficherDetails(p),
                  ),
                  // BOUTONS MODIFIER / SUPPRIMER (VISIBLES SUR MOBILE)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _surfaceHi,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildActionButton(
                          icon: Icons.edit_outlined,
                          label: 'Modifier',
                          color: _accent,
                          onTap: () => _afficherFormulaire(produit: p.toJson()),
                        ),
                        const SizedBox(width: 12),
                        _buildActionButton(
                          icon: Icons.delete_outline,
                          label: 'Supprimer',
                          color: _danger,
                          onTap: () => _confirmerSuppression(p.id ?? ''),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper pour les boutons d'action
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProductsListDesktop() {
  return Consumer<ProductsViewModel>(
    builder: (context, viewModel, child) {
      if (viewModel.products.isEmpty) return _buildEmptyState();

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: viewModel.products.length,
        itemBuilder: (context, index) => _buildProductCard(viewModel.products[index]),
      );
    },
  );
}
 
  @override
  void dispose() {
    nomController.dispose();
    descriptionController.dispose();
    quantiteAchatController.dispose();
    prixAchatTotalController.dispose();
    prixVenteUnitaireController.dispose();
    stockActuelController.dispose();
    fournisseurController.dispose();
    telephoneFournisseurController.dispose();
    rechercheController.dispose();
    nomCategorieController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}
