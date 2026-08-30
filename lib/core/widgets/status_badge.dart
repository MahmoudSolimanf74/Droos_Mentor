import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../theme/text_styles.dart';

enum BadgeVariant {
  success,
  warning,
  danger,
  info,
  neutral,
  bronze,
  sage,
}

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final Color? color;
  final IconData? icon;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.neutral,
    this.color,
    this.icon,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Color fgColor;
    Color bgColor;
    Color borderColor;

    if (color != null) {
      fgColor = color!;
      bgColor = color!.withValues(alpha: 0.15);
      borderColor = color!.withValues(alpha: 0.35);
    } else {
      final tuple = switch (variant) {
        BadgeVariant.success => (AppColors.successBg, AppColors.success, AppColors.success.withValues(alpha: 0.35)),
        BadgeVariant.warning => (AppColors.warningBg, AppColors.warning, AppColors.warning.withValues(alpha: 0.35)),
        BadgeVariant.danger => (AppColors.dangerBg, AppColors.danger, AppColors.danger.withValues(alpha: 0.35)),
        BadgeVariant.info => (AppColors.infoBg, AppColors.info, AppColors.info.withValues(alpha: 0.35)),
        BadgeVariant.neutral => (AppColors.surfaceMuted, AppColors.textSecondary, AppColors.border),
        BadgeVariant.bronze => (AppColors.yellow.withValues(alpha: 0.15), AppColors.yellow, AppColors.yellow.withValues(alpha: 0.35)),
        BadgeVariant.sage => (AppColors.green.withValues(alpha: 0.15), AppColors.green, AppColors.green.withValues(alpha: 0.35)),
      };
      bgColor = tuple.$1;
      fgColor = tuple.$2;
      borderColor = tuple.$3;
    }

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fgColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w700,
              fontSize: fontSize ?? 11,
            ),
          ),
        ],
      ),
    );
  }
}
