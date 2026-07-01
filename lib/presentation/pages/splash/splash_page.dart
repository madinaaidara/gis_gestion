import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/animated_splash.dart';

/// Route splash optionnelle — redirige après vérification session.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    final session = Supabase.instance.client.auth.currentSession;
    Navigator.of(context).pushReplacementNamed(session != null ? '/navigation' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return const AnimatedSplash(statusText: 'Démarrage...');
  }
}
