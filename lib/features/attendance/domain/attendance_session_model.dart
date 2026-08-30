import 'package:equatable/equatable.dart';

class AttendanceSessionModel extends Equatable {
  final String id;
  final String groupId;
  final String title;
  final DateTime sessionDate;
  final DateTime createdAt;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int totalStudents;
  final String? groupName;

  const AttendanceSessionModel({
    required this.id,
    required this.groupId,
    required this.title,
    required this.sessionDate,
    required this.createdAt,
    this.presentCount = 0,
    this.absentCount = 0,
    this.lateCount = 0,
    this.totalStudents = 0,
    this.groupName,
  });

  double get attendanceRate => totalStudents > 0
      ? ((presentCount + lateCount) / totalStudents) * 100
      : 0.0;

  factory AttendanceSessionModel.fromJson(
    Map<String, dynamic> json, {
    int presentCount = 0,
    int absentCount = 0,
    int lateCount = 0,
    int totalStudents = 0,
    String? groupName,
  }) {
    return AttendanceSessionModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      sessionDate: json['session_date'] != null
          ? DateTime.tryParse(json['session_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      presentCount: json['present_count'] as int? ?? presentCount,
      absentCount: json['absent_count'] as int? ?? absentCount,
      lateCount: json['late_count'] as int? ?? lateCount,
      totalStudents: json['total_students'] as int? ?? totalStudents,
      groupName: groupName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'group_id': groupId,
        'title': title,
        'session_date': sessionDate.toIso8601String().split('T').first,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        groupId,
        title,
        sessionDate,
        createdAt,
        presentCount,
        absentCount,
        lateCount,
        totalStudents,
        groupName,
      ];
}
