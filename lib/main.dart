import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

// Constantes globales de configuration
import 'core/constants/supabase_constants.dart';
import 'core/theme/app_surface.dart';
import 'core/theme/gis_palette.dart';
import 'core/services/app_refresh_notifier.dart';
import 'presentation/viewmodels/theme_viewmodel.dart';

// COUCHE DATA : Importations corrigées selon votre arborescence exacte
import 'data/repositories/products_repository.dart';
import 'data/repositories/categories_repository.dart';
import 'data/repositories/ventes_repository.dart';
import 'data/repositories/credits_repository.dart';
import 'data/repositories/abonnement_repository.dart';

// Importations des Repositories 
import 'data/repositories/shops_repository.dart'; 
import 'data/repositories/profil_repository.dart';
import 'data/repositories/stats_repository.dart';
import 'data/repositories/assistant_repository.dart';

// COUCHE PRÉSENTATION : Flux de navigation et d'écrans
import 'presentation/widgets/app_entry.dart';
import 'presentation/widgets/auth_wrapper.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/navigation/navigation_page.dart';
import 'presentation/pages/onboarding/setup_boutique_page.dart';
import 'presentation/pages/onboarding/onboarding_tour_page.dart';
import 'presentation/pages/abonnement/abonnement_page.dart';

import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/credits_viewmodel.dart';
import 'presentation/viewmodels/shop_viewmodel.dart';
import 'presentation/viewmodels/ventes_viewmodel.dart';
import 'presentation/viewmodels/products_viewmodel.dart';
import 'presentation/viewmodels/stats_viewmodel.dart';
import 'presentation/viewmodels/assistant_viewmodel.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. INITIALISATION DU MOTEUR BRUT SUPABASE
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  
  await initializeDateFormatting('fr_FR', null);

  AppSurface.sync(GisPalette.light);

  runApp(const GisGestionApp());
}

class GisGestionApp extends StatelessWidget {
  const GisGestionApp({super.key});

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
          update: (_, repo, previous) => previous ?? ShopViewModel(repo),
        ),
        
        ChangeNotifierProxyProvider2<ProductsRepository, CategoriesRepository, ProductsViewModel>(
          create: (context) => ProductsViewModel(
            Provider.of<ProductsRepository>(context, listen: false),
            Provider.of<CategoriesRepository>(context, listen: false),
          ),
          update: (_, repoProd, repoCat, previous) =>
              previous ?? ProductsViewModel(repoProd, repoCat),
        ),
        
        ChangeNotifierProxyProvider3<VentesRepository, ProductsRepository, CreditsRepository, VentesViewModel>(
          create: (context) => VentesViewModel(
            Provider.of<ProductsRepository>(context, listen: false),
            Provider.of<CreditsRepository>(context, listen: false),
          ),
          update: (_, rVente, rProd, rCredit, previous) =>
              previous ?? VentesViewModel(rProd, rCredit),
        ),
        
        ChangeNotifierProxyProvider<CreditsRepository, CreditsViewModel>(
          create: (context) => CreditsViewModel(Provider.of<CreditsRepository>(context, listen: false)),
          update: (_, repo, previous) => previous ?? CreditsViewModel(repo),
        ),
        ChangeNotifierProvider(create: (_) => StatsViewModel(StatsRepository())),
        ChangeNotifierProvider(create: (_) => AssistantViewModel(AssistantRepository())),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => AppRefreshNotifier()),
      ],


      child: Consumer<ThemeViewModel>(
        builder: (context, themeVm, _) {
          AppSurface.sync(themeVm.isDark ? GisPalette.dark : GisPalette.light);
          return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Gis Gestion',
        theme: gisLightTheme(),
        darkTheme: gisDarkTheme(),
        themeMode: themeVm.mode,

        // ============================================
        // FLUX DE ROUTAGE NOMMÉ DE L'APPLICATION
        // ============================================
        initialRoute: '/',
        routes: {
          '/': (context) => const AppEntry(),
          '/app': (context) => const AuthWrapper(),
          '/login': (context) {
            final signUp = ModalRoute.of(context)?.settings.arguments == true;
            return LoginPage(initialSignUp: signUp);
          },
          '/navigation': (context) => const NavigationPage(indexInitial: 0),
          '/setup-boutique': (context) => const SetupBoutiquePage(),
          '/onboarding-tour': (context) => const OnboardingTourPage(),
          '/abonnement': (context) => const AbonnementPage(),
        },
          );
        },
      ),
    );
  }
}
