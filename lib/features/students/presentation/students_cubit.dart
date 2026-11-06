import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/students_repository.dart';
import '../domain/student_model.dart';

enum StudentSortColumn {
  name,
  code,
  attendance,
  homework,
  examAverage,
}

abstract class StudentsState extends Equatable {
  const StudentsState();

  @override
  List<Object?> get props => [];
}

class StudentsInitial extends StudentsState {}

class StudentsLoading extends StudentsState {}

class StudentsLoaded extends StudentsState {
  final List<StudentModel> allStudents;
  final String searchQuery;
  final String? statusFilter;
  final StudentSortColumn sortColumn;
  final bool isAscending;

  const StudentsLoaded({
    required this.allStudents,
    this.searchQuery = '',
    this.statusFilter,
    this.sortColumn = StudentSortColumn.name,
    this.isAscending = true,
  });

  List<StudentModel> get students => displayedStudents;

  List<StudentModel> get displayedStudents {
    var list = allStudents.where((s) {
      final matchesStatus = statusFilter == null || statusFilter!.isEmpty || s.status == statusFilter;
      final q = searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.studentCode.toLowerCase().contains(q) ||
          (s.phone != null && s.phone!.contains(q));
      return matchesStatus && matchesSearch;
    }).toList();

    list.sort((a, b) {
      int comparison = 0;
      switch (sortColumn) {
        case StudentSortColumn.name:
          comparison = a.name.compareTo(b.name);
          break;
        case StudentSortColumn.code:
          comparison = a.studentCode.compareTo(b.studentCode);
          break;
        case StudentSortColumn.attendance:
          comparison = a.attendanceRate.compareTo(b.attendanceRate);
          break;
        case StudentSortColumn.homework:
          comparison = a.homeworkRate.compareTo(b.homeworkRate);
          break;
        case StudentSortColumn.examAverage:
          comparison = a.examAverage.compareTo(b.examAverage);
          break;
      }
      return isAscending ? comparison : -comparison;
    });

    return list;
  }

  StudentsLoaded copyWith({
    List<StudentModel>? allStudents,
    String? searchQuery,
    String? statusFilter,
    StudentSortColumn? sortColumn,
    bool? isAscending,
    bool clearStatusFilter = false,
  }) {
    return StudentsLoaded(
      allStudents: allStudents ?? this.allStudents,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      sortColumn: sortColumn ?? this.sortColumn,
      isAscending: isAscending ?? this.isAscending,
    );
  }

  @override
  List<Object?> get props => [allStudents, searchQuery, statusFilter, sortColumn, isAscending];
}

class StudentsError extends StudentsState {
  final String message;

  const StudentsError(this.message);

  @override
  List<Object?> get props => [message];
}

class StudentsCubit extends Cubit<StudentsState> {
  final StudentsRepository _repository;
  String? _currentGroupId;
  String? _currentGradeId;

  StudentsCubit(this._repository) : super(StudentsInitial());

  String? get currentGroupId => _currentGroupId;
  String? get currentGradeId => _currentGradeId;

  Future<void> loadStudents([String? groupId, String? gradeId]) async {
    _currentGroupId = groupId;
    _currentGradeId = gradeId;
    emit(StudentsLoading());
    try {
      final students = await _repository.getStudents(groupId: groupId, gradeId: gradeId);
      emit(StudentsLoaded(allStudents: students));
    } catch (e) {
      emit(StudentsError(e.toString()));
    }
  }

  void search(String query) {
    if (state is StudentsLoaded) {
      final current = state as StudentsLoaded;
      emit(current.copyWith(searchQuery: query));
    }
  }

  void sort(StudentSortColumn column) {
    if (state is StudentsLoaded) {
      final current = state as StudentsLoaded;
      final isAsc = current.sortColumn == column ? !current.isAscending : true;
      emit(current.copyWith(sortColumn: column, isAscending: isAsc));
    }
  }

  void filterStatus(String? status) {
    if (state is StudentsLoaded) {
      final current = state as StudentsLoaded;
      emit(current.copyWith(statusFilter: status, clearStatusFilter: status == null));
    }
  }

  Future<void> addStudent({
    required String name,
    String? gradeId,
    String? groupId,
    String? phone,
    String? parentPhone,
    String? email,
  }) async {
    final targetGradeId = (gradeId != null && gradeId.isNotEmpty)
        ? gradeId
        : ((groupId != null && groupId.isNotEmpty) ? groupId : (_currentGradeId ?? _currentGroupId ?? ''));

    try {
      await _repository.createStudent(
        name: name,
        gradeId: targetGradeId,
        groupId: targetGradeId,
        phone: phone,
        parentPhone: parentPhone,
        email: email,
      );
      await loadStudents(targetGradeId, targetGradeId);
    } catch (e) {
      debugPrint('[StudentsCubit] addStudent error: $e');
      emit(StudentsError(e.toString()));
      rethrow;
    }
  }

  Future<void> updateStudent({
    required String studentId,
    String? name,
    String? gradeId,
    String? groupId,
    String? phone,
    String? parentPhone,
    String? email,
    String? status,
  }) async {
    try {
      await _repository.updateStudent(
        studentId: studentId,
        name: name,
        gradeId: gradeId,
        groupId: groupId,
        phone: phone,
        parentPhone: parentPhone,
        email: email,
        status: status,
      );
      await loadStudents(_currentGroupId, _currentGradeId);
    } catch (e) {
      emit(StudentsError(e.toString()));
    }
  }

  Future<void> removeStudent(String studentId) async {
    await deleteStudent(studentId);
  }

  Future<void> deleteStudent(String studentId) async {
    // 1. Optimistic update: remove student from UI immediately
    List<StudentModel>? previousList;
    if (state is StudentsLoaded) {
      final current = state as StudentsLoaded;
      previousList = current.allStudents;
      final updatedList = current.allStudents.where((s) => s.id != studentId).toList();
      emit(current.copyWith(allStudents: updatedList));
    }

    try {
      await _repository.deleteStudent(studentId);
      // Synchronize with database
      await loadStudents(_currentGroupId, _currentGradeId);
    } catch (e) {
      debugPrint('[StudentsCubit] deleteStudent error: $e');
      if (previousList != null && state is StudentsLoaded) {
        emit((state as StudentsLoaded).copyWith(allStudents: previousList));
      }
      emit(StudentsError(e.toString()));
      rethrow;
    }
  }
}
