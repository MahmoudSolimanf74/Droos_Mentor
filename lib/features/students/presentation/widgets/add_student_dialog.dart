import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/phone_validator.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class AddStudentDialog extends StatefulWidget {
  final Function({
    required String name,
    String? phone,
    String? parentPhone,
    String? email,
  }) onSubmit;

  const AddStudentDialog({super.key, required this.onSubmit});

  static Future<void> show(
    BuildContext context, {
    required Function({
      required String name,
      String? phone,
      String? parentPhone,
      String? email,
    }) onSubmit,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AddStudentDialog(onSubmit: onSubmit),
    );
  }

  @override
  State<AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<AddStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _parentPhoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSubmit(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        parentPhone: _parentPhoneController.text.trim().isEmpty ? null : _parentPhoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
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
                    AppStrings.addStudent,
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
                controller: _nameController,
                label: AppStrings.studentName,
                hintText: 'الاسم ثلاثي أو رباعي',
                prefixIcon: Icons.person_outline,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return AppStrings.requiredField;
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _phoneController,
                      label: AppStrings.phone,
                      hintText: '010XXXXXXXX',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      maxLength: 11,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      validator: (val) => PhoneValidator.validateEgyptianPhone(val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _parentPhoneController,
                      label: AppStrings.parentPhone,
                      hintText: '011XXXXXXXX',
                      prefixIcon: Icons.contact_phone_outlined,
                      keyboardType: TextInputType.phone,
                      maxLength: 11,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      validator: (val) => PhoneValidator.validateEgyptianPhone(val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _emailController,
                label: 'البريد الإلكتروني (اختياري)',
                hintText: 'student@example.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
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
                    text: AppStrings.add,
                    variant: ButtonVariant.primary,
                    icon: Icons.add,
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
