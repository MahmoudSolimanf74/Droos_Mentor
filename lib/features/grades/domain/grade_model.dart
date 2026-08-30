import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class GradeModel extends Equatable {
  final String id;
  final String name;
  final String code;
  final String gradeLevel; // e.g. 'الأول الثانوي', 'الثاني الثانوي', 'الثالث الثانوي'
  final String colorHex;
  final int colorValue;
  final String joinCode;
  final String schedule;
  final int studentCount;
  final double averageAttendance;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;

  const GradeModel({
    required this.id,
    required this.name,
    required this.code,
    this.gradeLevel = 'الأول الثانوي',
    this.colorHex = '#4f8ef7',
    this.colorValue = 0xFF4F8EF7,
    this.joinCode = 'MATH-1A',
    this.schedule = 'السبت والثلاثاء • 5:00م',
    this.studentCount = 0,
    this.averageAttendance = 90.0,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
  });

  Color get color => Color(colorValue);

  factory GradeModel.fromJson(Map<String, dynamic> json) {
    int parsedColorVal = 0xFF4F8EF7;
    if (json['color_value'] != null) {
      parsedColorVal = (json['color_value'] as num).toInt();
    } else if (json['color'] != null) {
      final hex = json['color'].toString().replaceAll('#', '');
      parsedColorVal = int.tryParse('0xFF$hex') ?? 0xFF4F8EF7;
    }

    return GradeModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? json['join_code'] as String? ?? 'MATH-1A',
      gradeLevel: json['grade'] as String? ?? 'الأول الثانوي',
      colorHex: json['color'] as String? ?? '#4f8ef7',
      colorValue: parsedColorVal,
      joinCode: json['join_code'] as String? ?? json['code'] as String? ?? 'MATH-1A',
      schedule: json['schedule'] as String? ?? 'السبت والثلاثاء • 5:00م',
      studentCount: (json['student_count'] as num?)?.toInt() ?? 0,
      averageAttendance: (json['average_attendance'] as num?)?.toDouble() ?? 90.0,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'grade': gradeLevel,
        'color': colorHex,
        'color_value': colorValue,
        'join_code': joinCode,
        'schedule': schedule,
        'sort_order': sortOrder,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };

  GradeModel copyWith({
    String? id,
    String? name,
    String? code,
    String? gradeLevel,
    String? colorHex,
    int? colorValue,
    String? joinCode,
    String? schedule,
    int? studentCount,
    double? averageAttendance,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return GradeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      colorHex: colorHex ?? this.colorHex,
      colorValue: colorValue ?? this.colorValue,
      joinCode: joinCode ?? this.joinCode,
      schedule: schedule ?? this.schedule,
      studentCount: studentCount ?? this.studentCount,
      averageAttendance: averageAttendance ?? this.averageAttendance,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, code, gradeLevel, colorHex, colorValue, joinCode, schedule, studentCount, averageAttendance, sortOrder, isActive, createdAt];
}
