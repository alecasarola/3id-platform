import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserRole { nurse, facility }

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.userId,
    this.role,
  });

  final AuthStatus status;
  final String? userId;
  final UserRole? role;

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    UserRole? role,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      role: role ?? this.role,
    );
  }
}

// TODO(step-2): replace with a real StreamProvider backed by
// Supabase.instance.client.auth.onAuthStateChange
final authStateProvider = StateProvider<AuthState>(
  (_) => const AuthState(status: AuthStatus.unauthenticated),
);
