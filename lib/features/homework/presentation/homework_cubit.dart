import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/homework_repository.dart';
import '../domain/homework_model.dart';
import '../domain/homework_record_model.dart';

abstract class HomeworkState extends Equatable {
  const HomeworkState();

  @override
  List<Object?> get props => [];
}

class HomeworkInitial extends HomeworkState {}

class HomeworkLoading extends HomeworkState {}

class HomeworkLoaded extends HomeworkState {
  final List<HomeworkModel> allHomeworks;
  final String? selectedGroupId;

  const HomeworkLoaded({
    required this.allHomeworks,
    this.selectedGroupId,
  });

  List<HomeworkModel> get homeworks => displayedHomeworks;

  List<HomeworkModel> get displayedHomeworks {
    if (selectedGroupId == null || selectedGroupId!.isEmpty) {
      return allHomeworks;
    }
    return allHomeworks.where((h) => h.groupId == selectedGroupId).toList();
  }

  HomeworkLoaded copyWith({
    List<HomeworkModel>? allHomeworks,
    String? selectedGroupId,
    bool clearGroupFilter = false,
  }) {
    return HomeworkLoaded(
      allHomeworks: allHomeworks ?? this.allHomeworks,
      selectedGroupId: clearGroupFilter ? null : (selectedGroupId ?? this.selectedGroupId),
    );
  }

  @override
  List<Object?> get props => [allHomeworks, selectedGroupId];
}

class HomeworkError extends HomeworkState {
  final String message;

  const HomeworkError(this.message);

  @override
  List<Object?> get props => [message];
}

class HomeworkCubit extends Cubit<HomeworkState> {
  final HomeworkRepository _repository;

  HomeworkCubit(this._repository) : super(HomeworkInitial());

  Future<void> loadHomeworks({String? groupId}) async {
    emit(HomeworkLoading());
    try {
      final homeworks = await _repository.getHomeworks(groupId: groupId);
      emit(HomeworkLoaded(allHomeworks: homeworks, selectedGroupId: groupId));
    } catch (e) {
      emit(HomeworkError(e.toString()));
    }
  }

  void filterGroup(String? groupId) {
    if (state is HomeworkLoaded) {
      final current = state as HomeworkLoaded;
      emit(current.copyWith(selectedGroupId: groupId, clearGroupFilter: groupId == null));
    }
  }

  Future<void> createHomework({
    required String gradeId,
    required String title,
    DateTime? dueDate,
  }) async {
    try {
      await _repository.createHomeworkWithRecords(
        groupId: gradeId,
        title: title,
        dueDate: dueDate,
        records: [],
      );
      await loadHomeworks(groupId: gradeId);
    } catch (e) {
      emit(HomeworkError(e.toString()));
    }
  }

  Future<void> saveHomework({
    String? homeworkId,
    required String groupId,
    String? lessonId,
    required String title,
    DateTime? dueDate,
    required List<Map<String, dynamic>> records,
  }) async {
    try {
      await _repository.saveHomeworkWithRecords(
        homeworkId: homeworkId,
        groupId: groupId,
        lessonId: lessonId,
        title: title,
        dueDate: dueDate,
        records: records,
      );
      await loadHomeworks(groupId: groupId);
    } catch (e) {
      emit(HomeworkError(e.toString()));
    }
  }

  Future<void> updateRecordStatus(String recordId, String status) async {
    try {
      await _repository.updateRecordStatus(recordId, status);
    } catch (e) {
      emit(HomeworkError(e.toString()));
    }
  }

  Future<void> deleteHomework(String homeworkId, [String? groupId]) async {
    try {
      await _repository.deleteHomework(homeworkId);
      await loadHomeworks(groupId: groupId);
    } catch (e) {
      emit(HomeworkError(e.toString()));
    }
  }

  Future<List<HomeworkRecordModel>> loadHomeworkRecords(String homeworkId) async {
    return await _repository.getHomeworkRecords(homeworkId);
  }

  Future<List<HomeworkRecordModel>> getHomeworkRecords(String homeworkId) async {
    return await _repository.getHomeworkRecords(homeworkId);
  }
}
