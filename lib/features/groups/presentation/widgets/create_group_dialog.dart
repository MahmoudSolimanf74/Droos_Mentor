import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../grades/data/grades_repository.dart';
import '../../../grades/domain/grade_model.dart';
import '../../domain/group_model.dart';

class CreateGroupDialog extends StatefulWidget {
  final GroupModel? initialGroup;
  final Function(String name, String gradeId) onSubmit;

  const CreateGroupDialog({
    super.key,
    this.initialGroup,
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    GroupModel? initialGroup,
    required Function(String name, String gradeId) onSubmit,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => CreateGroupDialog(
        initialGroup: initialGroup,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  String? _selectedGradeId;
  List<GradeModel> _grades = [];
  bool _isLoadingGrades = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialGroup?.name ?? '');
    _selectedGradeId = widget.initialGroup?.gradeId;
    _fetchGrades();
  }

  Future<void> _fetchGrades() async {
    try {
      final repo = context.read<GradesRepository>();
      final grades = await repo.getGrades();
      if (mounted) {
        setState(() {
          _grades = grades;
          if (_selectedGradeId == null && grades.isNotEmpty) {
            _selectedGradeId = grades.first.id;
          }
          _isLoadingGrades = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingGrades = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedGradeId == null && _grades.isNotEmpty) {
        _selectedGradeId = _grades.first.id;
      }
      if (_selectedGradeId != null) {
        widget.onSubmit(_nameController.text.trim(), _selectedGradeId!);
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialGroup != null;

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
                    isEditing ? AppStrings.editGroup : AppStrings.createGroup,
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
                label: AppStrings.groupName,
                hintText: 'مثال: مجموعة السبت ٥:٠٠ مساءً',
                prefixIcon: Icons.groups_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return AppStrings.requiredField;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.grade,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              if (_isLoadingGrades)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _selectedGradeId ?? (_grades.isNotEmpty ? _grades.first.id : null),
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.school_outlined, size: 20, color: AppColors.textSecondary),
                  ),
                  dropdownColor: AppColors.surface,
                  items: _grades.map((g) {
                    return DropdownMenuItem<String>(
                      value: g.id,
                      child: Text(g.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedGradeId = val);
                    }
                  },
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
