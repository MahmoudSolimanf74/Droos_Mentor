import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/attendance_repository.dart';
import '../domain/attendance_record_model.dart';
import '../domain/attendance_session_model.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class AttendanceLoaded extends AttendanceState {
  final List<AttendanceSessionModel> allSessions;
  final String? selectedGroupId;

  const AttendanceLoaded({
    required this.allSessions,
    this.selectedGroupId,
  });

  List<AttendanceSessionModel> get sessions => displayedSessions;

  List<AttendanceSessionModel> get displayedSessions {
    if (selectedGroupId == null || selectedGroupId!.isEmpty) {
      return allSessions;
    }
    return allSessions.where((s) => s.groupId == selectedGroupId).toList();
  }

  AttendanceLoaded copyWith({
    List<AttendanceSessionModel>? allSessions,
    String? selectedGroupId,
    bool clearGroupFilter = false,
  }) {
    return AttendanceLoaded(
      allSessions: allSessions ?? this.allSessions,
      selectedGroupId: clearGroupFilter ? null : (selectedGroupId ?? this.selectedGroupId),
    );
  }

  @override
  List<Object?> get props => [allSessions, selectedGroupId];
}

class AttendanceError extends AttendanceState {
  final String message;

  const AttendanceError(this.message);

  @override
  List<Object?> get props => [message];
}

class AttendanceCubit extends Cubit<AttendanceState> {
  final AttendanceRepository _repository;

  AttendanceCubit(this._repository) : super(AttendanceInitial());

  Future<void> loadSessions({String? groupId}) async {
    emit(AttendanceLoading());
    try {
      final sessions = await _repository.getSessions(groupId: groupId);
      emit(AttendanceLoaded(allSessions: sessions, selectedGroupId: groupId));
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }

  void filterGroup(String? groupId) {
    if (state is AttendanceLoaded) {
      final current = state as AttendanceLoaded;
      emit(current.copyWith(selectedGroupId: groupId, clearGroupFilter: groupId == null));
    }
  }

  Future<void> saveAttendanceSession({
    required String groupId,
    required String title,
    required DateTime sessionDate,
    required List<Map<String, dynamic>> records,
  }) async {
    return saveAttendance(
      groupId: groupId,
      title: title,
      sessionDate: sessionDate,
      records: records,
    );
  }

  Future<void> createSession({
    required String gradeId,
    required String lessonTitle,
    required DateTime sessionDate,
  }) async {
    try {
      await _repository.createSessionWithRecords(
        groupId: gradeId,
        title: lessonTitle,
        sessionDate: sessionDate,
        records: [],
      );
      await loadSessions(groupId: gradeId);
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }

  Future<void> saveAttendance({
    String? sessionId,
    required String groupId,
    required String title,
    required DateTime sessionDate,
    required List<Map<String, dynamic>> records,
  }) async {
    try {
      await _repository.saveSessionWithRecords(
        sessionId: sessionId,
        groupId: groupId,
        title: title,
        sessionDate: sessionDate,
        records: records,
      );
      await loadSessions(groupId: groupId);
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }

  Future<void> updateRecordStatus(String recordId, String status) async {
    try {
      await _repository.updateRecordStatus(recordId, status);
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }

  Future<void> deleteSession(String sessionId, [String? groupId]) async {
    try {
      await _repository.deleteSession(sessionId);
      await loadSessions(groupId: groupId);
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }

  Future<List<AttendanceRecordModel>> loadSessionRecords(String sessionId) async {
    return await _repository.getSessionRecords(sessionId);
  }

  Future<List<AttendanceRecordModel>> getSessionRecords(String sessionId) async {
    return await _repository.getSessionRecords(sessionId);
  }
}
