import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../domain/homework_model.dart';
import '../domain/homework_record_model.dart';
import 'homework_cubit.dart';

class HomeworkDetailScreen extends StatefulWidget {
  final HomeworkModel? homework;
  final String gradeId;
  final String gradeName;

  const HomeworkDetailScreen({
    super.key,
    this.homework,
    required this.gradeId,
    required this.gradeName,
  });

  @override
  State<HomeworkDetailScreen> createState() => _HomeworkDetailScreenState();
}

class _HomeworkDetailScreenState extends State<HomeworkDetailScreen> {
  late TextEditingController _titleController;
  DateTime? _dueDate;
  List<HomeworkRecordModel> _records = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String _searchQuery = '';

  bool get isNew => widget.homework == null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.homework?.title ?? 'واجب: ${_formatDate(DateTime.now())}',
    );
    _dueDate = widget.homework?.dueDate ?? DateTime.now().add(const Duration(days: 3));
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
      if (!isNew && widget.homework != null) {
        final records = await context.read<HomeworkCubit>().loadHomeworkRecords(widget.homework!.id);
        if (records.isNotEmpty) {
          setState(() {
            _records = records;
            _isLoading = false;
          });
          return;
        }
      }

      // If new or records empty, load students of this grade
      final client = SupabaseConfig.client;
      if (client != null) {
        final res = await client
            .from('students')
            .select('id, name, student_code')
            .eq('grade_id', widget.gradeId)
            .order('name');

        final list = (res as List<dynamic>).map((s) {
          final sMap = s as Map<String, dynamic>;
          return HomeworkRecordModel(
            id: '',
            homeworkId: widget.homework?.id ?? '',
            studentId: sMap['id'].toString(),
            studentName: sMap['name']?.toString() ?? 'طالب',
            studentCode: sMap['student_code']?.toString() ?? 'STU-000',
            status: 'not_done',
          );
        }).toList();

        setState(() {
          _records = list;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('[HomeworkDetail] Error loading students/records: $e');
    }

    setState(() => _isLoading = false);
  }

  void _setAllStatus(String status) {
    setState(() {
      _records = _records.map((r) => r.copyWith(status: status)).toList();
    });
  }

  void _toggleStatus(int index) {
    final cur = _records[index].status;
    final next = cur == 'done' ? 'not_done' : 'done';
    setState(() {
      _records[index] = _records[index].copyWith(status: next);
    });
  }

  Future<void> _saveAndExit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة عنوان للواجب'), backgroundColor: AppColors.red),
      );
      return;
    }

    if (_records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد طلاب مسجلين في هذه المجموعة'), backgroundColor: AppColors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final recordsPayload = _records.map((r) => {
        'student_id': r.studentId,
        'status': r.status,
      }).toList();

      await context.read<HomeworkCubit>().saveHomework(
        homeworkId: widget.homework?.id,
        groupId: widget.gradeId,
        title: title,
        dueDate: _dueDate,
        records: recordsPayload,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('تم حفظ متابعة الواجب بنجاح!'),
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
          SnackBar(content: Text('فشل حفظ الواجب: $e'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = _records.where((r) => r.status == 'done').length;
    final notDoneCount = _records.where((r) => r.status != 'done').length;

    final filteredRecords = _records.where((r) {
      if (_searchQuery.isEmpty) return true;
      return r.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.studentCode.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isNew ? 'إضافة واجب جديد' : 'متابعة: ${widget.homework?.title ?? ""}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_rounded),
            tooltip: 'تاريخ التسليم',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dueDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => _dueDate = picked);
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
                  // Top Form Card
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
                                color: AppColors.yellow.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.gradeName,
                                style: const TextStyle(color: AppColors.yellow, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            const Spacer(),
                            if (_dueDate != null)
                              Row(
                                children: [
                                  const Icon(Icons.alarm_rounded, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text('آخر موعد: ${_formatDate(_dueDate!)}', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _titleController,
                          label: 'عنوان الواجب أو التكليف',
                          hintText: 'مثال: حل تدريبات الدرس الأول من ص 15 إلى 20',
                          prefixIcon: Icons.assignment_outlined,
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
                          _buildStatBadge('تم التسليم', doneCount, AppColors.green),
                          const SizedBox(width: 6),
                          _buildStatBadge('لم يسلم', notDoneCount, AppColors.red),
                          const SizedBox(width: 14),
                          Container(width: 1, height: 24, color: AppColors.border),
                          const SizedBox(width: 10),
                          TextButton.icon(
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                            onPressed: () => _setAllStatus('done'),
                            icon: const Icon(Icons.check_circle_outline, size: 15, color: AppColors.green),
                            label: const Text('الكل سلّم', style: TextStyle(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.bold)),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                            onPressed: () => _setAllStatus('not_done'),
                            icon: const Icon(Icons.cancel_outlined, size: 15, color: AppColors.red),
                            label: const Text('الكل لم يسلم', style: TextStyle(fontSize: 12, color: AppColors.red, fontWeight: FontWeight.bold)),
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

                  // Students List
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

                  // Bottom Save & Exit Bar
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
                      text: '💾 حفظ متابعة الواجب والإنهاء',
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

  Widget _buildStudentCard(HomeworkRecordModel record, int index) {
    final isDone = record.status == 'done';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone ? AppColors.green.withValues(alpha: 0.4) : AppColors.red.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDone ? AppColors.green.withValues(alpha: 0.15) : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: isDone ? AppColors.green : AppColors.border),
            ),
            alignment: Alignment.center,
            child: Icon(
              isDone ? Icons.check_rounded : Icons.close_rounded,
              color: isDone ? AppColors.green : AppColors.textSecondary,
              size: 20,
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
          // Toggle Done Button
          InkWell(
            onTap: () => _toggleStatus(index),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDone ? AppColors.green : AppColors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDone ? AppColors.green : AppColors.red.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                    size: 16,
                    color: isDone ? Colors.black : AppColors.red,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isDone ? 'تم التسليم' : 'لم يسلم',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDone ? Colors.black : AppColors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
