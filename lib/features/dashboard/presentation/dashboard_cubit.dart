import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../exams/domain/exam_model.dart';
import '../../groups/domain/group_model.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_kpis.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardKpis kpis;
  final List<GroupModel> groups;
  final List<ExamModel> upcomingExams;
  final List<RecentActivityItem> recentActivities;

  List<RecentActivityItem> get activities => recentActivities;

  const DashboardLoaded({
    required this.kpis,
    required this.groups,
    required this.upcomingExams,
    required this.recentActivities,
  });

  @override
  List<Object?> get props => [kpis, groups, upcomingExams, recentActivities];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository _repository;

  DashboardCubit(this._repository) : super(DashboardInitial());

  Future<void> loadDashboard() async {
    emit(DashboardLoading());
    try {
      final results = await Future.wait([
        _repository.getKpis(),
        _repository.getTopGroups(),
        _repository.getUpcomingExams(),
        _repository.getRecentActivities(),
      ]);

      emit(DashboardLoaded(
        kpis: results[0] as DashboardKpis,
        groups: results[1] as List<GroupModel>,
        upcomingExams: results[2] as List<ExamModel>,
        recentActivities: results[3] as List<RecentActivityItem>,
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
