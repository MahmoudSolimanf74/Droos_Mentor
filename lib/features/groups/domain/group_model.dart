import 'package:equatable/equatable.dart';

class GroupModel extends Equatable {
  final String id;
  final String teacherId;
  final String gradeId;
  final String gradeName;
  final String name;
  final String joinCode;
  final String inviteToken;
  final String status;
  final DateTime createdAt;
  final int studentsCount;

  const GroupModel({
    required this.id,
    required this.teacherId,
    required this.gradeId,
    required this.gradeName,
    required this.name,
    required this.joinCode,
    required this.inviteToken,
    this.status = 'active',
    required this.createdAt,
    this.studentsCount = 0,
  });

  bool get isActive => status == 'active';

  GroupModel copyWith({
    String? id,
    String? teacherId,
    String? gradeId,
    String? gradeName,
    String? name,
    String? joinCode,
    String? inviteToken,
    String? status,
    DateTime? createdAt,
    int? studentsCount,
  }) {
    return GroupModel(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      gradeId: gradeId ?? this.gradeId,
      gradeName: gradeName ?? this.gradeName,
      name: name ?? this.name,
      joinCode: joinCode ?? this.joinCode,
      inviteToken: inviteToken ?? this.inviteToken,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      studentsCount: studentsCount ?? this.studentsCount,
    );
  }

  factory GroupModel.fromJson(Map<String, dynamic> json, [int studentsCount = 0]) {
    String gName = '';
    if (json['grades'] != null && json['grades'] is Map) {
      gName = json['grades']['name'] as String? ?? '';
    } else if (json['grade_name'] != null) {
      gName = json['grade_name'] as String? ?? '';
    } else if (json['grade'] != null) {
      gName = json['grade'] as String? ?? '';
    }

    return GroupModel(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String? ?? '',
      gradeId: json['grade_id'] as String? ?? '',
      gradeName: gName.isNotEmpty ? gName : 'المرحلة الثانوية',
      name: json['name'] as String? ?? '',
      joinCode: json['join_code'] as String? ?? '',
      inviteToken: json['invite_token'] as String? ?? '',
      status: json['status'] as String? ?? (json['is_active'] == false ? 'archived' : 'active'),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      studentsCount: json['students_count'] as int? ?? studentsCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'teacher_id': teacherId,
        'grade_id': gradeId,
        'name': name,
        'join_code': joinCode,
        'invite_token': inviteToken,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        teacherId,
        gradeId,
        gradeName,
        name,
        joinCode,
        inviteToken,
        status,
        createdAt,
        studentsCount,
      ];
}
