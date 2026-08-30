import 'package:equatable/equatable.dart';

class LessonFileModel extends Equatable {
  final String id;
  final String lessonId;
  final String title;
  final String filePath;
  final String fileType; // e.g. 'pdf', 'docx', 'pptx', 'zip', 'mp4'
  final int fileSize;     // bytes
  final DateTime createdAt;

  const LessonFileModel({
    required this.id,
    required this.lessonId,
    required this.title,
    String? filePath,
    String? fileName,
    String? storagePath,
    required this.fileType,
    required this.fileSize,
    required this.createdAt,
  }) : filePath = filePath ?? storagePath ?? fileName ?? title;

  String get fileName => title.isNotEmpty ? title : filePath;
  String get storagePath => filePath;

  factory LessonFileModel.fromJson(Map<String, dynamic> json) {
    return LessonFileModel(
      id: json['id'].toString(),
      lessonId: json['lesson_id']?.toString() ?? '',
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      filePath: json['file_path'] as String? ?? json['name'] as String? ?? '',
      fileType: json['file_type'] as String? ?? json['type'] as String? ?? 'pdf',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'lesson_id': lessonId,
        'title': title,
        'file_path': filePath,
        'file_type': fileType,
        'file_size': fileSize,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, lessonId, title, filePath, fileType, fileSize, createdAt];
}
