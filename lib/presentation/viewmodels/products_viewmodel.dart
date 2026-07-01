import 'dart:async';

import 'package:flutter/material.dart';
import '../../data/models/produit_model.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/products_repository.dart';
import '../../data/repositories/categories_repository.dart';

/// Chef d'orchestre de l'écran Produits.
/// Gère le chargement, la recherche (debounce) et le filtrage par catégorie.
class ProductsViewModel extends ChangeNotifier {
  final ProductsRepository _productsRepository;
  final CategoriesRepository _categoriesRepository;
  String? _currentShopId;

  ProductsViewModel(this._productsRepository, this._categoriesRepository) {
    _productsRepository.addListener(_onRepositoryUpdate);
  }

  void _onRepositoryUpdate() {
    _notifyIfActive();
  }

  bool _disposed = false;

  bool get isLoading => _productsRepository.isLoading || _categoriesRepository.isLoading;
  List<ProduitModel> get products => _productsRepository.products;
  List<CategoryModel> get categories => _categoriesRepository.categories;

  String? _selectedCategoryId;
  String _searchQuery = '';
  bool _stockFaibleFilterOnly = false;
  Timer? _searchDebounce;

  int _totalCatalog = 0;
  int _enStockCatalog = 0;
  int _ruptureCatalog = 0;
  int _faibleCatalog = 0;

  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  bool get stockFaibleFilterOnly => _stockFaibleFilterOnly;
  int get totalCatalog => _totalCatalog;
  int get enStockCatalog => _enStockCatalog;
  int get ruptureCatalog => _ruptureCatalog;
  int get faibleCatalog => _faibleCatalog;
  bool get hasActiveFilter =>
      _selectedCategoryId != null ||
      _searchQuery.trim().isNotEmpty ||
      _stockFaibleFilterOnly;

  void _notifyIfActive() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initializeCatalog(String shopId) async {
    _currentShopId = shopId;
    await _categoriesRepository.fetchCategories(shopId);
    if (_disposed) return;
    await refreshCatalogStats();
    if (_disposed) return;
    await refreshProducts();
  }

  Future<void> refreshCatalogStats() async {
    if (_currentShopId == null || _disposed) return;
    final stats = await _productsRepository.fetchCatalogStats(shopId: _currentShopId!);
    if (_disposed) return;
    _totalCatalog = stats['total'] ?? 0;
    _enStockCatalog = stats['enStock'] ?? 0;
    _ruptureCatalog = stats['rupture'] ?? 0;
    _faibleCatalog = stats['faible'] ?? 0;
    _notifyIfActive();
  }

  Future<void> refreshProducts() async {
    if (_disposed) return;
    await _productsRepository.fetchProducts(
      shopId: _currentShopId,
      categoryId: _selectedCategoryId,
      searchPattern: _searchQuery,
    );
    if (_disposed) return;
    await refreshCatalogStats();
  }

  /// Recharge le catalogue après changement stock (annulation, etc.).
  Future<void> reloadForShop(String shopId) async {
    _currentShopId = shopId;
    await refreshProducts();
  }

  void toggleStockFaibleFilter() {
    _stockFaibleFilterOnly = !_stockFaibleFilterOnly;
    _notifyIfActive();
  }

  void selectCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    _notifyIfActive();
    refreshProducts();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    _notifyIfActive();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!_disposed) refreshProducts();
    });
  }

  @override
  void dispose() {
    _productsRepository.removeListener(_onRepositoryUpdate);
    _disposed = true;
    _searchDebounce?.cancel();
    super.dispose();
  }
}
