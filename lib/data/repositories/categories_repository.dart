import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';

/// ============================================
/// CATEGORIES REPOSITORY - GIS Gestion
/// ============================================
/// Gère les opérations CRUD de la table 'categories' sur Supabase.
/// Intègre l'injection automatique des catégories par défaut si la base est vide.
/// ============================================

class CategoriesRepository extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<CategoryModel> _categories = [];
  bool _isLoading = false;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;

  /// ============================================
  /// CHARGER LES CATÉGORIES (AVEC SÉCURITÉ INJECTION)
  /// ============================================
  Future<void> fetchCategories(String shopId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('categories')
          .select('*')
          .eq('shop_id', shopId)
          .order('nom');

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);

      // Si la boutique n'a aucune catégorie, on injecte le pack de démarrage automatique
      if (data.isEmpty) {
        await _createDefaultCategories(shopId);
        return;
      }

      _categories = data.map((json) => CategoryModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('🚨 Erreur fetchCategories: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// ============================================
  /// CRÉATION DU PACK DE DÉMARRAGE AUTOMATIQUE
  /// ============================================
  Future<void> _createDefaultCategories(String shopId) async {
    final defaults = [
      {'nom': 'Alimentation', 'description': 'Produits alimentaires et épicerie'},
      {'nom': 'Boissons', 'description': 'Boissons et rafraîchissements'},
      {'nom': 'Hygiène & Beauté', 'description': 'Produits d\'hygiène personnelle'},
      {'nom': 'Maison & Entretien', 'description': 'Produits d\'entretien maison'},
      {'nom': 'Cosmétiques', 'description': 'Produits beauté et cosmétiques'},
    ];

    try {
      // Insertion groupée performante en une seule requête SQL
      final List<Map<String, dynamic>> insertPayload = defaults.map((cat) => {
        'shop_id': shopId,
        'nom': cat['nom'],
        'description': cat['description'],
      }).toList();

      await _supabase.from('categories').insert(insertPayload);
      
      // Rechargement immédiat après insertion pour alimenter la liste locale
      final response = await _supabase
          .from('categories')
          .select('*')
          .eq('shop_id', shopId)
          .order('nom');

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);
      _categories = data.map((json) => CategoryModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('🚨 Erreur lors de la création des catégories par défaut: $e');
    }
  }

  /// ============================================
  /// AJOUTER UNE CATÉGORIE MANUELLEMENT
  /// ============================================
  Future<bool> addCategory(CategoryModel category) async {
    try {
      await _supabase.from('categories').insert(category.toJson());
      _categories.add(category);
      _categories.sort((a, b) => a.nom.compareTo(b.nom)); // Garde le tri alphabétique local
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('🚨 Erreur addCategory: $e');
      return false;
    }
  }
}
