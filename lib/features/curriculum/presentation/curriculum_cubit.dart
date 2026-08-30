import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/curriculum_repository.dart';
import '../domain/curriculum_model.dart';
import '../domain/lesson_file_model.dart';
import '../domain/lesson_model.dart';
import '../domain/unit_model.dart';

abstract class CurriculumState extends Equatable {
  const CurriculumState();

  @override
  List<Object?> get props => [];
}

class CurriculumInitial extends CurriculumState {}

class CurriculumLoading extends CurriculumState {}

class CurriculumLoaded extends CurriculumState {
  final String gradeId;
  final CurriculumModel? curriculum;
  final List<UnitModel> units;
  final String? selectedUnitId;
  final List<LessonModel> lessons;
  final String? selectedLessonId;
  final List<LessonFileModel> files;
  final bool isUploading;

  const CurriculumLoaded({
    required this.gradeId,
    this.curriculum,
    required this.units,
    this.selectedUnitId,
    this.lessons = const [],
    this.selectedLessonId,
    this.files = const [],
    this.isUploading = false,
  });

  UnitModel? get selectedUnit {
    if (selectedUnitId == null || units.isEmpty) return null;
    try {
      return units.firstWhere((u) => u.id == selectedUnitId);
    } catch (_) {
      return null;
    }
  }

  LessonModel? get selectedLesson {
    if (selectedLessonId == null || lessons.isEmpty) return null;
    try {
      return lessons.firstWhere((l) => l.id == selectedLessonId);
    } catch (_) {
      return null;
    }
  }

  CurriculumLoaded copyWith({
    String? gradeId,
    CurriculumModel? curriculum,
    List<UnitModel>? units,
    String? selectedUnitId,
    List<LessonModel>? lessons,
    String? selectedLessonId,
    List<LessonFileModel>? files,
    bool? isUploading,
    bool clearSelectedUnit = false,
    bool clearSelectedLesson = false,
  }) {
    return CurriculumLoaded(
      gradeId: gradeId ?? this.gradeId,
      curriculum: curriculum ?? this.curriculum,
      units: units ?? this.units,
      selectedUnitId: clearSelectedUnit ? null : (selectedUnitId ?? this.selectedUnitId),
      lessons: lessons ?? this.lessons,
      selectedLessonId: clearSelectedLesson ? null : (selectedLessonId ?? this.selectedLessonId),
      files: files ?? this.files,
      isUploading: isUploading ?? this.isUploading,
    );
  }

  @override
  List<Object?> get props => [gradeId, curriculum, units, selectedUnitId, lessons, selectedLessonId, files, isUploading];
}

class CurriculumError extends CurriculumState {
  final String message;

  const CurriculumError(this.message);

  @override
  List<Object?> get props => [message];
}

class CurriculumCubit extends Cubit<CurriculumState> {
  final CurriculumRepository _repository;

  CurriculumCubit(this._repository) : super(CurriculumInitial());

  Future<void> loadCurriculumForGrade(String gradeId) async {
    if (gradeId.isEmpty) {
      emit(const CurriculumLoaded(gradeId: '', units: []));
      return;
    }
    emit(CurriculumLoading());
    try {
      var curriculum = await _repository.getCurriculumByGrade(gradeId);
      if (curriculum == null) {
        emit(CurriculumLoaded(gradeId: gradeId, units: const []));
        return;
      }

      final units = await _repository.getUnits(curriculum.id);
      if (units.isNotEmpty) {
        final firstUnit = units.first;
        final lessons = await _repository.getLessons(firstUnit.id);
        List<LessonFileModel> files = [];
        String? firstLessonId;
        if (lessons.isNotEmpty) {
          firstLessonId = lessons.first.id;
          files = await _repository.getLessonFiles(firstLessonId);
        }
        emit(CurriculumLoaded(
          gradeId: gradeId,
          curriculum: curriculum,
          units: units,
          selectedUnitId: firstUnit.id,
          lessons: lessons,
          selectedLessonId: firstLessonId,
          files: files,
        ));
      } else {
        emit(CurriculumLoaded(gradeId: gradeId, curriculum: curriculum, units: const []));
      }
    } catch (e) {
      emit(CurriculumError(e.toString()));
    }
  }

  Future<void> selectUnit(String unitId) async {
    if (state is CurriculumLoaded) {
      final current = state as CurriculumLoaded;
      try {
        final lessons = await _repository.getLessons(unitId);
        List<LessonFileModel> files = [];
        String? firstLessonId;
        if (lessons.isNotEmpty) {
          firstLessonId = lessons.first.id;
          files = await _repository.getLessonFiles(firstLessonId);
        }
        emit(current.copyWith(
          selectedUnitId: unitId,
          lessons: lessons,
          selectedLessonId: firstLessonId,
          files: files,
          clearSelectedLesson: lessons.isEmpty,
        ));
      } catch (e) {
        emit(CurriculumError(e.toString()));
      }
    }
  }

