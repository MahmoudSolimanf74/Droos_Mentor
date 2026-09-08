import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/core/utils/whatsapp_helper.dart';
import 'package:teacher/features/students/domain/student_model.dart';

void main() {
  group('WhatsAppHelper Tests', () {
    test('buildStudentReportMessage formats text with stats correctly', () {
      final student = StudentModel(
        id: 'stu-1',
        name: 'أحمد محمد علي',
        studentCode: 'STU-1024',
        gradeName: 'الصف الأول الثانوي',
        groupName: 'مجموعة العباقرة (أ)',
        phone: '01012345678',
        parentPhone: '01123456789',
        attendanceRate: 92.0,
        homeworkRate: 85.0,
        examAverage: 90.5,
        createdAt: DateTime.now(),
      );

      final message = WhatsAppHelper.buildStudentReportMessage(
        student: student,
        groupName: student.groupName,
      );

      expect(message, contains('أحمد محمد علي'));
      expect(message, contains('STU-1024'));
      expect(message, contains('مجموعة العباقرة (أ)'));
      expect(message, contains('92%'));
      expect(message, contains('85%'));
      expect(message, contains('90.5%'));
      expect(message, contains('نسبة الحضور'));
      expect(message, contains('تسليم الواجبات'));
      expect(message, contains('متوسط درجات الاختبارات'));
    });
  });
}
