// lib/presentation/viewmodels/auth_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/oauth_helper.dart';

class AuthViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  User? get currentUser => _supabase.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  /// Connexion de l'utilisateur
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      _setLoading(false);
      return response.user != null;
    } catch (e) {
      _setError(_convertErrorMessage(e.toString()));
      _setLoading(false);
      return false;
    }
  }

  /// Inscription d'un nouveau gérant
  Future<bool> signUp(String email, String password, String fullName) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
      );
      _setLoading(false);
      return response.user != null;
    } catch (e) {
      _setError(_convertErrorMessage(e.toString()));
      _setLoading(false);
      return false;
    }
  }

  /// Connexion Google (OAuth Supabase)
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    try {
      await OAuthHelper.signInWithGoogle();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_convertErrorMessage(e.toString()));
      _setLoading(false);
      return false;
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      notifyListeners();
    } catch (e) {
      debugPrint('🚨 Erreur de déconnexion : $e');
    }
  }

  // Helpers de gestion d'état
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
  }

  String _convertErrorMessage(String rawError) {
    final msg = rawError.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Identifiants ou mot de passe incorrects.';
    } else if (msg.contains('already registered') || msg.contains('email_already_exists')) {
      return 'Cette adresse email possède déjà un compte gérant.';
    } else if (msg.contains('network') || msg.contains('connection')) {
      return 'Connexion au serveur impossible. Vérifiez votre connexion internet.';
    }
    return 'Une erreur est survenue lors de la validation.';
  }
}
