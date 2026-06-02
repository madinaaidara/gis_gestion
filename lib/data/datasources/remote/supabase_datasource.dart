import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../models/produit_model.dart';
import '../../models/shop_model.dart';
import '../../models/vente_model.dart';
import '../../models/credit_model.dart';

class SupabaseDataSource {
  final _client = SupabaseService.instance;

  // ============================================
  // AUTHENTIFICATION
  // ============================================

  Future<AuthResponse> signIn(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password, String? fullName) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName ?? email.split('@').first},
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ============================================
  // BOUTIQUES
  // ============================================

  Future<List<ShopModel>> getShops() async {
    final response = await _client
        .from(SupabaseConstants.tableShops)
          .select()
          .eq('owner_id', SupabaseService.userId ?? '');
    return (response as List).map((e) => ShopModel.fromJson(e)).toList();
  }

  Future<void> createShop(Map<String, dynamic> shop) async {
    await _client.from(SupabaseConstants.tableShops).insert({
      ...shop,
      'owner_id': SupabaseService.userId,
    });
  }

  // ============================================
  // PRODUITS
  // ============================================

  Future<List<ProduitModel>> getProducts(String shopId) async {
    final response = await _client
        .from(SupabaseConstants.tableProduits)
        .select()
        .eq('shop_id', shopId)
        .order('nom');
    return (response as List).map((e) => ProduitModel.fromJson(e)).toList();
  }

  Future<void> addProduct(Map<String, dynamic> product) async {
    await _client.from(SupabaseConstants.tableProduits).insert(product);
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _client.from(SupabaseConstants.tableProduits)
        .update(data)
        .eq('id', id);
  }

  Future<void> deleteProduct(String id) async {
    await _client.from(SupabaseConstants.tableProduits).delete().eq('id', id);
  }

  // ============================================
  // VENTES
  // ============================================

  Future<List<VenteModel>> getSales(String shopId) async {
    final response = await _client
        .from(SupabaseConstants.tableVentes)
        .select()
        .eq('shop_id', shopId)
        .order('date_vente', ascending: false);
    return (response as List).map((e) => VenteModel.fromJson(e)).toList();
  }

  Future<void> addSale(Map<String, dynamic> sale) async {
    await _client.from(SupabaseConstants.tableVentes).insert(sale);
  }

  // ============================================
  // CRÉDITS
  // ============================================

  Future<List<CreditModel>> getCredits(String shopId) async {
    final response = await _client
        .from(SupabaseConstants.tableCredits)
        .select()
        .eq('shop_id', shopId)
        .order('date_credit', ascending: false);
    return (response as List).map((e) => CreditModel.fromJson(e)).toList();
  }

  Future<void> addCredit(Map<String, dynamic> credit) async {
    await _client.from(SupabaseConstants.tableCredits).insert(credit);
  }

  Future<void> addPaiementCredit(Map<String, dynamic> paiement) async {
    await _client.from(SupabaseConstants.tablePaiementsCredit).insert(paiement);
  }
}