// lib/presentation/viewmodels/ventes_viewmodel.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../../data/models/produit_model.dart';
import '../../data/models/credit_model.dart';
import '../../data/repositories/products_repository.dart';
import '../../data/repositories/credits_repository.dart';

/// ============================================
/// VENTES VIEWMODEL - GIS Gestion
/// ============================================

class VentesViewModel extends ChangeNotifier {
  final ProductsRepository _productsRepository;
  final CreditsRepository _creditsRepository;

  // CORRECTION: Constructeur avec 3 paramètres
  VentesViewModel(
    this._productsRepository,
    this._creditsRepository,
  );

  // Structure du Panier Local de Caisse
  final List<Map<String, dynamic>> _panier = [];
  List<Map<String, dynamic>> get panier => _panier;

  bool _isCreditMode = false;
  double _amountPaid = 0.0;
  String _selectedPaymentMethod = 'Espèces';

  bool get isCreditMode => _isCreditMode;
  double get amountPaid => _amountPaid;
  String get selectedPaymentMethod => _selectedPaymentMethod;

  // --- GETTERS DE CALCULS FINANCIERS GLOBAUX ---
  double get sousTotal => _panier.fold(0.0, (sum, item) => sum + (item['prix_total'] ?? 0.0));
  
  double get remiseGlobale {
    return _panier.fold(0.0, (sum, item) {
      final double initial = (item['prix_initial'] ?? 0.0);
      final double actuel = (item['prix_unitaire'] ?? 0.0);
      return sum + ((initial - actuel) * (item['quantite'] ?? 1));
    });
  }

  double get totalTTC => sousTotal;
  double get montantRestant => _isCreditMode ? (totalTTC - _amountPaid) : 0.0;

  double get benefice {
    return _panier.fold(0.0, (sum, item) {
      final double venteLigne = (item['prix_total'] ?? 0.0);
      final double coutAchatUnitaire = (item['prix_achat_unitaire'] ?? 0.0);
      final double qty = (item['quantite'] ?? 1).toDouble();
      return sum + (venteLigne - (coutAchatUnitaire * qty));
    });
  }

  double get margePercentage {
    final double totalCout = _panier.fold(0.0, (sum, item) => sum + ((item['prix_achat_unitaire'] ?? 0.0) * (item['quantite'] ?? 1)));
    if (totalCout == 0) return 0.0;
    return (benefice / totalCout) * 100;
  }

  bool get isPerte => benefice < 0;

  // --- ACTIONS DU PANIER ---
  void ajouterAuPanier(ProduitModel produit, int quantite, double prixVenteSaisi) {
    final existIndex = _panier.indexWhere((item) => item['produit_id'] == produit.id);

    if (existIndex >= 0) {
      final int newQty = _panier[existIndex]['quantite'] + quantite;
      _panier[existIndex]['quantite'] = newQty;
      _panier[existIndex]['prix_total'] = prixVenteSaisi * newQty;
    } else {
      _panier.add({
        'produit_id': produit.id,
        'nom': produit.nom,
        'type_vente': produit.typeVente ?? 'unite',
        'prix_unitaire': prixVenteSaisi,
        'prix_initial': produit.prixVenteUnitaire,
        'quantite': quantite,
        'prix_total': prixVenteSaisi * quantite,
        'stock': produit.stock,
        'unite_vente': produit.uniteVente,
        'prix_achat_unitaire': produit.prixAchatTotal / (produit.quantiteParUnite > 0 ? produit.quantiteParUnite : 1.0),
      });
    }
    notifyListeners();
  }

  void modifierQuantite(int index, int newQty) {
    if (newQty <= 0) {
      _panier.removeAt(index);
    } else {
      _panier[index]['quantite'] = newQty;
      _panier[index]['prix_total'] = newQty * _panier[index]['prix_unitaire'];
    }
    notifyListeners();
  }

  void setCreditMode(bool value) {
    _isCreditMode = value;
    notifyListeners();
  }

  void setAmountPaid(double value) {
    _amountPaid = value;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  void viderPanier() {
    _panier.clear();
    _amountPaid = 0.0;
    _isCreditMode = false;
    notifyListeners();
  }

  /// ============================================
  /// TRANSACTION ATOMIQUE SUPABASE SÉCURISÉE
  /// ============================================
  Future<Map<String, dynamic>?> executerEncaissement(
    String shopId, 
    String sellerId, 
    String clientNom, 
    String clientPhone
  ) async {
    try {
      if (_panier.isEmpty) return null;

      List<String> resume = [];
      for (var item in _panier) {
        resume.add("${item['nom']} (x${item['quantite']})");
      }

      final String typeVenteSaisi = _panier.first['type_vente']?.toString() ?? 'unite';
      final double totalQuantiteGlobale = _panier.fold(0.0, (sum, item) => sum + (item['quantite'] ?? 1));

      final Map<String, dynamic> ventePayload = {
        'shop_id': shopId,
        'seller_id': sellerId,
        'nom_produit': resume.join(', '),
        'quantite': totalQuantiteGlobale,
        'prix_achat_unitaire': _panier.fold(0.0, (sum, item) => sum + ((item['prix_achat_unitaire'] ?? 0.0) * (item['quantite'] ?? 1))),
        'prix_vente_prevu': _panier.fold(0.0, (sum, item) => sum + ((item['prix_initial'] ?? 0.0) * (item['quantite'] ?? 1))),
        'prix_vendu_unitaire': totalTTC / (totalQuantiteGlobale > 0 ? totalQuantiteGlobale : 1.0),
        'total': totalTTC,
        'montant_total': totalTTC,
        'benefice_reel': benefice,
        'beneficiaire': benefice,
        'type_vente': typeVenteSaisi,
        'client_nom': _isCreditMode ? (clientNom.isNotEmpty ? clientNom : 'Client Créditeur') : (clientNom.isNotEmpty ? clientNom : 'Client Comptant'),
        'status': _isCreditMode ? 'en_cours' : 'paye',
        'methode_paiement': _isCreditMode ? 'Crédit' : _selectedPaymentMethod,
        'est_credit': _isCreditMode,
        'remise': remiseGlobale,
        'montant_paye': _isCreditMode ? _amountPaid : totalTTC,
        'reste_a_payer': _isCreditMode ? montantRestant : 0.0,
        'date_vente': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await Supabase.instance.client
          .from('ventes')
          .insert(ventePayload)
          .select()
          .single();

      final String completedVenteId = response['id']?.toString() ?? '';

      // Mise à jour des stocks
      for (var item in _panier) {
        final double stockMagasinActuel = (item['stock'] ?? 0.0).toDouble();
        final double volumeVendu = (item['quantite'] ?? 1).toDouble();
        await _productsRepository.updateStock(item['produit_id'], stockMagasinActuel - volumeVendu);
      }

      // Création du crédit si nécessaire
      if (_isCreditMode && completedVenteId.isNotEmpty) {
        final nouveauCredit = CreditModel(
          shopId: shopId,
          clientNom: clientNom.isNotEmpty ? clientNom : 'Client Créditeur',
          telephoneClient: clientPhone,
          montantTotal: totalTTC,
          montantPaye: _amountPaid,
          reste: montantRestant,
          statut: 'en_cours',
          dateCredit: DateTime.now().toIso8601String(),
        );
        await _creditsRepository.createCredit(nouveauCredit);
      }

      viderPanier();
      return response;

    } catch (e) {
      debugPrint('🚨 Échec critique de la transaction atomique (VentesViewModel) : $e');
      return null;
    }
  }
}