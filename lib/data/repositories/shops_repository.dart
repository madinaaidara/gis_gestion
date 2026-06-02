import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shop_model.dart';

/// ============================================
/// SHOPS REPOSITORY - GIS Gestion
/// ============================================
/// Centralise les requêtes de la table 'shops'.
/// Gère la création de l'établissement et la détection d'existence.
/// ============================================

class ShopsRepository extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  ShopModel? _currentShop;
  bool _isLoading = false;
  String _errorMessage = '';

  ShopModel? get currentShop => _currentShop;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  /// ============================================
  /// VÉRIFIER ET CHARGER LA BOUTIQUE DU GÉRANT
  /// ============================================
  Future<bool> checkAndLoadShop(String userId) async {
    _setLoading(true);
    _clearError();
    try {
      final response = await _supabase
          .from('shops')
          .select('*')
          .eq('owner_id', userId)
          .maybeSingle();

      if (response != null) {
        _currentShop = ShopModel.fromJson(response);
        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false; // L'utilisateur est connecté mais n'a pas créé de boutique
    } catch (e) {
      _setError('Échec de la vérification de la boutique : $e');
      _setLoading(false);
      return false;
    }
  }

  /// ============================================
  /// ENREGISTRER UNE NOUVELLE BOUTIQUE (SETUP)
  /// ============================================
  Future<bool> registerNewShop(ShopModel shop) async {
    _setLoading(true);
    _clearError();
    try {
      await _supabase.from('shops').insert(shop.toJson());
      _currentShop = shop;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Impossible de configurer l\'établissement : $e');
      _setLoading(false);
      return false;
    }
  }

  /// ============================================
  /// HELPERS D'ÉTAT INTERNES
  /// ============================================
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    debugPrint('🚨 ShopsRepository : $message');
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
  }
}
