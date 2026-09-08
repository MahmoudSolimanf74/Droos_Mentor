import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../theme/text_styles.dart';

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final Color? iconColor;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.color,
    this.iconColor,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? iconColor ?? AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Right vertical colored indicator stripe
            Positioned(
              top: -12,
              bottom: -12,
              right: -14,
              width: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: effectiveColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 4),
                      Icon(icon, size: 16, color: effectiveColor.withValues(alpha: 0.7)),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    value,
                    style: AppTextStyles.monoStat.copyWith(
                      fontSize: 22,
                      color: effectiveColor,
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textFaint),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
