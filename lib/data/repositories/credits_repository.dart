import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/credit_model.dart';

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

  Future<bool> createCredit(CreditModel credit) async {
    try {
      await _supabase.from('credits').insert(credit.toJson());
      _credits.insert(0, credit);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur createCredit: $e');
      return false;
    }
  }
    /// ============================================
  /// ACTION COMMERCIALE : ENCAISSER UN REMBOURSEMENT CLIENT
  /// ============================================
  Future<bool> encaisserRemboursement(String creditId, double montantVerse) async {
    try {
      // 1. Trouver le dossier local correspondant dans la liste en mémoire
      final index = _credits.indexWhere((c) => c.id == creditId);
      if (index == -1) return false;

      final credit = _credits[index];
      
      // 2. Calculs comptables des nouvelles valeurs
      final double nouveauPaye = credit.montantPaye + montantVerse;
      final double nouveauReste = credit.reste - montantVerse;
      final String nouveauStatut = nouveauReste <= 0 ? 'paye' : 'en_cours';

      // 3. Mise à jour synchrone en base de données Supabase
      await _supabase.from('credits').update({
        'montant_paye': nouveauPaye,
        'reste': nouveauReste,
        'statut': nouveauStatut,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', creditId);

      // 4. Mise à jour de l'état local pour un rafraîchissement d'écran instantané
      _credits[index] = CreditModel(
        id: credit.id,
        shopId: credit.shopId,
        clientNom: credit.clientNom,
        telephoneClient: credit.telephoneClient,
        montantTotal: credit.montantTotal,
        montantPaye: nouveauPaye,
        reste: nouveauReste,
        statut: nouveauStatut,
        dateCredit: credit.dateCredit,
      );
      
      notifyListeners(); // Informe le ViewModel et l'écran de recalculer les indicateurs
      return true;
    } catch (e) {
      debugPrint('🚨 Erreur unique encaisserRemboursement dans le Repository : $e');
      return false;
    }
  }

}
