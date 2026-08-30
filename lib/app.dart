import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/attendance/data/attendance_repository.dart';
import 'features/attendance/presentation/attendance_cubit.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_cubit.dart';
import 'features/curriculum/data/curriculum_repository.dart';
import 'features/curriculum/presentation/curriculum_cubit.dart';
import 'features/dashboard/data/dashboard_repository.dart';
import 'features/dashboard/presentation/dashboard_cubit.dart';
import 'features/exams/data/exams_repository.dart';
import 'features/exams/presentation/exams_cubit.dart';
import 'features/grades/data/grades_repository.dart';
import 'features/grades/presentation/grades_cubit.dart';
import 'features/groups/data/groups_repository.dart';
import 'features/groups/presentation/groups_cubit.dart';
import 'features/homework/data/homework_repository.dart';
import 'features/homework/presentation/homework_cubit.dart';
import 'features/students/data/students_repository.dart';
import 'features/students/presentation/students_cubit.dart';

class ClassPilotTeacherApp extends StatefulWidget {
  const ClassPilotTeacherApp({super.key});

  @override
  State<ClassPilotTeacherApp> createState() => _ClassPilotTeacherAppState();
}

class _ClassPilotTeacherAppState extends State<ClassPilotTeacherApp> {
  late final AuthRepository _authRepository;
  late final GradesRepository _gradesRepository;
  late final GroupsRepository _groupsRepository;
  late final StudentsRepository _studentsRepository;
  late final CurriculumRepository _curriculumRepository;
  late final ExamsRepository _examsRepository;
  late final AttendanceRepository _attendanceRepository;
  late final HomeworkRepository _homeworkRepository;
  late final DashboardRepository _dashboardRepository;

  late final AuthCubit _authCubit;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepositoryImpl();
    _gradesRepository = GradesRepositoryImpl();
    _groupsRepository = GroupsRepositoryImpl();
    _studentsRepository = StudentsRepositoryImpl();
    _curriculumRepository = CurriculumRepositoryImpl();
    _examsRepository = ExamsRepositoryImpl();
    _attendanceRepository = AttendanceRepositoryImpl();
    _homeworkRepository = HomeworkRepositoryImpl();
    _dashboardRepository = DashboardRepositoryImpl();

    _authCubit = AuthCubit(_authRepository);
    _appRouter = AppRouter(_authCubit);
  }

  @override
  void dispose() {
    _authCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: _authRepository),
        RepositoryProvider<GradesRepository>.value(value: _gradesRepository),
        RepositoryProvider<GroupsRepository>.value(value: _groupsRepository),
        RepositoryProvider<StudentsRepository>.value(value: _studentsRepository),
        RepositoryProvider<CurriculumRepository>.value(value: _curriculumRepository),
        RepositoryProvider<ExamsRepository>.value(value: _examsRepository),
        RepositoryProvider<AttendanceRepository>.value(value: _attendanceRepository),
        RepositoryProvider<HomeworkRepository>.value(value: _homeworkRepository),
        RepositoryProvider<DashboardRepository>.value(value: _dashboardRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: _authCubit),
          BlocProvider<GradesCubit>(
            create: (ctx) => GradesCubit(_gradesRepository),
          ),
          BlocProvider<GroupsCubit>(
            create: (ctx) => GroupsCubit(_groupsRepository),
          ),
          BlocProvider<StudentsCubit>(
            create: (ctx) => StudentsCubit(_studentsRepository),
          ),
          BlocProvider<CurriculumCubit>(
            create: (ctx) => CurriculumCubit(_curriculumRepository),
          ),
          BlocProvider<ExamsCubit>(
            create: (ctx) => ExamsCubit(_examsRepository),
          ),
          BlocProvider<AttendanceCubit>(
            create: (ctx) => AttendanceCubit(_attendanceRepository),
          ),
          BlocProvider<HomeworkCubit>(
            create: (ctx) => HomeworkCubit(_homeworkRepository),
          ),
          BlocProvider<DashboardCubit>(
            create: (ctx) => DashboardCubit(_dashboardRepository),
          ),
        ],
        child: MaterialApp.router(
          title: AppConfig.appArabicName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          routerConfig: _appRouter.router,
          locale: const Locale('ar', 'EG'),
          supportedLocales: const [
            Locale('ar', 'EG'),
            Locale('ar'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}
