import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/abonnement_model.dart';

class AbonnementRepository extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  AbonnementModel? _currentAbonnement;
  bool _isLoading = false;

  AbonnementModel? get currentAbonnement => _currentAbonnement;
  bool get isLoading => _isLoading;

  Future<void> checkAbonnementStatus(String shopId) async {
    _isLoading = true;
    try {
      final response = await _supabase
          .from('abonnements')
          .select('*')
          .eq('shop_id', shopId)
          .maybeSingle();

      if (response != null) {
        _currentAbonnement = AbonnementModel.fromJson(response);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('🚨 Erreur checkAbonnementStatus: $e');
    } finally {
      _isLoading = false;
    }
  }

  // Permet d'insérer un code d'activation pour renouveler la licence
  Future<bool> activerLicence(String shopId, String code) async {
    try {
      // Logique de validation à adapter selon votre système de clés d'activation
      await _supabase.from('abonnements').update({
        'code_activation': code,
        'est_active': true,
        'date_expiration': DateTime.now().add(const Duration(days: 365)).toIso8601String(), // Prolonge de 1 an
      }).eq('shop_id', shopId);
      
      await checkAbonnementStatus(shopId);
      return true;
    } catch (e) {
      debugPrint('🚨 Erreur activation licence: $e');
      return false;
    }
  }
}
