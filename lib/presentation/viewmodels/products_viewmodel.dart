import 'package:flutter/material.dart';
import '../../data/models/produit_model.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/products_repository.dart';
import '../../data/repositories/categories_repository.dart';

/// ============================================
/// PRODUCTS VIEWMODEL - GIS Gestion
/// ============================================
/// Chef d'orchestre de l'écran Produits.
/// Gère les états de chargement, la recherche en direct et le filtrage par onglet.
/// ============================================

class ProductsViewModel extends ChangeNotifier {
  final ProductsRepository _productsRepository;
  final CategoriesRepository _categoriesRepository;
   String? _currentShopId;

  ProductsViewModel(this._productsRepository, this._categoriesRepository);

  // Exposition des états de chargement combinés de la logistique
  bool get isLoading => _productsRepository.isLoading || _categoriesRepository.isLoading;
  List<ProduitModel> get products => _productsRepository.products;
  List<CategoryModel> get categories => _categoriesRepository.categories;

  String? _selectedCategoryId;
  String _searchQuery = '';

  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;

  /// ============================================
  /// INITIALISATION DU CATALOGUE (PRODUITS + CATÉGORIES)
  /// ============================================
  Future<void> initializeCatalog(String shopId) async {
    _currentShopId = shopId; // Enregistre le shopId actif en mémoire
    // 1. Charge d'abord les filtres de catégories (et injecte les défauts si besoin)
    await _categoriesRepository.fetchCategories(shopId);
    // 2. Charge les lignes de produits correspondantes
    await refreshProducts();
  }

  /// ============================================
  /// RECHARGEMENT DYNAMIQUE DU STOCK
  /// ============================================
  Future<void> refreshProducts() async {
    await _productsRepository.fetchProducts(
      shopId: _currentShopId,
      categoryId: _selectedCategoryId,
      searchPattern: _searchQuery,
    );
  }

  /// ============================================
  /// GESTION DES FILTRES DE L'INTERFACE
  /// ============================================
  
  // Action au clic sur un onglet de catégorie
  void selectCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners(); // Dit à l'écran de se redessiner
    refreshProducts(); // Déclenche la requête filtrée vers le dépôt
  }

  // Action à la saisie de texte dans la loupe de recherche
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
    refreshProducts();
  }
}
