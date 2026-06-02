import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

/// ============================================
/// PROFIL REPOSITORY - GIS Gestion
/// ============================================
/// Centralise les requêtes de la table 'profiles'.
/// Récupère l'identité et les droits du gérant connecté.
/// ============================================

class ProfilRepository extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  ProfileModel? _currentProfile;
  bool _isLoading = false;
  String _errorMessage = '';

  ProfileModel? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  /// ============================================
  /// RECUPE RER LE COMPTE DU GÉRANT SÉCURISÉ
  /// ============================================
  Future<void> fetchProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _setLoading(true);
    _clearError();

    try {
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        _currentProfile = ProfileModel.fromJson(response);
      } else {
        // Sécurité/Fallback si le trigger Supabase d'inscription prend du temps
        _currentProfile = ProfileModel(
          id: user.id,
          email: user.email,
          fullName: user.userMetadata?['full_name']?.toString() ?? user.email?.split('@').first,
          phone: user.phone,
        );
      }
    } catch (e) {
      _setError('Impossible d\'extraire les informations du profil : $e');
    }

    _setLoading(false);
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
    debugPrint('🚨 ProfilRepository : $message');
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
  }
}
