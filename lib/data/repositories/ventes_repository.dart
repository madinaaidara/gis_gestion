import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vente_model.dart';
import '../../core/utils/lignes_panier_utils.dart';
import 'products_repository.dart';

class AnnulationVenteResult {
  final bool success;
  final String? message;
  final bool stockRestored;

  const AnnulationVenteResult({
    required this.success,
    this.message,
    this.stockRestored = false,
  });
}

class VentesRepository extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<VenteModel> _sales = [];
  bool _isLoading = false;

  List<VenteModel> get sales => _sales;
  bool get isLoading => _isLoading;

  Future<void> fetchSales(String shopId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase
          .from('ventes')
          .select('*')
          .eq('shop_id', shopId)
          .order('date_vente', ascending: false);

      _sales = (response as List).map((json) => VenteModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Erreur fetchSales: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createSale(VenteModel sale) async {
    try {
      await _supabase.from('ventes').insert(sale.toJson());
      _sales.insert(0, sale);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur createSale: $e');
      return false;
    }
  }

  /// Restaure le stock à partir d'une vente (lignes_panier JSON ou repli nom_produit).
  Future<bool> restaurerStockDepuisVente(
    Map<String, dynamic> vente, {
    required ProductsRepository productsRepository,
    String? shopId,
  }) async {
    final effectiveShopId = shopId ?? vente['shop_id']?.toString();
    if (effectiveShopId != null && effectiveShopId.isNotEmpty) {
      await productsRepository.fetchProducts(shopId: effectiveShopId);
    }

    var lignes = LignesPanierUtils.parse(vente['lignes_panier']);

    if (lignes.isEmpty) {
      lignes = LignesPanierUtils.parseFromNomProduit(
        vente['nom_produit']?.toString() ?? '',
        productsRepository.products,
        typeVente: vente['type_vente']?.toString(),
      );
      if (lignes.isNotEmpty) {
        debugPrint('ℹ️ Restore stock via nom_produit (repli, ${lignes.length} ligne(s))');
      }
    }

    if (lignes.isEmpty) {
      debugPrint('⚠️ restaurerStock: impossible — lignes_panier vide et nom_produit non reconnu');
      return false;
    }

    var restored = 0;
    for (final ligne in lignes) {
      final produitId = ligne['produit_id']!.toString();
      final volume = LignesPanierUtils.volumeLigne(ligne);
      final ok = await productsRepository.increaseStock(produitId, volume);
      if (ok) restored++;
      else debugPrint('❌ increaseStock échoué pour $produitId (+$volume)');
    }

    debugPrint('✓ Stock restauré pour $restored/${lignes.length} produit(s)');
    return restored > 0;
  }

  Future<AnnulationVenteResult> annulerVente(
    String venteId, {
    required ProductsRepository productsRepository,
    String? shopId,
  }) async {
    try {
      final vente = await _supabase.from('ventes').select('*').eq('id', venteId).maybeSingle();
      if (vente == null) {
        return const AnnulationVenteResult(success: false, message: 'Vente introuvable');
      }

      final status = vente['status']?.toString() ?? '';
      if (status == 'annulee') {
        return const AnnulationVenteResult(success: false, message: 'Cette vente est déjà annulée');
      }

      final estCredit = vente['est_credit'] == true ||
          vente['methode_paiement']?.toString() == 'Crédit' ||
          status == 'en_cours';
      if (estCredit) {
        return const AnnulationVenteResult(
          success: false,
          message: 'Les ventes à crédit s\'annulent depuis la page Crédits.',
        );
      }

      final effectiveShopId = shopId ?? vente['shop_id']?.toString();

      final stockRestored = await restaurerStockDepuisVente(
        vente,
        productsRepository: productsRepository,
        shopId: effectiveShopId,
      );

      await _supabase.from('ventes').update({'status': 'annulee'}).eq('id', venteId);

      try {
        await _supabase.from('credits').update({'statut': 'annule'}).eq('vente_id', venteId);
      } catch (_) {}

      notifyListeners();
      return AnnulationVenteResult(
        success: true,
        stockRestored: stockRestored,
        message: stockRestored
            ? 'Vente annulée et stock restauré'
            : 'Vente annulée mais stock non restauré (produit introuvable)',
      );
    } catch (e) {
      debugPrint('Erreur annulerVente: $e');
      return AnnulationVenteResult(success: false, message: 'Erreur lors de l\'annulation');
    }
  }
}
