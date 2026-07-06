import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../pages/landing/landing_page.dart';
import 'auth_wrapper.dart';

/// Point d'entrée web : landing publique ou app si déjà connecté.
class AppEntry extends StatelessWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      return const AuthWrapper();
    }
    return const LandingPage();
  }
}
