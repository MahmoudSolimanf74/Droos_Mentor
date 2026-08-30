import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String? teacherId;
  final String? teacherCode;
  final String name;
  final String email;
  final String? avatarUrl;
  final String role; // 'teacher' or 'student'
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    this.teacherId,
    this.teacherCode,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.role,
    required this.createdAt,
  });

  bool get isTeacher => role == 'teacher';

  factory UserProfile.fromJson(Map<String, dynamic> json, {String? teacherId, String? teacherCode}) {
    return UserProfile(
      id: json['id'] as String,
      teacherId: teacherId ?? json['teacher_id'] as String?,
      teacherCode: teacherCode ?? json['teacher_code'] as String?,
      name: json['name'] as String? ?? 'الأستاذ',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'teacher',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (teacherId != null) 'teacher_id': teacherId,
        if (teacherCode != null) 'teacher_code': teacherCode,
        'name': name,
        'email': email,
        'avatar_url': avatarUrl,
        'role': role,
        'created_at': createdAt.toIso8601String(),
      };

  UserProfile copyWith({
    String? id,
    String? teacherId,
    String? teacherCode,
    String? name,
    String? email,
    String? avatarUrl,
    String? role,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      teacherCode: teacherCode ?? this.teacherCode,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, teacherId, teacherCode, name, email, avatarUrl, role, createdAt];
}
