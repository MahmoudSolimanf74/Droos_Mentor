import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/academic/presentation/academic_hub_screen.dart';
import '../../features/auth/presentation/auth_cubit.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/exams/presentation/create_exam_manual_screen.dart';
import '../../features/exams/presentation/exam_import_json_screen.dart';
import '../../features/exams/presentation/exam_results_screen.dart';
import '../../features/grades/presentation/grades_and_students_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/sql_schema_viewer_screen.dart';
import '../../features/settings/presentation/supabase_setup_screen.dart';
import '../../features/students/presentation/student_details_screen.dart';
import '../widgets/app_scaffold.dart';
import 'route_names.dart';

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(AuthCubit cubit) {
    cubit.stream.listen((_) => notifyListeners());
  }
}

class AppRouter {
  final AuthCubit authCubit;

  AppRouter(this.authCubit);

  late final GoRouter router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthRefreshListenable(authCubit),
    errorBuilder: (context, state) => const SplashScreen(),
    redirect: (context, state) {
      final authState = authCubit.state;
      final isLogin = state.matchedLocation == '/login';
      final isSplash = state.matchedLocation == '/splash' ||
          state.matchedLocation == '/' ||
          state.matchedLocation == '/login-callback';

      if (authState is AuthInitial || authState is AuthLoading) {
        return null;
      }

      if (authState is Authenticated) {
        if (isLogin || isSplash) {
          return '/dashboard';
        }
      }

      if (authState is Unauthenticated ||
          authState is AuthRoleUnauthorized ||
          authState is AuthError) {
        if (!isLogin && !isSplash) {
          return '/login';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/splash',
      ),
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/login-callback',
        name: RouteNames.loginCallback,
        builder: (context, state) => const SplashScreen(),
      ),

      // Protected 4-Branch Navigation Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard (الداش بورد)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                name: RouteNames.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),

          // Branch 1: Groups & Students & QR (المجموعات والطلاب)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/groups',
                name: RouteNames.groups,
                builder: (context, state) {
                  final initialGradeId = state.uri.queryParameters['gradeId'];
                  return GradesAndStudentsScreen(initialGradeId: initialGradeId);
                },
                routes: [
                  GoRoute(
                    path: 'students/:studentId',
                    name: RouteNames.studentDetails,
                    builder: (context, state) {
                      final studentId = state.pathParameters['studentId'] ?? '';
                      return StudentDetailsScreen(
                        groupId: '1',
                        studentId: studentId,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 2: Academic Center (إدارة الدروس والتعليم: منهج، امتحانات، حضور، واجبات، أداء)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/academic',
                name: RouteNames.academic,
                builder: (context, state) {
                  final tabStr = state.uri.queryParameters['tab'];
                  final tabIdx = int.tryParse(tabStr ?? '0') ?? 0;
                  return AcademicHubScreen(initialTabIndex: tabIdx);
                },
                routes: [
                  GoRoute(
                    path: 'exam-import-json',
                    name: RouteNames.examImportJson,
                    builder: (context, state) => const ExamImportJsonScreen(),
                  ),
                  GoRoute(
                    path: 'exam-create-manual',
                    name: RouteNames.examCreateManual,
                    builder: (context, state) {
                      final gradeId = state.uri.queryParameters['gradeId'];
                      return CreateExamManualScreen(initialGradeId: gradeId);
                    },
                  ),
                  GoRoute(
                    path: 'exam-results/:examId',
                    name: RouteNames.examResults,
                    builder: (context, state) {
                      final examId = state.pathParameters['examId'] ?? '';
                      return ExamResultsScreen(examId: examId);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 3: Settings (الإعدادات)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: RouteNames.settings,
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'supabase-setup',
                    name: RouteNames.supabaseSetup,
                    builder: (context, state) => const SupabaseSetupScreen(),
                  ),
                  GoRoute(
                    path: 'sql-schema',
                    name: RouteNames.sqlSchema,
                    builder: (context, state) => const SqlSchemaViewerScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
