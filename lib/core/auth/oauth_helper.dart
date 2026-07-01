import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// OAuth Google via Supabase.
/// Config Supabase requise : Auth → Providers → Google activé
/// Redirect URLs : guissgestion://login-callback + URL web (localhost)
class OAuthHelper {
  static const String mobileRedirectScheme = 'guissgestion';
  static const String mobileRedirectHost = 'login-callback';

  static String get redirectUrl {
    if (kIsWeb) {
      return Uri.base.origin;
    }
    return '$mobileRedirectScheme://$mobileRedirectHost/';
  }

  static Future<void> signInWithGoogle() async {
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectUrl,
      authScreenLaunchMode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
  }

  static Future<void> ensureProfileFromAuthUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final metaName = user.userMetadata?['full_name']?.toString() ??
        user.userMetadata?['name']?.toString() ??
        user.email?.split('@').first ??
        'Utilisateur';

    await Supabase.instance.client.from('profiles').upsert({
      'id': user.id,
      'full_name': metaName,
    });
  }
}
