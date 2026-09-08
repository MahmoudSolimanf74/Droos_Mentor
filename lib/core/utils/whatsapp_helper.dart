import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../utils/phone_validator.dart';
import '../../features/students/domain/student_model.dart';

class WhatsAppHelper {
  WhatsAppHelper._();

  /// Generates a structured Arabic performance report message for WhatsApp
  static String buildStudentReportMessage({
    required StudentModel student,
    String? groupName,
  }) {
    final String effectiveGroup;
    if (groupName != null && groupName.isNotEmpty) {
      effectiveGroup = groupName;
    } else if (student.groupName != null && student.groupName!.isNotEmpty) {
      effectiveGroup = student.groupName!;
    } else if (student.gradeName.isNotEmpty) {
      effectiveGroup = student.gradeName;
    } else {
      effectiveGroup = 'المجموعة الدراسية';
    }

    return '''
السلام عليكم ورحمة الله وبركاته 🌸
تحية طيبة لولي أمر الطالب: *${student.name}*
المجموعة: *${effectiveGroup.isNotEmpty ? effectiveGroup : 'المجموعة الدراسية'}*
كود الطالب: *${student.studentCode}*

📊 *تقرير المتابعة والتقييم:*
━━━━━━━━━━━━━━━━━━━━
📌 *نسبة الحضور:* ${student.attendanceRate.toStringAsFixed(0)}%
📝 *تسليم الواجبات:* ${student.homeworkRate.toStringAsFixed(0)}%
🎯 *متوسط درجات الاختبارات:* ${student.examAverage.toStringAsFixed(1)}%
━━━━━━━━━━━━━━━━━━━━

نتمنى له دوام التوفيق والتميز دائماً بإذن الله! 🌟
'''.trim();
  }

  /// Sends a WhatsApp message to the student's parent or student.
  /// Prioritizes `parentPhone`, then falls back to `phone`.
  static Future<void> shareStudentReport({
    required BuildContext context,
    required StudentModel student,
    String? groupName,
  }) async {
    final rawPhone = (student.parentPhone != null && student.parentPhone!.trim().isNotEmpty)
        ? student.parentPhone!.trim()
        : (student.phone != null && student.phone!.trim().isNotEmpty ? student.phone!.trim() : null);

    final reportText = buildStudentReportMessage(
      student: student,
      groupName: groupName,
    );

    if (rawPhone == null || rawPhone.isEmpty) {
      if (!context.mounted) return;
      _showMissingPhoneDialog(context, student, reportText);
      return;
    }

    final formattedPhone = PhoneValidator.formatForWhatsApp(rawPhone);
    final encodedMessage = Uri.encodeComponent(reportText);
    final waUrlString = 'https://wa.me/$formattedPhone?text=$encodedMessage';
    final waUri = Uri.parse(waUrlString);

    try {
      final launched = await launchUrl(waUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        // Try platform default
        await launchUrl(waUri);
      }
    } catch (e) {
      // Fallback: Copy to clipboard and alert user
      await Clipboard.setData(ClipboardData(text: reportText));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر فتح واتساب تلقائياً، تم نسخ التقرير للحافظة.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  static void _showMissingPhoneDialog(BuildContext context, StudentModel student, String reportText) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            SizedBox(width: 8),
            Text('لا يوجد رقم هاتف مسجل'),
          ],
        ),
        content: Text('لم يتم تسجيل رقم هاتف لولي أمر الطالب (${student.name}). يمكنك نسخ نص التقرير ومشاركته يدوياً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('نسخ نص التقرير'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: reportText));
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('تم نسخ تقرير الطالب بنجاح!'),
                    backgroundColor: AppColors.green,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
