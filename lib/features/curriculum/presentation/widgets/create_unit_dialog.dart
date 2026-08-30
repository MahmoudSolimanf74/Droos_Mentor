import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../domain/unit_model.dart';

class CreateUnitDialog extends StatefulWidget {
  final UnitModel? initialUnit;
  final Function(String title, String? description) onSubmit;

  const CreateUnitDialog({
    super.key,
    this.initialUnit,
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    UnitModel? initialUnit,
    required Function(String title, String? description) onSubmit,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => CreateUnitDialog(
        initialUnit: initialUnit,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<CreateUnitDialog> createState() => _CreateUnitDialogState();
}

class _CreateUnitDialogState extends State<CreateUnitDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialUnit?.title ?? '');
    _descController = TextEditingController(text: widget.initialUnit?.description ?? '');
  }

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
    final isEditing = widget.initialUnit != null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
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
                    isEditing ? 'تعديل الوحدة الدراسية' : AppStrings.addUnit,
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: AppColors.border, height: 24),
              CustomTextField(
                controller: _titleController,
                label: 'عنوان الوحدة',
                hintText: 'مثال: الوحدة الأولى: مقدمة في لغة بايثون',
                prefixIcon: Icons.menu_book_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return AppStrings.requiredField;
                  return null;
                },
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _descController,
                label: 'وصف الوحدة (اختياري)',
                hintText: 'مخرجات التعلم والمفاهيم التي تغطيها الوحدة...',
                maxLines: 3,
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomButton(
                    text: AppStrings.cancel,
                    variant: ButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  CustomButton(
                    text: isEditing ? AppStrings.save : AppStrings.add,
                    variant: ButtonVariant.primary,
                    icon: isEditing ? Icons.check : Icons.add,
                    onPressed: _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
