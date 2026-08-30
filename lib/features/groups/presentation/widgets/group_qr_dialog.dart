import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/group_model.dart';

class GroupQrDialog extends StatefulWidget {
  final GroupModel group;
  final Future<String> Function() onRegenerateToken;
  final Future<void> Function(bool isActive)? onToggleActive;

  const GroupQrDialog({
    super.key,
    required this.group,
    required this.onRegenerateToken,
    this.onToggleActive,
  });

  static Future<void> show(
    BuildContext context, {
    required GroupModel group,
    required Future<String> Function() onRegenerateToken,
    Future<void> Function(bool isActive)? onToggleActive,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => GroupQrDialog(
        group: group,
        onRegenerateToken: onRegenerateToken,
        onToggleActive: onToggleActive,
      ),
    );
  }

  @override
  State<GroupQrDialog> createState() => _GroupQrDialogState();
}

class _GroupQrDialogState extends State<GroupQrDialog> {
  late String _currentInviteToken;
  late bool _isActive;
  bool _isRegenerating = false;

  @override
  void initState() {
    super.initState();
    _currentInviteToken = widget.group.inviteToken;
    _isActive = widget.group.isActive;
  }

  void _copyJoinCode() {
    Clipboard.setData(ClipboardData(text: widget.group.joinCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.copied),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _regenerateToken() async {
    setState(() => _isRegenerating = true);
    try {
      final newToken = await widget.onRegenerateToken();
      if (mounted) {
        setState(() {
          _currentInviteToken = newToken;
          _isRegenerating = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isRegenerating = false);
    }
  }

  Future<void> _toggleActive() async {
    final newStatus = !_isActive;
    if (widget.onToggleActive != null) {
      await widget.onToggleActive!(newStatus);
    }
    if (mounted) {
      setState(() => _isActive = newStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrData = 'classpilot://join?token=$_currentInviteToken&code=${widget.group.joinCode}';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.group.name,
                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.group.gradeName,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
                StatusBadge(
                  label: _isActive ? 'الانضمام مفتوح' : 'الانضمام معطل',
                  variant: _isActive ? BadgeVariant.success : BadgeVariant.danger,
                ),
              ],
            ),
            const Divider(color: AppColors.border, height: 28),
            if (_isActive) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppColors.primary,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'امسح الرمز عبر تطبيق الطالب للانضمام مباشرة',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            ] else ...[
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline, size: 40, color: AppColors.textMuted),
                    const SizedBox(height: 8),
                    Text(
                      'تم تعطيل الانضمام للمجموعة',
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            // Join Code Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'كود الانضمام المباشر:',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.group.joinCode,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20, color: AppColors.primary),
                    tooltip: AppStrings.copy,
                    onPressed: _copyJoinCode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomButton(
                  text: _isActive ? 'تعطيل الرمز' : 'تفعيل الرمز',
                  variant: _isActive ? ButtonVariant.outline : ButtonVariant.secondary,
                  icon: _isActive ? Icons.block : Icons.check_circle_outline,
                  onPressed: _toggleActive,
                ),
                CustomButton(
                  text: 'تجديد الرمز',
                  variant: ButtonVariant.outline,
                  icon: Icons.refresh,
                  isLoading: _isRegenerating,
                  onPressed: _regenerateToken,
                ),
              ],
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: AppStrings.close,
              variant: ButtonVariant.primary,
              isFullWidth: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
