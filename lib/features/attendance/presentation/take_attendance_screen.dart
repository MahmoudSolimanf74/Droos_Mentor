import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../students/data/students_repository.dart';
import '../../students/domain/student_model.dart';
import 'attendance_cubit.dart';

class TakeAttendanceScreen extends StatefulWidget {
  final String groupId;

  const TakeAttendanceScreen({super.key, required this.groupId});

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  final TextEditingController _titleController = TextEditingController();
  DateTime _sessionDate = DateTime.now();
  List<StudentModel> _students = [];
  final Map<String, String> _statuses = {}; // studentId -> 'present' | 'absent' | 'late'
  final Map<String, String> _notes = {};    // studentId -> notes
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = 'حصة يوم ${DateFormatter.formatDate(DateTime.now())}';
    _loadStudents();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    final repo = StudentsRepositoryImpl();
    try {
      final list = await repo.getStudents(groupId: widget.groupId);
      if (mounted) {
        setState(() {
          _students = list;
          for (final s in list) {
            _statuses[s.id] = 'present';
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _markAll(String status) {
    setState(() {
      for (final s in _students) {
        _statuses[s.id] = status;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sessionDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2027),
    );
    if (picked != null) {
      setState(() => _sessionDate = picked);
    }
  }

  Future<void> _saveAttendance() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال عنوان الحصة')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final records = _students.map((s) => {
            'student_id': s.id,
            'status': _statuses[s.id] ?? 'present',
            'notes': _notes[s.id],
          }).toList();

      await context.read<AttendanceCubit>().saveAttendanceSession(
            groupId: widget.groupId,
            title: _titleController.text.trim(),
            sessionDate: _sessionDate,
            records: records,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.attendanceSaved),
            backgroundColor: AppColors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل حفظ الحصة: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)),
        ),
      );
    }

    final presentCount = _statuses.values.where((v) => v == 'present').length;
    final absentCount = _statuses.values.where((v) => v == 'absent').length;
    final lateCount = _statuses.values.where((v) => v == 'late').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.takeAttendance),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            tooltip: AppStrings.save,
            onPressed: _isSaving ? null : _saveAttendance,
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: CustomButton(
          text: AppStrings.saveSession,
          icon: Icons.save_outlined,
          isLoading: _isSaving,
          onPressed: _saveAttendance,
        ),
      ),
      body: Column(
        children: [
          // Session Title & Date Bar
          Container(
            color: AppColors.card,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CustomTextField(
                  controller: _titleController,
                  label: AppStrings.sessionTitle,
                  hintText: 'مثال: حصة المتجهات والمصفوفات',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today_outlined, size: 18),
                        label: Text(
                          'تاريخ الحصة: ${DateFormatter.formatDate(_sessionDate)}',
                          style: AppTextStyles.bodyMedium,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _pickDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Quick Action & Counter Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildBadgeCounter('حاضر: $presentCount', AppColors.green.withValues(alpha: 0.15), AppColors.green),
                        const SizedBox(width: 8),
                        _buildBadgeCounter('غائب: $absentCount', AppColors.red.withValues(alpha: 0.15), AppColors.red),
                        const SizedBox(width: 8),
                        _buildBadgeCounter('متأخر: $lateCount', AppColors.yellow.withValues(alpha: 0.15), AppColors.yellow),
                      ],
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.done_all, size: 18, color: AppColors.primary),
                      label: const Text(AppStrings.markAllPresent, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      onPressed: () => _markAll('present'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),

          // Students Roster List
          Expanded(
            child: _students.isEmpty
                ? const Center(child: Text('لا يوجد طلاب في هذه المجموعة'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _students.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      final currentStatus = _statuses[student.id] ?? 'present';

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: currentStatus == 'absent'
                                ? AppColors.red.withValues(alpha: 0.4)
                                : (currentStatus == 'late' ? AppColors.yellow.withValues(alpha: 0.4) : AppColors.border),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Student Name & Code
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.name,
                                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    student.studentCode,
                                    style: AppTextStyles.monoNumber.copyWith(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),

                            // 3-Way Toggle Buttons (Present, Late, Absent)
                            Row(
                              children: [
                                _buildStatusOption(
                                  label: AppStrings.statusPresent,
                                  icon: Icons.check,
                                  isSelected: currentStatus == 'present',
                                  activeColor: AppColors.green,
                                  activeBg: AppColors.green.withValues(alpha: 0.15),
                                  onTap: () => setState(() => _statuses[student.id] = 'present'),
                                ),
                                const SizedBox(width: 6),
                                _buildStatusOption(
                                  label: AppStrings.statusLate,
                                  icon: Icons.access_time,
                                  isSelected: currentStatus == 'late',
                                  activeColor: AppColors.yellow,
                                  activeBg: AppColors.yellow.withValues(alpha: 0.15),
                                  onTap: () => setState(() => _statuses[student.id] = 'late'),
                                ),
                                const SizedBox(width: 6),
                                _buildStatusOption(
                                  label: AppStrings.statusAbsent,
                                  icon: Icons.close,
                                  isSelected: currentStatus == 'absent',
                                  activeColor: AppColors.red,
                                  activeBg: AppColors.red.withValues(alpha: 0.15),
                                  onTap: () => setState(() => _statuses[student.id] = 'absent'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCounter(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildStatusOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required Color activeBg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : AppColors.cardHover,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? activeColor : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? activeColor : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
