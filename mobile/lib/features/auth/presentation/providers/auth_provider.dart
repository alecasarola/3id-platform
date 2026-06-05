import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:healthcare_marketplace/features/auth/data/auth_repository.dart';
import 'package:healthcare_marketplace/features/auth/domain/user_role.dart';

export 'package:healthcare_marketplace/features/auth/domain/user_role.dart';

// ── Domain model ──────────────────────────────────────────────────────────────

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AppAuthState {
  const AppAuthState({
    this.status = AuthStatus.initial,
    this.userId,
    this.role,
  });

  final AuthStatus status;
  final String? userId;
  final UserRole? role;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isNurse => role == UserRole.nurse;
  bool get isFacility => role == UserRole.facility;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AppAuthState>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<AppAuthState> {
  @override
  Future<AppAuthState> build() async {
    final repo = ref.read(authRepositoryProvider);

    // Keep the Supabase auth stream alive for the notifier's lifetime.
    final sub = repo.authStateChanges.listen(_onSupabaseAuthChange);
    ref.onDispose(sub.cancel);

    // Initial state from persisted session (survives app restarts).
    final session = repo.currentSession;
    if (session == null) {
      return const AppAuthState(status: AuthStatus.unauthenticated);
    }
    final role = await repo.fetchUserRole(session.user.id);
    return AppAuthState(
      status: AuthStatus.authenticated,
      userId: session.user.id,
      role: role,
    );
  }

  // ── Stream listener ──────────────────────────────────────────────────────

  void _onSupabaseAuthChange(supa.AuthState event) {
    final user = event.session?.user;
    if (user == null) {
      state = const AsyncData(AppAuthState(status: AuthStatus.unauthenticated));
    } else {
      _resolveAuthenticatedState(user.id);
    }
  }

  Future<void> _resolveAuthenticatedState(String userId) async {
    try {
      final role = await ref.read(authRepositoryProvider).fetchUserRole(userId);
      state = AsyncData(AppAuthState(
        status: AuthStatus.authenticated,
        userId: userId,
        role: role,
      ));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // ── Public actions ───────────────────────────────────────────────────────

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithEmailPassword(email: email, password: password);
      // State updated via _onSupabaseAuthChange stream.
    } catch (e, st) {
      state = const AsyncData(AppAuthState(status: AuthStatus.unauthenticated));
      Error.throwWithStackTrace(e, st); // UI catches to show SnackBar
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signUp(
        email: email,
        password: password,
        role: role,
      );
      // If email confirmation is required, Supabase returns a user but no
      // session — stream won't fire. Reset to unauthenticated so the UI can
      // show a "confirm your email" message.
      state = const AsyncData(AppAuthState(status: AuthStatus.unauthenticated));
    } catch (e, st) {
      state = const AsyncData(AppAuthState(status: AuthStatus.unauthenticated));
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    // State updated via stream.
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
  }
}
