import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/supabase_constants.dart';
import '../models/abonnement_model.dart';
import '../models/activation_result.dart';

class AbonnementRepository extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  static const _table = SupabaseConstants.tableLicences;

  AbonnementModel? _currentAbonnement;
  bool _isLoading = false;
  String _lastError = '';

  AbonnementModel? get currentAbonnement => _currentAbonnement;
  bool get isLoading => _isLoading;
  String get lastError => _lastError;
  bool get hasValidSubscription => _currentAbonnement?.isValid ?? false;

  Future<void> checkAbonnementStatus(String shopId) async {
    _isLoading = true;
    _lastError = '';
    notifyListeners();
    try {
      final response = await _supabase
          .from(_table)
          .select('*')
          .eq('shop_id', shopId)
          .maybeSingle();

      _currentAbonnement =
          response != null ? AbonnementModel.fromJson(response) : null;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Erreur checkAbonnementStatus (licences): $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Essai 30 jours automatique à la création de boutique (sans code).
  Future<void> ensureTrialForShop(String shopId) async {
    await checkAbonnementStatus(shopId);
    if (_currentAbonnement != null) return;

    final now = DateTime.now();
    final trialEnd = now.add(const Duration(days: 30));
    try {
      await _supabase.from(_table).insert({
        'shop_id': shopId,
        'date_installation': now.toIso8601String(),
        'date_expiration': trialEnd.toIso8601String(),
        'est_active': true,
        'type_abonnement': 'essai',
      });
      await checkAbonnementStatus(shopId);
    } catch (e) {
      debugPrint('Erreur ensureTrialForShop (licences): $e');
    }
  }

  /// Active un code à usage unique via Supabase (RPC activer_code_licence).
  Future<ActivationResult> activerLicence(String shopId, String code) async {
    _lastError = '';
    final normalized = code.trim();
    if (normalized.isEmpty) {
      return const ActivationResult(success: false, errorMessage: 'Entrez un code d\'activation');
    }

    try {
      final raw = await _supabase.rpc('activer_code_licence', params: {
        'p_shop_id': shopId,
        'p_code': normalized,
      });

      final map = raw is Map<String, dynamic> ? raw : Map<String, dynamic>.from(raw as Map);
      final success = map['success'] == true;

      if (!success) {
        _lastError = map['error']?.toString() ?? 'Code invalide ou déjà utilisé';
        notifyListeners();
        return ActivationResult(success: false, errorMessage: _lastError);
      }

      await checkAbonnementStatus(shopId);
      return ActivationResult(
        success: true,
        typeAbonnement: map['type_abonnement']?.toString(),
      );
    } catch (e) {
      _lastError = _parseRpcError(e);
      debugPrint('Erreur activerLicence: $e');
      notifyListeners();
      return ActivationResult(success: false, errorMessage: _lastError);
    }
  }

  String _parseRpcError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('activer_code_licence') && msg.contains('does not exist')) {
      return 'Configuration Supabase manquante. Exécutez create_codes_activation.sql';
    }
    if (msg.contains('already used') || msg.contains('déjà utilisé')) {
      return 'Ce code a déjà été utilisé par une autre boutique';
    }
    return 'Code invalide ou déjà utilisé';
  }
}
