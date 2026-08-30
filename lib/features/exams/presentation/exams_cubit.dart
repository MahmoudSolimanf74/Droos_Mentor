import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/json_validator.dart';
import '../data/exams_repository.dart';
import '../domain/exam_attempt_model.dart';
import '../domain/exam_model.dart';
import '../domain/exam_question_model.dart';

abstract class ExamsState extends Equatable {
  const ExamsState();

  @override
  List<Object?> get props => [];
}

class ExamsInitial extends ExamsState {}

class ExamsLoading extends ExamsState {}

class ExamsLoaded extends ExamsState {
  final List<ExamModel> allExams;
  final String? selectedGradeId;
  final String? statusFilter; // 'active', 'upcoming', 'ended'
  final String searchQuery;

  const ExamsLoaded({
    required this.allExams,
    this.selectedGradeId,
    this.statusFilter,
    this.searchQuery = '',
  });

  List<ExamModel> get exams => displayedExams;

  List<ExamModel> get displayedExams {
    return allExams.where((e) {
      final matchesGrade = selectedGradeId == null || selectedGradeId!.isEmpty || e.gradeId == selectedGradeId;
      final matchesSearch = searchQuery.isEmpty ||
          e.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          e.gradeName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (e.lessonTitle != null && e.lessonTitle!.toLowerCase().contains(searchQuery.toLowerCase()));

      bool matchesStatus = true;
      if (statusFilter == 'active') {
        matchesStatus = e.isOngoing;
      } else if (statusFilter == 'upcoming') {
        matchesStatus = e.isUpcoming;
      } else if (statusFilter == 'ended') {
        matchesStatus = e.isEnded;
      }

      return matchesGrade && matchesSearch && matchesStatus;
    }).toList();
  }

  ExamsLoaded copyWith({
    List<ExamModel>? allExams,
    String? selectedGradeId,
    String? statusFilter,
    String? searchQuery,
    bool clearGradeFilter = false,
    bool clearStatusFilter = false,
  }) {
    return ExamsLoaded(
      allExams: allExams ?? this.allExams,
      selectedGradeId: clearGradeFilter ? null : (selectedGradeId ?? this.selectedGradeId),
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [allExams, selectedGradeId, statusFilter, searchQuery];
}

class ExamImportValidationSuccess extends ExamsState {
  final ExamParsed parsedExam;

  const ExamImportValidationSuccess(this.parsedExam);

  @override
  List<Object?> get props => [parsedExam];
}

class ExamImportValidationError extends ExamsState {
  final List<String> errorList;

  const ExamImportValidationError(this.errorList);

  @override
  List<Object?> get props => [errorList];
}

class ExamsError extends ExamsState {
  final String message;

  const ExamsError(this.message);

  @override
  List<Object?> get props => [message];
}

class ExamsCubit extends Cubit<ExamsState> {
  final ExamsRepository _repository;

  ExamsCubit(this._repository) : super(ExamsInitial());

  Future<void> loadExams({String? gradeId, String? groupId}) async {
    emit(ExamsLoading());
    try {
      final exams = await _repository.getExams(gradeId: gradeId, groupId: groupId);
      emit(ExamsLoaded(allExams: exams, selectedGradeId: gradeId));
    } catch (e) {
      emit(ExamsError(e.toString()));
    }
  }

  void filterGrade(String? gradeId) {
    if (state is ExamsLoaded) {
      final current = state as ExamsLoaded;
      emit(current.copyWith(selectedGradeId: gradeId, clearGradeFilter: gradeId == null));
    }
  }

  void filterStatus(String? status) {
    if (state is ExamsLoaded) {
      final current = state as ExamsLoaded;
      emit(current.copyWith(statusFilter: status, clearStatusFilter: status == null));
    }
  }

  void searchExams(String query) {
    if (state is ExamsLoaded) {
      final current = state as ExamsLoaded;
      emit(current.copyWith(searchQuery: query));
    }
  }

  JsonValidationResult validateExamJson(String rawJson) {
    final result = JsonExamValidator.validate(rawJson);
    return result;
  }

  Future<void> createExam({
    required String gradeId,
    String? lessonId,
    required String title,
    required int durationMinutes,
    DateTime? startAt,
    DateTime? endAt,
    required List<Map<String, dynamic>> questions,
  }) async {
    try {
      await _repository.createExamWithQuestions(
        gradeId: gradeId,
        lessonId: lessonId,
        title: title,
        durationMinutes: durationMinutes,
        startAt: startAt,
        endAt: endAt,
        questions: questions,
      );
      await loadExams();
    } catch (e) {
      emit(ExamsError(e.toString()));
    }
  }

  Future<void> deleteExam(String examId) async {
    try {
      await _repository.deleteExam(examId);
      await loadExams();
    } catch (e) {
      emit(ExamsError(e.toString()));
    }
  }

  Future<void> toggleActive(String examId, bool isActive) async {
    try {
      await _repository.toggleExamActive(examId, isActive);
      await loadExams();
    } catch (e) {
      emit(ExamsError(e.toString()));
    }
  }

  Future<void> updateExam({
    required String examId,
    String? title,
    int? durationMinutes,
    bool? isActive,
    String? gradeId,
    List<Map<String, dynamic>>? questions,
  }) async {
    try {
      await _repository.updateExam(
        examId: examId,
        title: title,
        durationMinutes: durationMinutes,
        isActive: isActive,
        gradeId: gradeId,
        questions: questions,
      );
      await loadExams();
    } catch (e) {
      emit(ExamsError(e.toString()));
    }
  }

  Future<List<ExamAttemptModel>> loadExamAttempts(String examId) async {
    return await _repository.getExamAttempts(examId);
  }

  Future<List<ExamAttemptModel>> getExamResults(String examId) async {
    return await _repository.getExamAttempts(examId);
  }

  Future<List<ExamQuestionModel>> getExamQuestions(String examId) async {
    return await _repository.getExamQuestions(examId);
  }
}
