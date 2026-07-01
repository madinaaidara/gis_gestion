import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/credit_model.dart';
import '../models/paiement_credit_model.dart';
import 'products_repository.dart';
import 'ventes_repository.dart';

class AnnulationCreditResult {
  final bool success;
  final String? message;
  final bool stockRestored;

  const AnnulationCreditResult({
    required this.success,
    this.message,
    this.stockRestored = false,
  });
}

class CreditsRepository extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<CreditModel> _credits = [];
  bool _isLoading = false;

  List<CreditModel> get credits => _credits;
  bool get isLoading => _isLoading;

  Future<void> fetchCredits(String shopId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase
          .from('credits')
          .select('*')
          .eq('shop_id', shopId)
          .order('date_credit', ascending: false);

      _credits = (response as List).map((json) => CreditModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Erreur fetchCredits: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Recherche clients crédit par nom ou téléphone (recherche globale).
  Future<List<CreditModel>> searchClients(String shopId, String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    try {
      final response = await _supabase
          .from('credits')
          .select('*')
          .eq('shop_id', shopId)
          .or('client_nom.ilike.%$q%,telephone_client.ilike.%$q%')
          .order('date_credit', ascending: false)
          .limit(12);

      final list = (response as List).map((json) => CreditModel.fromJson(json)).toList();
      final seen = <String>{};
      return list.where((c) {
        final key = '${c.clientNom}|${c.telephoneClient ?? ''}';
        if (seen.contains(key)) return false;
        seen.add(key);
        return true;
      }).take(8).toList();
    } catch (e) {
      debugPrint('Erreur searchClients: $e');
      return [];
    }
  }

  Future<bool> createCredit(CreditModel credit) async {
    try {
      final response = await _supabase.from('credits').insert(credit.toJson()).select().single();
      final created = CreditModel.fromJson(response);
      _credits.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur createCredit: $e');
      return false;
    }
  }

  Future<bool> encaisserRemboursement(String creditId, double montantVerse) async {
    try {
      final index = _credits.indexWhere((c) => c.id == creditId);
      if (index == -1) return false;

      final credit = _credits[index];
      if (montantVerse <= 0 || montantVerse > credit.reste + 0.0001) return false;

      final double nouveauPaye = credit.montantPaye + montantVerse;
      final double nouveauReste = (credit.reste - montantVerse).clamp(0.0, double.infinity);
      final String nouveauStatut = nouveauReste <= 0.0001 ? 'paye' : 'en_cours';
      final now = DateTime.now().toIso8601String();

      await _supabase.from('credits').update({
        'montant_paye': nouveauPaye,
        'reste': nouveauReste,
        'statut': nouveauStatut,
      }).eq('id', creditId);

      try {
        await _supabase.from('paiements_credit').insert({
          'credit_id': creditId,
          'montant': montantVerse,
          'date_paiement': now,
        });
      } catch (e) {
        debugPrint('Historique paiement non enregistré (table paiements_credit?) : $e');
      }

      if (credit.venteId != null && credit.venteId!.isNotEmpty) {
        try {
          await _supabase.from('ventes').update({
            'montant_paye': nouveauPaye,
            'reste_a_payer': nouveauReste,
            'status': nouveauStatut == 'paye' ? 'paye' : 'en_cours',
          }).eq('id', credit.venteId!);
        } catch (e) {
          debugPrint('Sync vente crédit ignorée : $e');
        }
      }

      _credits[index] = CreditModel(
        id: credit.id,
        shopId: credit.shopId,
        venteId: credit.venteId,
        clientNom: credit.clientNom,
        telephoneClient: credit.telephoneClient,
        montantTotal: credit.montantTotal,
        montantPaye: nouveauPaye,
        reste: nouveauReste,
        statut: nouveauStatut,
        dateCredit: credit.dateCredit,
        note: credit.note,
        createdAt: credit.createdAt,
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur encaisserRemboursement : $e');
      return false;
    }
  }

  Future<List<PaiementCreditModel>> fetchPaiements(String creditId) async {
    try {
      final response = await _supabase
          .from('paiements_credit')
          .select('*')
          .eq('credit_id', creditId)
          .order('date_paiement', ascending: false);
      return (response as List).map((json) => PaiementCreditModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Erreur fetchPaiements : $e');
      return [];
    }
  }

  /// Annule un dossier crédit en cours : statut « annule », vente liée, stock restauré.
  Future<AnnulationCreditResult> annulerCredit(
    String creditId, {
    required ProductsRepository productsRepository,
    required VentesRepository ventesRepository,
  }) async {
    try {
      final response = await _supabase.from('credits').select('*').eq('id', creditId).maybeSingle();
      if (response == null) {
        return const AnnulationCreditResult(success: false, message: 'Dossier introuvable');
      }

      final credit = CreditModel.fromJson(response);
      final statut = credit.statut ?? 'en_cours';

      if (statut == 'annule') {
        return const AnnulationCreditResult(success: false, message: 'Ce dossier est déjà annulé');
      }
      if (statut == 'paye') {
        return const AnnulationCreditResult(success: false, message: 'Impossible d\'annuler un crédit déjà soldé');
      }

      var stockRestored = false;
      Map<String, dynamic>? venteLiee;

      if (credit.venteId != null && credit.venteId!.isNotEmpty) {
        venteLiee = await _supabase
            .from('ventes')
            .select('*')
            .eq('id', credit.venteId!)
            .maybeSingle();
      } else if (credit.shopId != null && credit.shopId!.isNotEmpty) {
        final rows = List<Map<String, dynamic>>.from(
          await _supabase
              .from('ventes')
              .select('*')
              .eq('shop_id', credit.shopId!)
              .eq('client_nom', credit.clientNom)
              .eq('est_credit', true)
              .neq('status', 'annulee')
              .order('created_at', ascending: false)
              .limit(1),
        );
        if (rows.isNotEmpty) {
          venteLiee = rows.first;
        }
      }

      if (venteLiee != null && venteLiee['status']?.toString() != 'annulee') {
        stockRestored = await ventesRepository.restaurerStockDepuisVente(
          venteLiee,
          productsRepository: productsRepository,
          shopId: credit.shopId,
        );
        final venteId = venteLiee['id']?.toString();
        if (venteId != null && venteId.isNotEmpty) {
          await _supabase.from('ventes').update({'status': 'annulee'}).eq('id', venteId);
        }
      }

      await _supabase.from('credits').update({'statut': 'annule', 'reste': 0}).eq('id', creditId);

      final index = _credits.indexWhere((c) => c.id == creditId);
      if (index >= 0) {
        _credits[index] = CreditModel(
          id: credit.id,
          shopId: credit.shopId,
          venteId: credit.venteId,
          clientNom: credit.clientNom,
          telephoneClient: credit.telephoneClient,
          montantTotal: credit.montantTotal,
          montantPaye: credit.montantPaye,
          reste: 0,
          statut: 'annule',
          dateCredit: credit.dateCredit,
          note: credit.note,
          createdAt: credit.createdAt,
        );
      }

      notifyListeners();

      var message = stockRestored
          ? 'Dossier annulé et stock restauré'
          : 'Dossier annulé (stock non restauré — vente sans détail produit)';
      if (credit.montantPaye > 0.0001) {
        message += '\nAcompte reçu : ${credit.montantPaye.toStringAsFixed(0)} — rembourser le client manuellement.';
      }

      return AnnulationCreditResult(success: true, stockRestored: stockRestored, message: message);
    } catch (e) {
      debugPrint('Erreur annulerCredit : $e');
      return AnnulationCreditResult(success: false, message: 'Erreur lors de l\'annulation');
    }
  }
}
