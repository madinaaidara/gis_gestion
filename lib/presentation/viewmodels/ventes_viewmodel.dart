// lib/presentation/viewmodels/ventes_viewmodel.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../../data/models/produit_model.dart';
import '../../data/models/credit_model.dart';
import '../../data/repositories/products_repository.dart';
import '../../data/repositories/credits_repository.dart';
import '../../core/utils/lignes_panier_utils.dart';

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
      final double factor = (item['facteur_conversion'] ?? 1.0).toDouble();
      return sum + (venteLigne - (coutAchatUnitaire * qty * factor));
    });
  }

  double get margePercentage {
    final double totalCout = _panier.fold(0.0, (sum, item) {
      final factor = (item['facteur_conversion'] ?? 1.0).toDouble();
      return sum + ((item['prix_achat_unitaire'] ?? 0.0) * (item['quantite'] ?? 1) * factor);
    });
    if (totalCout == 0) return 0.0;
    return (benefice / totalCout) * 100;
  }

  bool get isPerte => benefice < 0;

  /// Volume déjà réservé dans le panier pour un produit (en unités de base).
  double stockReserveDansPanier(String produitId) {
    return _panier.where((item) => item['produit_id'] == produitId).fold(0.0, (sum, item) {
      final qty = (item['quantite'] ?? 1).toDouble();
      final factor = (item['facteur_conversion'] ?? 1.0).toDouble();
      return sum + qty * factor;
    });
  }

  double stockDisponible(ProduitModel produit) {
    final id = produit.id ?? '';
    return produit.stock - stockReserveDansPanier(id);
  }

  bool peutAjouterAuPanier(ProduitModel produit, int quantite, double facteurConversion) {
    final volume = quantite * facteurConversion;
    return volume <= stockDisponible(produit) + 0.0001;
  }

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
        'facteur_conversion': 1.0,
        'prix_achat_unitaire': produit.prixAchatTotal / (produit.quantiteParUnite > 0 ? produit.quantiteParUnite : 1.0),
      });
    }
    notifyListeners();
  }

  void modifierQuantite(int index, int newQty) {
    if (newQty <= 0) {
      _panier.removeAt(index);
    } else {
      final item = _panier[index];
      final produitId = item['produit_id']?.toString() ?? '';
      final factor = (item['facteur_conversion'] ?? 1.0).toDouble();
      final stockSnapshot = (item['stock'] ?? 0.0).toDouble();
      final autresReserves = _panier.asMap().entries.where((e) => e.key != index && e.value['produit_id'] == produitId).fold(0.0, (sum, e) {
        final q = (e.value['quantite'] ?? 1).toDouble();
        final f = (e.value['facteur_conversion'] ?? 1.0).toDouble();
        return sum + q * f;
      });
      final volumeDemande = newQty * factor;
      if (volumeDemande > stockSnapshot - autresReserves + 0.0001) return;

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

      final lignesPanier = LignesPanierUtils.fromPanier(_panier);

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
        'lignes_panier': lignesPanier,
      };

      Map<String, dynamic> response;
      try {
        response = await Supabase.instance.client
            .from('ventes')
            .insert(ventePayload)
            .select()
            .single();
      } catch (e) {
        final err = e.toString();
        if (err.contains('lignes_panier')) {
          debugPrint('⚠️ Colonne lignes_panier absente — exécutez add_lignes_panier_to_ventes.sql');
          ventePayload.remove('lignes_panier');
          response = await Supabase.instance.client
              .from('ventes')
              .insert(ventePayload)
              .select()
              .single();
        } else {
          rethrow;
        }
      }

      final String completedVenteId = response['id']?.toString() ?? '';

      if (completedVenteId.isNotEmpty && lignesPanier.isNotEmpty) {
        try {
          await Supabase.instance.client
              .from('ventes')
              .update({'lignes_panier': lignesPanier})
              .eq('id', completedVenteId);
          debugPrint('✓ lignes_panier sauvegardées pour vente $completedVenteId');
        } catch (e) {
          debugPrint('⚠️ lignes_panier non sauvegardées (migration SQL?) : $e');
        }
      }

      final Map<String, double> stockInitialParProduit = {};
      final Map<String, double> volumeVenduParProduit = {};

      for (var item in _panier) {
        final String id = item['produit_id']?.toString() ?? '';
        if (id.isEmpty) continue;
        stockInitialParProduit.putIfAbsent(id, () => (item['stock'] ?? 0.0).toDouble());
        final volume = (item['quantite'] ?? 1).toDouble() * (item['facteur_conversion'] ?? 1.0).toDouble();
        volumeVenduParProduit[id] = (volumeVenduParProduit[id] ?? 0) + volume;
      }

      for (final entry in volumeVenduParProduit.entries) {
        final stockActuel = stockInitialParProduit[entry.key] ?? 0;
        await _productsRepository.updateStock(entry.key, stockActuel - entry.value);
      }

      // Création du crédit si nécessaire
      if (_isCreditMode && completedVenteId.isNotEmpty) {
        final nouveauCredit = CreditModel(
          shopId: shopId,
          venteId: completedVenteId,
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

  /// @deprecated Utiliser [VentesRepository.annulerVente] depuis l'Historique.
  Future<bool> annulerVente(String venteId, List<Map<String, dynamic>> items) async {
    return false;
  }

  void modifierPrixLigne(int index, double nouveauPrix) {
    if (index < 0 || index >= _panier.length || nouveauPrix <= 0) return;
    final qty = (_panier[index]['quantite'] ?? 1) as int;
    _panier[index]['prix_unitaire'] = nouveauPrix;
    _panier[index]['prix_total'] = nouveauPrix * qty;
    notifyListeners();
  }

  bool mettreAJourLignePanier(
    int index,
    int quantite,
    double prixVente,
    String unite,
    double facteurConversion,
  ) {
    if (index < 0 || index >= _panier.length || quantite <= 0 || prixVente <= 0) return false;

    final item = _panier[index];
    final produitId = item['produit_id']?.toString() ?? '';
    final stockSnapshot = (item['stock'] ?? 0.0).toDouble();
    final autresReserves = _panier.asMap().entries.where((e) {
      if (e.key == index) return false;
      return e.value['produit_id']?.toString() == produitId;
    }).fold(0.0, (sum, e) {
      final q = (e.value['quantite'] ?? 1).toDouble();
      final f = (e.value['facteur_conversion'] ?? 1.0).toDouble();
      return sum + q * f;
    });

    final volumeDemande = quantite * facteurConversion;
    if (volumeDemande > stockSnapshot - autresReserves + 0.0001) return false;

    _panier[index]['quantite'] = quantite;
    _panier[index]['prix_unitaire'] = prixVente;
    _panier[index]['unite_vente'] = unite;
    _panier[index]['facteur_conversion'] = facteurConversion;
    _panier[index]['prix_total'] = prixVente * quantite;
    notifyListeners();
    return true;
  }

  int _indexLignePanier(String produitId, String unite, double prixUnitaire) {
    return _panier.indexWhere((item) {
      if (item['produit_id'] != produitId) return false;
      if ((item['unite_vente'] ?? '') != unite) return false;
      final p = (item['prix_unitaire'] ?? 0.0).toDouble();
      return (p - prixUnitaire).abs() < 0.01;
    });
  }

  bool ajouterAuPanierAvecUnite(ProduitModel produit, int quantite, double prixVente, String unite, double facteurConversion) {
    final produitId = produit.id ?? '';
    final volumeAAjouter = quantite * facteurConversion;
    if (stockReserveDansPanier(produitId) + volumeAAjouter > produit.stock + 0.0001) {
      return false;
    }

    final existIndex = _indexLignePanier(produitId, unite, prixVente);

    if (existIndex >= 0) {
      final int newQty = _panier[existIndex]['quantite'] + quantite;
      _panier[existIndex]['quantite'] = newQty;
      _panier[existIndex]['prix_total'] = prixVente * newQty;
    } else {
      _panier.add({
        'produit_id': produit.id,
        'nom': produit.nom,
        'type_vente': produit.typeVente ?? 'unite',
        'prix_unitaire': prixVente,
        'prix_initial': produit.prixVenteUnitaire * facteurConversion,
        'quantite': quantite,
        'prix_total': prixVente * quantite,
        'stock': produit.stock,
        'unite_vente': unite,
        'facteur_conversion': facteurConversion,
        'prix_achat_unitaire': produit.prixAchatTotal / (produit.quantiteParUnite > 0 ? produit.quantiteParUnite : 1.0),
      });
    }
    notifyListeners();
    return true;
  }
}