// ============================================
// AUTH WRAPPER - GESTION DU FLUX UTILISATEUR
// Version avec rafraîchissement FORCÉ du token
// ============================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importations de vos pages
import '../pages/auth/login_page.dart';
import '../pages/onboarding/setup_boutique_page.dart';
import '../pages/onboarding/onboarding_tour_page.dart';
import '../pages/navigation/navigation_page.dart';
import '../../../core/theme/app_colors.dart';

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
  
  Widget _targetScreen = const Scaffold(
    body: Center(
      child: CircularProgressIndicator(color: AppColors.primaryIndigo),
    ),
  );

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
    try {
      final supabase = Supabase.instance.client;
      
      // Étape 1: Vérifier si l'utilisateur est connecté
      var currentUser = supabase.auth.currentUser;

      if (currentUser == null) {
        debugPrint('📱 PAS CONNECTÉ → Login');
        _updateState('Redirection vers Login...', const LoginPage());
        return;
      }

      debugPrint('✅ Connecté: ${currentUser.email}');
      
      // Étape 2: Rafraîchir le token FORCÉMENT avant toute requête
      await _forceRefreshToken();
      
      // Re-obtenir l'utilisateur après rafraîchissement
      currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        debugPrint('📱 Session perdue après refresh → Login');
        _updateState('Session expirée...', const LoginPage());
        return;
      }
      
      _updateState('Connecté, vérification boutique...', null);

      // Étape 3: Vérifier si le gérant possède une boutique enregistrée
      final hasShop = await _userHasShop(currentUser.id);

      if (!hasShop) {
        debugPrint('🏪 PAS DE BOUTIQUE → Setup');
        _updateState('Création de boutique requise...', const SetupBoutiquePage());
        return;
      }

      debugPrint('✅ Boutique existe');
      _updateState('Boutique trouvée, vérification onboarding...', null);

      // Étape 4: Vérifier si la visite guidée d'onboarding a été complétée
      final hasSeenOnboarding = await _hasSeenOnboardingBefore();

      if (!hasSeenOnboarding) {
        debugPrint('🎓 ONBOARDING NON VU → Onboarding');
        _updateState('Découverte de l\'application...', const OnboardingTourPage());
        return;
      }

      debugPrint('🎉 TOUT VALIDÉ → Navigation Active');
      _updateState('Bienvenue ! Redirection...', const NavigationPage(indexInitial: 0));
      
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur Critique Routage: $e');
      debugPrint('❌ StackTrace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
      _updateState('Erreur d\'authentification', const LoginPage());
    }
  }

  void _updateState(String status, Widget? nextScreen) {
    if (mounted) {
      setState(() {
        _debugStatus = status;
        if (nextScreen != null) {
          _targetScreen = nextScreen;
          _isLoading = false;
        }
      });
    }
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
    if (!_isLoading) {
      return _targetScreen;
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;

    final logoHeight = isSmallScreen ? 110.0 : 130.0;
    final indicatorSize = isSmallScreen ? 32.0 : 36.0;

    return Scaffold(
      backgroundColor: AppColors.sidebarBg,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.sidebarBg,
              Color(0xFF161624),
              Color(0xFF0F0F1A),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        height: logoHeight,
                        width: logoHeight,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.glowIndigo.withOpacity(0.4),
                              blurRadius: 24 * value,
                              spreadRadius: 4 * value,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo_guiss_gestion1.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [AppColors.sidebarBg, AppColors.primaryIndigo],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.store_rounded, color: Colors.white, size: 44),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Column(
                        children: [
                          const Text(
                            'GIS Gestion',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.6,
                              shadows: [Shadow(color: AppColors.glowIndigo, blurRadius: 16)],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.12)),
                            ),
                            child: const Text(
                              'Gestion de Boutique',
                              style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600, letterSpacing: 0.3),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                
                SizedBox(
                  width: indicatorSize,
                  height: indicatorSize,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryIndigo),
                    backgroundColor: Colors.white10,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _debugStatus,
                  style: TextStyle(
                    fontSize: 12, 
                    color: Colors.white.withOpacity(0.4), 
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                
                if (_hasError) _buildErrorBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'ÉCHEC DE ROUTAGE',
            style: TextStyle(
              fontSize: 11, 
              color: AppColors.danger, 
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _errorMessage,
            style: TextStyle(
              fontSize: 11, 
              color: Colors.white.withOpacity(0.7), 
              height: 1.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}