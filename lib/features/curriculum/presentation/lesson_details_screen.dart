import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../domain/lesson_file_model.dart';
import '../domain/lesson_model.dart';
import 'curriculum_cubit.dart';
import 'widgets/upload_file_dialog.dart';

class LessonDetailsScreen extends StatefulWidget {
  final LessonModel lesson;
  final String unitTitle;
  final String gradeId;

  const LessonDetailsScreen({
    super.key,
    required this.lesson,
    required this.unitTitle,
    required this.gradeId,
  });

  @override
  State<LessonDetailsScreen> createState() => _LessonDetailsScreenState();
}

class _LessonDetailsScreenState extends State<LessonDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CurriculumCubit>().selectLesson(widget.lesson.id);
  }

  void _openUploadDialog() {
    UploadFileDialog.show(
      context,
      onUpload: ({
        required String title,
        required String fileName,
        required dynamic fileBytes,
        required String fileType,
        required int fileSize,
      }) {
        context.read<CurriculumCubit>().uploadFile(
              title: title,
              fileName: fileName,
              fileBytes: fileBytes,
              fileType: fileType,
              fileSize: fileSize,
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.lesson.title, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            Text(widget.unitTitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_rounded),
            tooltip: 'رفع ملف PDF جديد',
            onPressed: _openUploadDialog,
          ),
        ],
      ),
      body: BlocBuilder<CurriculumCubit, CurriculumState>(
        builder: (context, state) {
          if (state is CurriculumLoading) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }

          final files = state is CurriculumLoaded ? state.files : <LessonFileModel>[];
          final isUploading = state is CurriculumLoaded && state.isUploading;

          return SafeArea(
            child: Column(
              children: [
                // Top Info Card
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.menu_book_rounded, color: AppColors.cyan, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.lesson.title, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 3),
                            Text('الوحدة: ${widget.unitTitle}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cyan,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('رفع PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: _openUploadDialog,
                      ),
                    ],
                  ),
                ),

                if (isUploading)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('جاري رفع ومعالجة الملف إلى السيرفر...', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),

                // Files Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ملفات ومذكرات هذا الدرس (${files.length})',
                        style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // Files List
                Expanded(
                  child: files.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.picture_as_pdf_outlined, size: 54, color: AppColors.textFaint),
                              const SizedBox(height: 12),
                              Text('لا توجد ملفات مرفوعة لهذا الدرس حتى الآن', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary)),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.cyan, foregroundColor: Colors.black),
                                icon: const Icon(Icons.upload_file_rounded),
                                label: const Text('رفع أول مذكرة أو ملخص', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: _openUploadDialog,
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: files.length,
                          separatorBuilder: (context, i) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final f = files[i];
                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.red.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.red, size: 22),
                                ),
                                title: Text(f.fileName, style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  '${(f.fileSize / 1024).toStringAsFixed(1)} KB • نوع: ${f.fileType.toUpperCase()}',
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red, size: 20),
                                  tooltip: 'حذف الملف',
                                  onPressed: () {
                                    context.read<CurriculumCubit>().deleteFile(f.id, f.storagePath);
                                  },
                                ),
                              ),
                            );
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
                    text: '💾 إغلاق وحفظ',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
