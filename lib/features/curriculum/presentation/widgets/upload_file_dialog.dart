import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class UploadFileDialog extends StatefulWidget {
  final Function({
    required String title,
    required String fileName,
    required Uint8List fileBytes,
    required String fileType,
    required int fileSize,
  }) onUpload;

  const UploadFileDialog({super.key, required this.onUpload});

  static Future<void> show(
    BuildContext context, {
    required Function({
      required String title,
      required String fileName,
      required Uint8List fileBytes,
      required String fileType,
      required int fileSize,
    }) onUpload,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => UploadFileDialog(onUpload: onUpload),
    );
  }

  @override
  State<UploadFileDialog> createState() => _UploadFileDialogState();
}

class _UploadFileDialogState extends State<UploadFileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  PlatformFile? _pickedFile;
  bool _isPicking = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() => _isPicking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'zip', 'mp4', 'png', 'jpg'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _pickedFile = file;
          if (_titleController.text.trim().isEmpty) {
            _titleController.text = file.name.split('.').first;
          }
        });
      }
    } catch (e) {
      debugPrint('File picker error: $e');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _submit() {
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار ملف أولاً')),
      );
      return;
    }

      var bytes = _pickedFile!.bytes ?? Uint8List(0);
      if (bytes.isEmpty && _pickedFile!.path != null) {
        try {
          final file = File(_pickedFile!.path!);
          if (file.existsSync()) {
            bytes = file.readAsBytesSync();
          }
        } catch (e) {
          debugPrint('Error reading file bytes: $e');
        }
      }

      final ext = _pickedFile!.extension ?? 'pdf';
      final size = bytes.isNotEmpty ? bytes.length : _pickedFile!.size;

      widget.onUpload(
        title: _titleController.text.trim(),
        fileName: _pickedFile!.name,
        fileBytes: bytes,
        fileType: ext,
        fileSize: size,
      );
      Navigator.of(context).pop();
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
                    AppStrings.uploadFile,
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: AppColors.border, height: 24),

              // File Picker Box
              InkWell(
                onTap: _isPicking ? null : _pickFile,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _pickedFile != null ? AppColors.sage : AppColors.border,
                      width: _pickedFile != null ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _pickedFile != null ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
                        size: 36,
                        color: _pickedFile != null ? AppColors.sageDark : AppColors.primary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _pickedFile != null ? _pickedFile!.name : 'اضغط لاختيار ملف من جهازك',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _pickedFile != null ? AppColors.textPrimary : AppColors.sageDark,
                        ),
                      ),
                      if (_pickedFile != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'الحجم: ${DateFormatter.formatBytes(_pickedFile!.size)}  •  النوع: ${_pickedFile!.extension?.toUpperCase()}',
                          style: AppTextStyles.bodySmall,
                        ),
                      ] else ...[
                        const SizedBox(height: 4),
                        Text(
                          'PDF, Word, PowerPoint, ZIP, MP4 (بحد أقصى 50 ميجابايت)',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              CustomTextField(
                controller: _titleController,
                label: AppStrings.fileTitle,
                hintText: 'مثال: مذكرة شرح المتغيرات والعمليات',
                prefixIcon: Icons.title_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return AppStrings.requiredField;
                  return null;
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
                    text: 'رفع إلى الخادم',
                    variant: ButtonVariant.primary,
                    icon: Icons.upload_file,
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
