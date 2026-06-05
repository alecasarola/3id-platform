import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

// All route paths in one place — no magic strings scattered through the app.
abstract class AppRoute {
  static const login = '/login';
  static const register = '/register';

  // Nurse (infermiere) shell
  static const nurseShifts = '/nurse/shifts';
  static const nurseApplications = '/nurse/applications';
  static const nurseProfile = '/nurse/profile';

  // Facility (struttura) shell
  static const facilityShifts = '/facility/shifts';
  static const facilityPostShift = '/facility/post-shift';
  static const facilityProfile = '/facility/profile';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoute.login,
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      // TODO(step-2): implement role-based redirect using Supabase session.
      //   - unauthenticated → /login
      //   - role == nurse   → /nurse/shifts
      //   - role == facility → /facility/shifts
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoute.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoute.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Nurse shell (bottom navigation) ─────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => NurseShellScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoute.nurseShifts,
            name: 'nurseShifts',
            builder: (context, state) => const NurseShiftsScreen(),
          ),
          GoRoute(
            path: AppRoute.nurseApplications,
            name: 'nurseApplications',
            builder: (context, state) => const NurseApplicationsScreen(),
          ),
          GoRoute(
            path: AppRoute.nurseProfile,
            name: 'nurseProfile',
            builder: (context, state) => const NurseProfileScreen(),
          ),
        ],
      ),

      // ── Facility shell (bottom navigation) ──────────────────────────────
      ShellRoute(
        builder: (context, state, child) => FacilityShellScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoute.facilityShifts,
            name: 'facilityShifts',
            builder: (context, state) => const FacilityShiftsScreen(),
          ),
          GoRoute(
            path: AppRoute.facilityPostShift,
            name: 'facilityPostShift',
            builder: (context, state) => const FacilityPostShiftScreen(),
          ),
          GoRoute(
            path: AppRoute.facilityProfile,
            name: 'facilityProfile',
            builder: (context, state) => const FacilityProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
