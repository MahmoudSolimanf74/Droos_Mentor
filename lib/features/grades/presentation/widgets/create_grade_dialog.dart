import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/token_generator.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class CreateGradeDialog extends StatefulWidget {
  final Function({
    required String name,
    required String code,
    required String schedule,
    required String colorHex,
  }) onSubmit;

  const CreateGradeDialog({super.key, required this.onSubmit});

  static Future<void> show(
    BuildContext context, {
    required Function({
      required String name,
      required String code,
      required String schedule,
      required String colorHex,
    }) onSubmit,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => CreateGradeDialog(onSubmit: onSubmit),
    );
  }

  @override
  State<CreateGradeDialog> createState() => _CreateGradeDialogState();
}

class _CreateGradeDialogState extends State<CreateGradeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _scheduleController = TextEditingController();
  String _selectedColor = '#4f8ef7';
  bool _isSubmitting = false;

  static const List<String> _colors = [
    '#4f8ef7', // Primary Blue
    '#22d3ee', // Cyan
    '#34d399', // Green
    '#fbbf24', // Yellow
    '#f87171', // Red
    '#a78bfa', // Purple
  ];

  @override
  void initState() {
    super.initState();
    _codeController.text = TokenGenerator.generateGroupCode();
    _scheduleController.text = 'السبت والثلاثاء • 5:00م';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _scheduleController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmitting = true);
      widget.onSubmit(
        name: _nameController.text.trim(),
        code: _codeController.text.trim().toUpperCase(),
        schedule: _scheduleController.text.trim(),
        colorHex: _selectedColor,
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
                      'إنشاء مجموعة جديدة',
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
                  controller: _nameController,
                  label: 'اسم المجموعة أو الصف',
                  hintText: 'مثال: الصف الأول الثانوي (مجموعة أ)',
                  prefixIcon: Icons.school_outlined,
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'يرجى إدخال اسم المجموعة' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _codeController,
                  label: 'كود الانضمام (Join Code)',
                  hintText: 'GRP-XXXXX',
                  textDirection: TextDirection.ltr,
                  prefixIcon: Icons.vpn_key_outlined,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    tooltip: 'توليد كود جديد',
                    onPressed: () {
                      setState(() {
                        _codeController.text = TokenGenerator.generateGroupCode();
                      });
                    },
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'يرجى إدخال كود الانضمام' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _scheduleController,
                  label: 'مواعيد الحصص الأسبوعية',
                  hintText: 'السبت والثلاثاء • 5:00م',
                  prefixIcon: Icons.access_time_rounded,
                ),
                const SizedBox(height: 14),

                Text(
                  'اللون المميز للمجموعة',
                  style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _colors.map((hex) {
                      final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                      final isSelected = _selectedColor == hex;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = hex),
                        child: Container(
                          margin: const EdgeInsets.only(left: 10),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: isSelected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                        ),
                      );
                    }).toList(),
                  ),
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
                      text: 'إضافة المجموعة',
                      variant: ButtonVariant.primary,
                      isLoading: _isSubmitting,
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
