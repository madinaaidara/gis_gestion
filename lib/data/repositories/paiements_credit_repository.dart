import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/paiement_credit_model.dart';

class PaiementsCreditRepository extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<PaiementCreditModel> _paiements = [];
  bool _isLoading = false;

  List<PaiementCreditModel> get paiements => _paiements;
  bool get isLoading => _isLoading;

  Future<void> fetchPaiementsForCredit(String creditId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase
          .from('paiements_credit')
          .select('*')
          .eq('credit_id', creditId)
          .order('date_paiement', ascending: false);
          
      _paiements = (response as List).map((json) => PaiementCreditModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Erreur fetchPaiements: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> enregistrerVersement(PaiementCreditModel paiement, String creditId, double montantSaisi) async {
    try {
      // 1. Enregistrer la ligne d'historique de versement
      await _supabase.from('paiements_credit').insert(paiement.toJson());
      _paiements.insert(0, paiement);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur enregistrerVersement: $e');
      return false;
    }
  }
}
