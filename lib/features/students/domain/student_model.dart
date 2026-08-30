import 'package:equatable/equatable.dart';

class StudentModel extends Equatable {
  final String id;
  final String teacherId;
  final String? profileId;
  final String gradeId;
  final String gradeName;
  final String? groupId;
  final String? groupName;
  final String name;
  final String? email;
  final String? phone;
  final String? parentPhone;
  final String studentCode;
  final String status; // 'active', 'inactive', 'suspended'
  final DateTime createdAt;
  final double attendanceRate; // e.g. 95.0 %
  final double homeworkRate;   // e.g. 88.0 %
  final double examAverage;   // e.g. 92.5 %

  const StudentModel({
    required this.id,
    this.teacherId = '',
    this.profileId,
    this.gradeId = '',
    this.gradeName = '',
    this.groupId,
    this.groupName,
    required this.name,
    this.email,
    this.phone,
    this.parentPhone,
    required this.studentCode,
    this.status = 'active',
    required this.createdAt,
    this.attendanceRate = 0.0,
    this.homeworkRate = 0.0,
    this.examAverage = 0.0,
  });

  bool get isActive => status == 'active';

  StudentModel copyWith({
    String? id,
    String? teacherId,
    String? profileId,
    String? gradeId,
    String? gradeName,
    String? groupId,
    String? groupName,
    String? name,
    String? email,
    String? phone,
    String? parentPhone,
    String? studentCode,
    String? status,
    DateTime? createdAt,
    double? attendanceRate,
    double? homeworkRate,
    double? examAverage,
  }) {
    return StudentModel(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      profileId: profileId ?? this.profileId,
      gradeId: gradeId ?? this.gradeId,
      gradeName: gradeName ?? this.gradeName,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      parentPhone: parentPhone ?? this.parentPhone,
      studentCode: studentCode ?? this.studentCode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      attendanceRate: attendanceRate ?? this.attendanceRate,
      homeworkRate: homeworkRate ?? this.homeworkRate,
      examAverage: examAverage ?? this.examAverage,
    );
  }

  factory StudentModel.fromJson(
    Map<String, dynamic> json, {
    String? groupId,
    String? groupName,
    double attendanceRate = 0.0,
    double homeworkRate = 0.0,
    double examAverage = 0.0,
  }) {
    String gName = '';
    if (json['grades'] != null && json['grades'] is Map) {
      gName = json['grades']['name'] as String? ?? '';
    } else if (json['grade_name'] != null) {
      gName = json['grade_name'] as String? ?? '';
    }

    return StudentModel(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String? ?? '',
      profileId: json['profile_id'] as String?,
      gradeId: json['grade_id'] as String? ?? '',
      gradeName: gName.isNotEmpty ? gName : 'الصف الأول الثانوي',
      groupId: groupId ?? json['group_id'] as String?,
      groupName: groupName ?? json['group_name'] as String?,
      name: json['name'] as String? ?? 'طالب',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      parentPhone: json['parent_phone'] as String?,
      studentCode: json['student_code'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      attendanceRate: (json['attendance_rate'] as num?)?.toDouble() ?? attendanceRate,
      homeworkRate: (json['homework_rate'] as num?)?.toDouble() ?? homeworkRate,
      examAverage: (json['exam_average'] as num?)?.toDouble() ?? examAverage,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'teacher_id': teacherId,
        'profile_id': profileId,
        'grade_id': gradeId,
        if (groupId != null) 'group_id': groupId,
        'name': name,
        'email': email,
        'phone': phone,
        'parent_phone': parentPhone,
        'student_code': studentCode,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        teacherId,
        profileId,
        gradeId,
        gradeName,
        groupId,
        groupName,
        name,
        email,
        phone,
        parentPhone,
        studentCode,
        status,
        createdAt,
        attendanceRate,
        homeworkRate,
        examAverage,
      ];
}
