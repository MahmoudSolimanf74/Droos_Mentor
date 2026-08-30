import 'package:equatable/equatable.dart';

class AttendanceRecordModel extends Equatable {
  final String id;
  final String sessionId;
  final String studentId;
  final String studentName;
  final String studentCode;
  final String status; // 'present', 'absent', 'late'
  final String? notes;
  final DateTime? createdAt;

  const AttendanceRecordModel({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    required this.status,
    this.notes,
    this.createdAt,
  });

  AttendanceRecordModel copyWith({
    String? id,
    String? sessionId,
    String? studentId,
    String? studentName,
    String? studentCode,
    String? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return AttendanceRecordModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentCode: studentCode ?? this.studentCode,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json, {String studentName = '', String studentCode = ''}) {
    return AttendanceRecordModel(
      id: json['id'] as String,
      sessionId: json['session_id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      studentName: json['student_name'] as String? ?? studentName,
      studentCode: json['student_code'] as String? ?? studentCode,
      status: json['status'] as String? ?? 'present',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'session_id': sessionId,
        'student_id': studentId,
        'status': status,
        'notes': notes,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, sessionId, studentId, studentName, studentCode, status, notes, createdAt];
}
