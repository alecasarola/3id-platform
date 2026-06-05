import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:healthcare_marketplace/core/constants/app_constants.dart';
import 'package:healthcare_marketplace/core/errors/app_exception.dart';
import 'package:healthcare_marketplace/features/auth/domain/user_role.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(supa.Supabase.instance.client),
);

class AuthRepository {
  const AuthRepository(this._client);

  final supa.SupabaseClient _client;

  Stream<supa.AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  supa.Session? get currentSession => _client.auth.currentSession;

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on supa.AuthException catch (e) {
      throw AuthException(message: _localise(e.message), code: e.statusCode);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        // Role is picked up by the on_auth_user_created trigger
        // (supabase/migrations/001_profiles_table.sql) — no client INSERT needed.
        data: {'role': role.name},
      );
    } on supa.AuthException catch (e) {
      throw AuthException(message: _localise(e.message), code: e.statusCode);
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on supa.AuthException catch (e) {
      throw AuthException(message: e.message, code: e.statusCode);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on supa.AuthException catch (e) {
      throw AuthException(message: e.message, code: e.statusCode);
    }
  }

  Future<UserRole?> fetchUserRole(String userId) async {
    try {
      final row = await _client
          .from(AppConstants.tableProfiles)
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      final roleStr = row?['role'] as String?;
      return UserRole.values.where((r) => r.name == roleStr).firstOrNull;
    } on supa.PostgrestException catch (e) {
      throw NetworkException(message: e.message, code: e.code);
    }
  }

  String _localise(String msg) => switch (msg) {
    'Invalid login credentials' => 'Email o password non corretti.',
    'Email not confirmed'       => 'Conferma la tua email prima di accedere.',
    'User already registered'   => 'Esiste già un account con questa email.',
    _                           => msg,
  };
}