  Future<void> selectLesson(String lessonId) async {
    if (state is CurriculumLoaded) {
      final current = state as CurriculumLoaded;
      try {
        final files = await _repository.getLessonFiles(lessonId);
        emit(current.copyWith(
          selectedLessonId: lessonId,
          files: files,
        ));
      } catch (e) {
        emit(CurriculumError(e.toString()));
      }
    }
  }

  Future<void> createUnit(String title, String? description) async {
    if (state is CurriculumLoaded) {
      final current = state as CurriculumLoaded;
      try {
        var curriculum = current.curriculum;
        curriculum ??= await _repository.createCurriculum(
          gradeId: current.gradeId,
          title: 'منهج المجموعة الدراسية',
        );

        await _repository.createUnit(
          curriculumId: curriculum.id,
          title: title,
          description: description,
        );
        await loadCurriculumForGrade(current.gradeId);
      } catch (e) {
        emit(CurriculumError(e.toString()));
      }
    }
  }

  Future<void> updateUnit(String unitId, String title, String? description) async {
    if (state is CurriculumLoaded) {
      final current = state as CurriculumLoaded;
      try {
        await _repository.updateUnit(unitId: unitId, title: title, description: description);
        await loadCurriculumForGrade(current.gradeId);
      } catch (e) {
        emit(CurriculumError(e.toString()));
      }
    }
  }

  Future<void> deleteUnit(String unitId) async {
    if (state is CurriculumLoaded) {
      final current = state as CurriculumLoaded;
      try {
        await _repository.deleteUnit(unitId);
        await loadCurriculumForGrade(current.gradeId);
      } catch (e) {
        emit(CurriculumError(e.toString()));
      }
    }
  }

  Future<void> createLesson(String title, String? description) async {
    if (state is CurriculumLoaded && (state as CurriculumLoaded).selectedUnitId != null) {
      final current = state as CurriculumLoaded;
      try {
        await _repository.createLesson(unitId: current.selectedUnitId!, title: title, description: description);
        await selectUnit(current.selectedUnitId!);
      } catch (e) {
        emit(CurriculumError(e.toString()));
      }
    }
  }

  Future<void> updateLesson(String lessonId, String title, String? description) async {
    if (state is CurriculumLoaded && (state as CurriculumLoaded).selectedUnitId != null) {
      final current = state as CurriculumLoaded;
      try {
        await _repository.updateLesson(lessonId: lessonId, title: title, description: description);
        await selectUnit(current.selectedUnitId!);
      } catch (e) {
        emit(CurriculumError(e.toString()));
      }
    }
  }

  Future<void> deleteLesson(String lessonId) async {
    if (state is CurriculumLoaded && (state as CurriculumLoaded).selectedUnitId != null) {
      final current = state as CurriculumLoaded;
      try {
        await _repository.deleteLesson(lessonId);
        await selectUnit(current.selectedUnitId!);
      } catch (e) {
        emit(CurriculumError(e.toString()));
      }
    }
  }

  Future<void> uploadFile({
    required String title,
    required String fileName,
    required Uint8List fileBytes,
    required String fileType,
    required int fileSize,
  }) async {
    if (state is CurriculumLoaded && (state as CurriculumLoaded).selectedLessonId != null) {
      final current = state as CurriculumLoaded;
      emit(current.copyWith(isUploading: true));
      try {
        await _repository.uploadLessonFile(
          lessonId: current.selectedLessonId!,
          title: title,
          fileName: fileName,
          fileBytes: fileBytes,
          fileType: fileType,
          fileSize: fileSize,
        );
        final files = await _repository.getLessonFiles(current.selectedLessonId!);
        emit(current.copyWith(files: files, isUploading: false));
      } catch (e) {
        emit(current.copyWith(isUploading: false));
        rethrow;
      }
    }
  }

  Future<void> deleteFile(String fileId, String storagePath) async {
    if (state is CurriculumLoaded && (state as CurriculumLoaded).selectedLessonId != null) {
      final current = state as CurriculumLoaded;
      try {
        await _repository.deleteLessonFile(fileId, storagePath);
        final files = await _repository.getLessonFiles(current.selectedLessonId!);
        emit(current.copyWith(files: files));
      } catch (e) {
        emit(CurriculumError(e.toString()));
      }
    }
  }

  Future<String> getDownloadUrl(String filePath) async {
    final url = await _repository.getSignedFileUrl(filePath);
    return url ?? filePath;
  }
}
