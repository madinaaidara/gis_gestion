import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/produit_model.dart';
import '../../core/utils/packaging_utils.dart';

/// ============================================
/// PRODUCTS REPOSITORY - GIS Gestion
/// ============================================
/// Classe d'abstraction pour isoler les requêtes Supabase de la vue.
/// Centralise les opérations CRUD de la table 'produits' (version française).
/// ============================================

class ProductsRepository extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // CORRECTION SYNCHRONISATION : Nom unifié en français pour matcher le getter
  List<ProduitModel> _products = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters unifiés exposant les données de manière sécurisée (Read-Only)
  List<ProduitModel> get products => _products;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  /// Compteurs du catalogue complet (sans filtre recherche/catégorie).
  Future<Map<String, int>> fetchCatalogStats({required String shopId}) async {
    try {
      final response = await _supabase
          .from('produits')
          .select(
            'nom, stock, quantite_par_unite, unite_achat, unite_vente, '
            'unite_intermediaire, quantite_base_par_intermediaire, quantite_intermediaire_par_lot',
          )
          .eq('shop_id', shopId);

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);
      int rupture = 0;
      int faible = 0;
      for (final row in data) {
        final p = ProduitModel.fromJson(row);
        switch (PackagingUtils.stockLevel(p)) {
          case StockLevel.rupture:
            rupture++;
          case StockLevel.faible:
            faible++;
          case StockLevel.ok:
            break;
        }
      }
      final total = data.length;
      return {
        'total': total,
        'enStock': total - rupture,
        'rupture': rupture,
        'faible': faible,
      };
    } catch (e) {
      debugPrint('🚨 Erreur fetchCatalogStats : $e');
      return {'total': 0, 'enStock': 0, 'rupture': 0, 'faible': 0};
    }
  }

  /// ============================================
  /// RECUPÉRER TOUS LES PRODUITS DU MAGASIN
  /// ============================================
    Future<List<ProduitModel>> fetchProducts({String? shopId, String? categoryId, String? searchPattern}) async {
    _setLoading(true);
    _clearError();

    try {
      // ✅ JOINTURE RÉACTIVÉE : Demande à Supabase d'inclure le nom de la table categories
      var query = _supabase.from('produits').select('*, categories(nom)');

      if (shopId != null && shopId.isNotEmpty) query = query.eq('shop_id', shopId);
      if (categoryId != null && categoryId.isNotEmpty) query = query.eq('category_id', categoryId);
      if (searchPattern != null && searchPattern.trim().isNotEmpty) {
        query = query.or(
          'nom.ilike.%${searchPattern.trim()}%,'
          'description.ilike.%${searchPattern.trim()}%,'
          'barcode.ilike.%${searchPattern.trim()}%',
        );
      }

      final response = await query.order('nom', ascending: true);
      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);
      
      _products = data.map((json) => ProduitModel.fromJson(json)).toList();
      _setLoading(false);
      return _products;
    } catch (e) {
      _setError('Échec de la lecture du catalogue : $e');
      _setLoading(false);
      return [];
    }
  }

  /// ============================================
  /// AJOUTER UN NOUVEAU PRODUIT EN RAYON
  /// ============================================
  Future<bool> addProduct(ProduitModel newProduct) async {
    _setLoading(true);
    _clearError();

    try {
      await _supabase.from('produits').insert(newProduct.toJson());
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Impossible d\'ajouter le produit en base de données : $e');
      _setLoading(false);
      return false;
    }
  }

  /// ============================================
  /// METTRE À JOUR LES INFORMATIONS D'UN PRODUIT
  /// ============================================
  Future<bool> updateProduct(String productId, Map<String, dynamic> updatedFields) async {
    _setLoading(true);
    _clearError();

    try {
      await _supabase
          .from('produits')
          .update(updatedFields)
          .eq('id', productId);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Échec de la mise à jour de la fiche article : $e');
      _setLoading(false);
      return false;
    }
  }

  /// ============================================
  /// AJUSTER LE STOCK DE MANIÈRE RAPIDE (APRÈS VENTE COMTPOIR)
  /// ============================================
  Future<bool> updateStock(String productId, double newStockValue) async {
    try {
      await _supabase
          .from('produits')
          .update({'stock': newStockValue, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', productId);

      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(stock: newStockValue);
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('❌ Erreur critique mise à jour stock table produits : $e');
      return false;
    }
  }

  /// ============================================
  /// SUPPRIMER UN PRODUIT DU CATALOGUE
  /// ============================================
  Future<bool> deleteProduct(String productId) async {
    _setLoading(true);
    _clearError();

    try {
      await _supabase.from('produits').delete().eq('id', productId);
      
      // Nettoyage instantané de la liste locale pour éviter une requête réseau inutile
      _products.removeWhere((p) => p.id == productId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Impossible de supprimer définitivement l\'article : $e');
      _setLoading(false);
      return false;
    }
  }
  
  /// Augmenter le stock (quand on annule une vente)
  Future<bool> increaseStock(String productId, double quantity) async {
    try {
      // 1. Récupérer le produit actuel
      final response = await _supabase
          .from('produits')
          .select('stock')
          .eq('id', productId)
          .single();
      
      final currentStock = (response['stock'] ?? 0).toDouble();
      final newStock = currentStock + quantity;
      
      // 2. Mettre à jour le stock
      await _supabase
          .from('produits')
          .update({'stock': newStock, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', productId);
      
      // 3. Mettre à jour la liste locale
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(stock: newStock);
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Erreur increaseStock: $e');
      return false;
    }
  }

  /// ============================================
  /// HELPERS DE GESTION D'ÉTAT (NOTIFICATIONS MULTI-VUES)
  /// ============================================
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners(); // Alerte automatiquement le ProductsViewModel ou l'écran connecté
  }

  void _setError(String message) {
    _errorMessage = message;
    debugPrint('🚨 ProductsRepository : $message');
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
  }
}
