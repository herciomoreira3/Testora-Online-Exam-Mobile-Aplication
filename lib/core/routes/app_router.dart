import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/admin_exams_screen.dart';
import '../../features/admin/presentation/admin_reports_screen.dart';
import '../../features/admin/presentation/manage_subjects_screen.dart';
import '../../features/admin/presentation/manage_users_screen.dart';
import '../../features/alerts/presentation/alerts_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/exam/presentation/list_exam_screen.dart';
import '../../features/exam/presentation/result_screen.dart';
import '../../features/exam/presentation/take_exam_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/professor/presentation/create_exam_screen.dart';
import '../../features/professor/presentation/manage_questions_screen.dart';
import '../../features/professor/presentation/prof_dashboard_screen.dart';
import '../../features/professor/presentation/professor_exams_screen.dart';
import '../../features/professor/presentation/teacher_results_screen.dart';
import '../../features/professor/presentation/teacher_students_screen.dart';
import '../../features/professor/presentation/view_results_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../shared/models/result_model.dart';
import '../widgets/main_scaffold.dart';

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

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authRepo.authStateChanges),
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final userProfileAsync = ref.read(userProfileProvider);
      final isLoggedIn = authRepo.currentUid != null || authState.value != null;
      final location = state.matchedLocation;
      final isSplash = location == '/splash';
      final isLoggingIn = location == '/login';
      final isRegistering = location == '/register';

      if (isSplash) return null;

      if (!isLoggedIn) {
        if (!isLoggingIn && !isRegistering) return '/login';
        return null;
      }

      if (isLoggingIn || isRegistering) {
        if (userProfileAsync.isLoading) return null;
        final role = userProfileAsync.value?.role ?? '';
        if (role == 'admin') return '/admin-dashboard';
        if (role == 'teacher') return '/prof-dashboard';
        if (role == 'student') return '/home';
        return null;
      }

      if (userProfileAsync.isLoading) return null;
      final role = userProfileAsync.value?.role ?? '';
      if (role.isEmpty) {
        return '/login';
      }
      if (role.isNotEmpty) {
        final isAdmin = role == 'admin';
        final isTeacher = role == 'teacher';
        final isStudent = !(isAdmin || isTeacher);

        if (isStudent &&
            (location.startsWith('/admin') || location.startsWith('/prof'))) {
          return '/home';
        }

        if (isTeacher &&
            (location == '/home' ||
                location.startsWith('/history') ||
                location.startsWith('/admin'))) {
          return '/prof-dashboard';
        }

        if (isAdmin &&
            (location == '/home' ||
                location.startsWith('/history') ||
                location.startsWith('/prof'))) {
          return '/admin-dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
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
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const ListExamScreen(),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/alerts',
            builder: (context, state) => const AlertsScreen(),
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
            path: '/admin/manage-subjects',
            builder: (context, state) => const ManageSubjectsScreen(),
          ),
          GoRoute(
            path: '/admin/exams',
            builder: (context, state) => const AdminExamsScreen(),
          ),
          GoRoute(
            path: '/admin/exams/create',
            builder: (context, state) => const CreateExamScreen(),
          ),
          GoRoute(
            path: '/admin/exams/:examId/edit',
            builder: (context, state) {
              final examId = state.pathParameters['examId']!;
              return CreateExamScreen(examId: examId);
            },
          ),
          GoRoute(
            path: '/admin/exams/:examId/manage-questions',
            builder: (context, state) {
              final examId = state.pathParameters['examId']!;
              return ManageQuestionsScreen(examId: examId);
            },
          ),
          GoRoute(
            path: '/admin/exams/:examId/results',
            builder: (context, state) {
              final examId = state.pathParameters['examId']!;
              return ViewResultsScreen(examId: examId);
            },
          ),
          GoRoute(
            path: '/admin/reports',
            builder: (context, state) => const AdminReportsScreen(),
          ),
          GoRoute(
            path: '/prof-dashboard',
            builder: (context, state) => const ProfDashboardScreen(),
          ),
          GoRoute(
            path: '/prof-dashboard/students',
            builder: (context, state) => const TeacherStudentsScreen(),
          ),
          GoRoute(
            path: '/prof-dashboard/exams',
            builder: (context, state) => const ProfessorExamsScreen(),
          ),
          GoRoute(
            path: '/prof-dashboard/exams/create',
            builder: (context, state) => const CreateExamScreen(),
          ),
          GoRoute(
            path: '/prof-dashboard/results',
            builder: (context, state) => const TeacherResultsScreen(),
          ),
          GoRoute(
            path: '/prof-dashboard/exam/:examId/edit',
            builder: (context, state) {
              final examId = state.pathParameters['examId']!;
              return CreateExamScreen(examId: examId);
            },
          ),
          GoRoute(
            path: '/prof-dashboard/exam/:examId/manage-questions',
            builder: (context, state) {
              final examId = state.pathParameters['examId']!;
              return ManageQuestionsScreen(examId: examId);
            },
          ),
          GoRoute(
            path: '/prof-dashboard/exam/:examId/results',
            builder: (context, state) {
              final examId = state.pathParameters['examId']!;
              return ViewResultsScreen(examId: examId);
            },
          ),
        ],
      ),
    ],
  );
});
