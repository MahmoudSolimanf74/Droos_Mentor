import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../domain/attendance_record_model.dart';
import '../domain/attendance_session_model.dart';
import 'attendance_cubit.dart';

class AttendanceSessionDetailScreen extends StatefulWidget {
  final AttendanceSessionModel? session;
  final String gradeId;
  final String gradeName;

  const AttendanceSessionDetailScreen({
    super.key,
    this.session,
    required this.gradeId,
    required this.gradeName,
  });

  @override
  State<AttendanceSessionDetailScreen> createState() => _AttendanceSessionDetailScreenState();
}

class _AttendanceSessionDetailScreenState extends State<AttendanceSessionDetailScreen> {
  late TextEditingController _titleController;
  late DateTime _sessionDate;
  List<AttendanceRecordModel> _records = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String _searchQuery = '';

  bool get isNew => widget.session == null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.session?.title ?? 'حصة درس: ${_formatDate(DateTime.now())}',
    );
    _sessionDate = widget.session?.sessionDate ?? DateTime.now();
    _loadInitialData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month}/${dt.day}';
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      if (!isNew && widget.session != null) {
        // Load existing session records
        final records = await context.read<AttendanceCubit>().loadSessionRecords(widget.session!.id);
        if (records.isNotEmpty) {
          setState(() {
            _records = records;
            _isLoading = false;
          });
          return;
        }
      }

      // If new session or records are empty, fetch enrolled students for this grade
      final client = SupabaseConfig.client;
      if (client != null) {
        final res = await client
            .from('students')
            .select('id, name, student_code')
            .eq('grade_id', widget.gradeId)
            .order('name');
        
        final list = (res as List<dynamic>).map((s) {
          final sMap = s as Map<String, dynamic>;
          return AttendanceRecordModel(
            id: '',
            sessionId: widget.session?.id ?? '',
            studentId: sMap['id'].toString(),
            studentName: sMap['name']?.toString() ?? 'طالب',
            studentCode: sMap['student_code']?.toString() ?? 'STU-000',
            status: 'present',
          );
        }).toList();

        setState(() {
          _records = list;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('[AttendanceDetail] Error loading students/records: $e');
    }

    setState(() => _isLoading = false);
  }

  void _setAllStatus(String status) {
    setState(() {
      _records = _records.map((r) => r.copyWith(status: status)).toList();
    });
  }

  void _updateStatus(int index, String status) {
    setState(() {
      _records[index] = _records[index].copyWith(status: status);
    });
  }

  Future<void> _saveAndExit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة عنوان للحصة'), backgroundColor: AppColors.red),
      );
      return;
    }

    if (_records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد طلاب مسجلين في هذه المجموعة لحفظ حضورهم'), backgroundColor: AppColors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final recordsPayload = _records.map((r) => {
        'student_id': r.studentId,
        'status': r.status,
        'notes': r.notes,
      }).toList();

      await context.read<AttendanceCubit>().saveAttendance(
        sessionId: widget.session?.id,
        groupId: widget.gradeId,
        title: title,
        sessionDate: _sessionDate,
        records: recordsPayload,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('تم حفظ تسجيل الحضور بنجاح!'),
              ],
            ),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حفظ الحضور: $e'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _records.where((r) => r.status == 'present').length;
    final lateCount = _records.where((r) => r.status == 'late').length;
    final absentCount = _records.where((r) => r.status == 'absent').length;

    final filteredRecords = _records.where((r) {
      if (_searchQuery.isEmpty) return true;
      return r.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.studentCode.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isNew ? 'تسجيل حصة حضور جديدة' : 'تحضير: ${widget.session?.title ?? ""}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_rounded),
            tooltip: 'تغيير التاريخ',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _sessionDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => _sessionDate = picked);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : SafeArea(
              child: Column(
                children: [
                  // Top Info & Title Form Card
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.gradeName,
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(_formatDate(_sessionDate), style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _titleController,
                          label: 'عنوان الحصة أو الدرس',
                          hintText: 'مثال: شرح الباب الأول - الحصة الثانية',
                          prefixIcon: Icons.menu_book_rounded,
                        ),
                      ],
                    ),
                  ),

                  // Quick Stats & Bulk Actions Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatBadge('حاضر', presentCount, AppColors.green),
                          const SizedBox(width: 6),
                          _buildStatBadge('متأخر', lateCount, AppColors.yellow),
                          const SizedBox(width: 6),
                          _buildStatBadge('غائب', absentCount, AppColors.red),
                          const SizedBox(width: 14),
                          Container(width: 1, height: 24, color: AppColors.border),
                          const SizedBox(width: 10),
                          TextButton.icon(
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                            onPressed: () => _setAllStatus('present'),
                            icon: const Icon(Icons.check_circle_outline, size: 15, color: AppColors.green),
                            label: const Text('الكل حاضر', style: TextStyle(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.bold)),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                            onPressed: () => _setAllStatus('absent'),
                            icon: const Icon(Icons.cancel_outlined, size: 15, color: AppColors.red),
                            label: const Text('الكل غائب', style: TextStyle(fontSize: 12, color: AppColors.red, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Search input
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'ابحث عن اسم أو كود طالب...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),

                  // Students Attendance List
                  Expanded(
                    child: filteredRecords.isEmpty
                        ? Center(
                            child: Text(
                              _records.isEmpty
                                  ? 'لا يوجد طلاب مسجلين في هذه المجموعة'
                                  : 'لا توجد نتائج مطابقة للبحث',
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: filteredRecords.length,
                            separatorBuilder: (context, i) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final record = filteredRecords[i];
                              final actualIndex = _records.indexOf(record);
                              return _buildStudentCard(record, actualIndex);
                            },
                          ),
                  ),

                  // Bottom Save & Exit Action Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      border: const Border(top: BorderSide(color: AppColors.border)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -4)),
                      ],
                    ),
                    child: CustomButton(
                      text: '💾 حفظ تسجيل الحضور والإنهاء',
                      isLoading: _isSaving,
                      onPressed: _saveAndExit,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text('$label: $count', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStudentCard(AttendanceRecordModel record, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: record.status == 'present'
              ? AppColors.green.withValues(alpha: 0.4)
              : record.status == 'late'
                  ? AppColors.yellow.withValues(alpha: 0.4)
                  : AppColors.red.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Text(
              record.studentName.isNotEmpty ? record.studentName.substring(0, 1) : 'ط',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.studentName, style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(record.studentCode, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          // Status Selector Segmented Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusChoiceButton(
                label: 'حاضر',
                icon: Icons.check,
                color: AppColors.green,
                isSelected: record.status == 'present',
                onTap: () => _updateStatus(index, 'present'),
              ),
              const SizedBox(width: 4),
              _buildStatusChoiceButton(
                label: 'متأخر',
                icon: Icons.access_time,
                color: AppColors.yellow,
                isSelected: record.status == 'late',
                onTap: () => _updateStatus(index, 'late'),
              ),
              const SizedBox(width: 4),
              _buildStatusChoiceButton(
                label: 'غائب',
                icon: Icons.close,
                color: AppColors.red,
                isSelected: record.status == 'absent',
                onTap: () => _updateStatus(index, 'absent'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChoiceButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isSelected ? Colors.black : color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
