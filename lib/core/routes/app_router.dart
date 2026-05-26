import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/exam/presentation/list_exam_screen.dart';
import '../../features/exam/presentation/take_exam_screen.dart';
import '../../features/exam/presentation/result_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/manage_users_screen.dart';
import '../../features/professor/presentation/prof_dashboard_screen.dart';
import '../../shared/models/result_model.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final userProfileAsync = ref.watch(userProfileProvider);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(authRepo.authStateChanges),
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';

      if (!isLoggedIn) {
        if (!isLoggingIn && !isRegistering) {
          return '/login';
        }
        return null;
      }

      if (isLoggingIn || isRegistering) {
        // If user profile isn't ready yet, don't redirect so provider can load
        final role = userProfileAsync.value?.role;
        if (role == null) return null;

        // Map role to landing routes (support legacy 'student')
        if (role == 'admin') return '/admin-dashboard';
        if (role == 'professores' || role.toLowerCase().contains('prof'))
          return '/prof-dashboard';
        return '/home';
      }

      // Protect admin/prof routes from estudiantes (students)
      final currentPath = state.subloc;
      final role = userProfileAsync.value?.role;
      if (role != null) {
        final isStudent =
            !(role == 'admin' ||
                role == 'professores' ||
                role.toLowerCase().contains('prof'));
        if (isStudent &&
            (currentPath.startsWith('/admin') ||
                currentPath.startsWith('/prof'))) {
          return '/home';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const ListExamScreen(),
      ),
      GoRoute(
        path: '/take-exam/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TakeExamScreen(examId: id);
        },
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) {
          final result = state.extra as ResultModel;
          return ResultScreen(result: result);
        },
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/manage-users',
        builder: (context, state) => const ManageUsersScreen(),
      ),
      GoRoute(
        path: '/prof-dashboard',
        builder: (context, state) => const ProfDashboardScreen(),
      ),
    ],
  );
});
