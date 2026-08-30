import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/grades_repository.dart';
import '../domain/grade_model.dart';

abstract class GradesState extends Equatable {
  const GradesState();
  @override
  List<Object?> get props => [];
}

class GradesInitial extends GradesState {
  const GradesInitial();
}

class GradesLoading extends GradesState {
  const GradesLoading();
}

class GradesLoaded extends GradesState {
  final List<GradeModel> grades;
  final String? selectedGradeId;

  const GradesLoaded({
    required this.grades,
    this.selectedGradeId,
  });

  GradeModel? get selectedGrade {
    if (selectedGradeId == null || grades.isEmpty) return grades.isNotEmpty ? grades.first : null;
    try {
      return grades.firstWhere((g) => g.id == selectedGradeId);
    } catch (_) {
      return grades.isNotEmpty ? grades.first : null;
    }
  }

  GradesLoaded copyWith({
    List<GradeModel>? grades,
    String? selectedGradeId,
  }) {
    return GradesLoaded(
      grades: grades ?? this.grades,
      selectedGradeId: selectedGradeId ?? this.selectedGradeId,
    );
  }

  @override
  List<Object?> get props => [grades, selectedGradeId];
}

class GradesError extends GradesState {
  final String message;
  const GradesError(this.message);

  @override
  List<Object?> get props => [message];
}

class GradesCubit extends Cubit<GradesState> {
  final GradesRepository _repository;

  GradesCubit(this._repository) : super(const GradesInitial());

  Future<void> loadGrades({String? preselectGradeId}) async {
    emit(const GradesLoading());
    try {
      final grades = await _repository.getGrades();
      final selectedId = preselectGradeId ?? (grades.isNotEmpty ? grades.first.id : null);
      emit(GradesLoaded(grades: grades, selectedGradeId: selectedId));
    } catch (e) {
      emit(GradesError(e.toString()));
    }
  }

  void selectGrade(String gradeId) {
    if (state is GradesLoaded) {
      emit((state as GradesLoaded).copyWith(selectedGradeId: gradeId));
    }
  }

  Future<void> createGrade({
    required String name,
    required String code,
    String? schedule,
    String? colorHex,
    int sortOrder = 0,
  }) async {
    try {
      await _repository.createGrade(
        name: name,
        code: code,
        schedule: schedule,
        colorHex: colorHex,
        sortOrder: sortOrder,
      );
      await loadGrades();
    } catch (e) {
      emit(GradesError(e.toString()));
      rethrow;
    }
  }
}
