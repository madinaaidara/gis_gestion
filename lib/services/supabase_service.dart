import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_constants.dart';

class SupabaseService {
  static final SupabaseClient _client = SupabaseClient(
    SupabaseConstants.supabaseUrl,
    SupabaseConstants.supabaseAnonKey,
  );

  static SupabaseClient get instance => _client;

  // Authentification
  static User? get currentUser => _client.auth.currentUser;
  static String? get userId => _client.auth.currentUser?.id;
  static bool get isLoggedIn => _client.auth.currentUser != null;
}