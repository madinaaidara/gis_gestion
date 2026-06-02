import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Constantes globales de configuration
import 'core/constants/supabase_constants.dart';
import 'core/theme/app_colors.dart' as theme;

// COUCHE DATA : Importations corrigées selon votre arborescence exacte
import 'data/repositories/products_repository.dart';
import 'data/repositories/categories_repository.dart';
import 'data/repositories/ventes_repository.dart';
import 'data/repositories/credits_repository.dart';
import 'data/repositories/abonnement_repository.dart';

// Importations des Repositories 
import 'data/repositories/shops_repository.dart'; 
import 'data/repositories/profil_repository.dart';

// COUCHE PRÉSENTATION : Flux de navigation et d'écrans
import 'presentation/widgets/auth_wrapper.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/navigation/navigation_page.dart';
import 'presentation/pages/onboarding/setup_boutique_page.dart';
import 'presentation/pages/onboarding/onboarding_tour_page.dart';

import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/credits_viewmodel.dart';
import 'presentation/viewmodels/shop_viewmodel.dart';
import 'presentation/viewmodels/ventes_viewmodel.dart';
import 'presentation/viewmodels/products_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. INITIALISATION DU MOTEUR BRUT SUPABASE
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  runApp(const GuissGestionApp());
}

class GuissGestionApp extends StatelessWidget {
  const GuissGestionApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. INJECTION GLOBALE DE L'ARCHITECTURE DES DONNÉES (MULTIPROVIDER VALIDÉ)
    return MultiProvider(
            providers: [
        // 1. DÉCLARATION DES SOURCETS DE DONNÉES (REPOSITORIES)
        ChangeNotifierProvider(create: (_) => ShopsRepository()),
        ChangeNotifierProvider(create: (_) => ProductsRepository()),
        ChangeNotifierProvider(create: (_) => CategoriesRepository()),
        ChangeNotifierProvider(create: (_) => VentesRepository()),
        ChangeNotifierProvider(create: (_) => CreditsRepository()),
        ChangeNotifierProvider(create: (_) => ProfilRepository()),
        ChangeNotifierProvider(create: (_) => AbonnementRepository()),

        // 2. INJECTION DES VIEWMODELS MÉTIERS CONNECTÉS (MVVM INTERACTIVE)
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        
        ChangeNotifierProxyProvider<ShopsRepository, ShopViewModel>(
          create: (context) => ShopViewModel(Provider.of<ShopsRepository>(context, listen: false)),
          update: (_, repo, __) => ShopViewModel(repo),
        ),
        
        ChangeNotifierProxyProvider2<ProductsRepository, CategoriesRepository, ProductsViewModel>(
          create: (context) => ProductsViewModel(
            Provider.of<ProductsRepository>(context, listen: false),
            Provider.of<CategoriesRepository>(context, listen: false),
          ),
          update: (_, repoProd, repoCat, __) => ProductsViewModel(repoProd, repoCat),
        ),
        
        ChangeNotifierProxyProvider3<VentesRepository, ProductsRepository, CreditsRepository, VentesViewModel>(
          create: (context) => VentesViewModel(
            Provider.of<ProductsRepository>(context, listen: false),
            Provider.of<CreditsRepository>(context, listen: false),
          ),
          update: (_, rVente, rProd, rCredit, __) => VentesViewModel(rProd, rCredit),
        ),
        
        ChangeNotifierProxyProvider<CreditsRepository, CreditsViewModel>(
          create: (context) => CreditsViewModel(Provider.of<CreditsRepository>(context, listen: false)),
          update: (_, repo, __) => CreditsViewModel(repo),
        ),
      ],

      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'GIS Gestion',
        
        // ============================================
        // CONFIGURATION DU THÈME VISUEL SAAS PREMIUM
        // ============================================
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: theme.AppColors.background,
          primaryColor: theme.AppColors.primaryIndigo,
          colorScheme: ColorScheme.fromSeed(
            seedColor: theme.AppColors.primaryIndigo,
            background: theme.AppColors.background,
            surface: theme.AppColors.surface,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: theme.AppColors.textPrimary),
            bodyMedium: TextStyle(color: theme.AppColors.textPrimary),
          ),
        ),

        // ============================================
        // FLUX DE ROUTAGE NOMMÉ DE L'APPLICATION
        // ============================================
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginPage(),
          '/navigation': (context) => const NavigationPage(indexInitial: 0),
          '/setup-boutique': (context) => const SetupBoutiquePage(),
          '/onboarding-tour': (context) => const OnboardingTourPage(),
        },
      ),
    );
  }
}
