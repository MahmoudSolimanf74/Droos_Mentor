import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class CreateLessonDialog extends StatefulWidget {
  final Function(String title, String? description) onSubmit;

  const CreateLessonDialog({super.key, required this.onSubmit});

  static Future<void> show(
    BuildContext context, {
    required Function(String title, String? description) onSubmit,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => CreateLessonDialog(onSubmit: onSubmit),
    );
  }

  @override
  State<CreateLessonDialog> createState() => _CreateLessonDialogState();
}

class _CreateLessonDialogState extends State<CreateLessonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSubmit(
        _titleController.text.trim(),
        _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      backgroundColor: AppColors.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'إضافة درس جديد',
                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(color: AppColors.border, height: 18),
                CustomTextField(
                  controller: _titleController,
                  label: 'عنوان الدرس',
                  hintText: 'مثال: الدرس الأول: المتغيرات وأنواع البيانات',
                  prefixIcon: Icons.menu_book_outlined,
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'يرجى إدخال عنوان الدرس' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _descController,
                  label: 'شرح مختصر للدرس (اختياري)',
                  hintText: 'أهم النقاط التي سيتم شرحها في هذا الدرس...',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomButton(
                      text: 'إلغاء',
                      variant: ButtonVariant.outline,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    CustomButton(
                      text: 'إضافة الدرس',
                      variant: ButtonVariant.primary,
                      icon: Icons.add_rounded,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
