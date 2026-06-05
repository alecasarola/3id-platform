import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:healthcare_marketplace/features/auth/presentation/providers/auth_provider.dart';
import 'package:healthcare_marketplace/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:healthcare_marketplace/features/auth/presentation/screens/login_screen.dart';
import 'package:healthcare_marketplace/features/auth/presentation/screens/register_screen.dart';
import 'package:healthcare_marketplace/features/facility/presentation/screens/facility_post_shift_screen.dart';
import 'package:healthcare_marketplace/features/facility/presentation/screens/facility_profile_screen.dart';
import 'package:healthcare_marketplace/features/facility/presentation/screens/facility_shell_screen.dart';
import 'package:healthcare_marketplace/features/facility/presentation/screens/facility_shifts_screen.dart';
import 'package:healthcare_marketplace/features/nurse/presentation/screens/nurse_applications_screen.dart';
import 'package:healthcare_marketplace/features/nurse/presentation/screens/nurse_profile_screen.dart';
import 'package:healthcare_marketplace/features/nurse/presentation/screens/nurse_shell_screen.dart';
import 'package:healthcare_marketplace/features/nurse/presentation/screens/nurse_shifts_screen.dart';

// ── Route paths ───────────────────────────────────────────────────────────────

abstract class AppRoute {
  static const login          = '/login';
  static const register       = '/register';
  static const forgotPassword = '/forgot-password';

  // Infermiere
  static const nurseShifts       = '/nurse/shifts';
  static const nurseApplications = '/nurse/applications';
  static const nurseProfile      = '/nurse/profile';

  // Struttura
  static const facilityShifts    = '/facility/shifts';
  static const facilityPostShift = '/facility/post-shift';
  static const facilityProfile   = '/facility/profile';

  static const Set<String> _authPages = {login, register, forgotPassword};
  static bool isAuthPage(String location) => _authPages.contains(location);
}

// ── RouterNotifier ────────────────────────────────────────────────────────────
// Bridges Riverpod auth state changes to go_router's refreshListenable,
// so the router re-evaluates its redirect whenever auth changes.

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(authNotifierProvider, (_, __) => notifyListeners());
  }
}

// ── Router provider ───────────────────────────────────────────────────────────

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  final router = GoRouter(
    initialLocation: AppRoute.login,
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authAsync = ref.read(authNotifierProvider);
      final location  = state.matchedLocation;

      return authAsync.when(
        // Don't redirect while loading — let current route stay.
        loading: () => null,
        error: (_, __) => AppRoute.isAuthPage(location) ? null : AppRoute.login,
        data: (auth) {
          if (!auth.isAuthenticated) {
            // Unauthenticated: allow only auth pages.
            return AppRoute.isAuthPage(location) ? null : AppRoute.login;
          }
          // Authenticated: bounce away from auth pages to role home.
          if (AppRoute.isAuthPage(location)) {
            return auth.isNurse
                ? AppRoute.nurseShifts
                : AppRoute.facilityShifts;
          }
          return null;
        },
      );
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoute.login,
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoute.register,
        name: 'register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoute.forgotPassword,
        name: 'forgotPassword',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),

      // ── Infermiere shell (bottom navigation) ─────────────────────────────
      ShellRoute(
        builder: (_, __, child) => NurseShellScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoute.nurseShifts,
            name: 'nurseShifts',
            builder: (_, __) => const NurseShiftsScreen(),
          ),
          GoRoute(
            path: AppRoute.nurseApplications,
            name: 'nurseApplications',
            builder: (_, __) => const NurseApplicationsScreen(),
          ),
          GoRoute(
            path: AppRoute.nurseProfile,
            name: 'nurseProfile',
            builder: (_, __) => const NurseProfileScreen(),
          ),
        ],
      ),

      // ── Struttura shell (bottom navigation) ──────────────────────────────
      ShellRoute(
        builder: (_, __, child) => FacilityShellScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoute.facilityShifts,
            name: 'facilityShifts',
            builder: (_, __) => const FacilityShiftsScreen(),
          ),
          GoRoute(
            path: AppRoute.facilityPostShift,
            name: 'facilityPostShift',
            builder: (_, __) => const FacilityPostShiftScreen(),
          ),
          GoRoute(
            path: AppRoute.facilityProfile,
            name: 'facilityProfile',
            builder: (_, __) => const FacilityProfileScreen(),
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    notifier.dispose();
    router.dispose();
  });

  return router;
});
