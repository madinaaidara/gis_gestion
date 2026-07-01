// ============================================
// AUTH WRAPPER - GESTION DU FLUX UTILISATEUR
// Version avec rafraîchissement FORCÉ du token
// ============================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/auth/login_page.dart';
import '../pages/onboarding/setup_boutique_page.dart';
import '../pages/onboarding/onboarding_tour_page.dart';
import '../pages/navigation/navigation_page.dart';
import 'animated_splash.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  String _debugStatus = 'Démarrage...';
  bool _hasError = false;
  String _errorMessage = '';
  
  Widget _targetScreen = const LoginPage();

  @override
  void initState() {
    super.initState();
    debugPrint('🎯 AuthWrapper: Démarrage...');
    _checkUserStatus();
  }

  /// ============================================
  /// RAFRAÎCHIR LE TOKEN JWT DE MANIÈRE FORCÉE
  /// ============================================
  Future<bool> _forceRefreshToken() async {
    try {
      final supabase = Supabase.instance.client;
      debugPrint('🔄 Rafraîchissement forcé du token JWT...');
      await supabase.auth.refreshSession();
      debugPrint('✅ Token JWT rafraîchi avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur rafraîchissement token: $e');
      return false;
    }
  }

  /// ============================================
  /// VÉRIFIER OÙ EN EST L'UTILISATEUR (FLUX SÉCURISÉ)
  /// ============================================
  Future<void> _checkUserStatus() async {
    Widget? destination;
    var status = 'Initialisation...';

    try {
      final supabase = Supabase.instance.client;
      var currentUser = supabase.auth.currentUser;

      if (currentUser == null) {
        debugPrint('📱 PAS CONNECTÉ → Login');
        destination = const LoginPage();
        status = 'Redirection vers Login...';
      } else {
        debugPrint('✅ Connecté: ${currentUser.email}');
        _setStatus('Vérification session...');
        await _forceRefreshToken();

        currentUser = supabase.auth.currentUser;
        if (currentUser == null) {
          destination = const LoginPage();
          status = 'Session expirée...';
        } else {
          _setStatus('Vérification boutique...');
          final hasShop = await _userHasShop(currentUser.id);

          if (!hasShop) {
            destination = const SetupBoutiquePage();
            status = 'Configuration boutique...';
          } else {
            status = 'Chargement...';
            final hasSeenOnboarding = await _hasSeenOnboardingBefore();
            if (!hasSeenOnboarding) {
              destination = const OnboardingTourPage();
              status = 'Découverte...';
            } else {
              destination = const NavigationPage(indexInitial: 0);
              status = 'Bienvenue !';
            }
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur Critique Routage: $e');
      debugPrint('❌ StackTrace: $stackTrace');
      destination = const LoginPage();
      status = 'Erreur d\'authentification';
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }

    await Future.delayed(const Duration(milliseconds: 2800));

    if (mounted) {
      setState(() {
        _debugStatus = status;
        _targetScreen = destination ?? const LoginPage();
        _isLoading = false;
      });
    }
  }

  void _setStatus(String status) {
    if (mounted) setState(() => _debugStatus = status);
  }

  /// ============================================
  /// REQUÊTES BRUTES DE RECHERCHE (SUPABASE / PREFS)
  /// ============================================
  Future<bool> _userHasShop(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Rafraîchir le token avant chaque requête
      await _forceRefreshToken();
      
      final response = await supabase
          .from('shops')
          .select('id, nom_boutique')
          .eq('owner_id', userId)
          .maybeSingle();
          
      debugPrint('✅ Requête shops réussie: ${response != null ? "Boutique trouvée" : "Aucune boutique"}');
      return response != null;
    } catch (e) {
      debugPrint('❌ Erreur lecture table shops : $e');
      
      // Si erreur JWT, on rafraîchit et on réessaie une fois
      if (e.toString().contains('JWT expired') || e.toString().contains('PGRST303')) {
        debugPrint('🔄 Nouvelle tentative après refresh...');
        await _forceRefreshToken();
        try {
          final supabase = Supabase.instance.client;
          final response = await supabase
              .from('shops')
              .select('id, nom_boutique')
              .eq('owner_id', userId)
              .maybeSingle();
          return response != null;
        } catch (retryError) {
          debugPrint('❌ Échec tentative: $retryError');
          return false;
        }
      }
      
      return false;
    }
  }

  Future<bool> _hasSeenOnboardingBefore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('has_seen_onboarding') ?? false;
    } catch (e) {
      debugPrint('❌ Erreur lecture SharedPreferences : $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoading) return _targetScreen;

    return AnimatedSplash(
      statusText: _debugStatus,
      hasError: _hasError,
      errorMessage: _hasError ? _errorMessage : null,
    );
  }
}
