import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// 统一区块标题：图标 + 标题 + 可选右侧动作。
class AppSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: iconColor ?? AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: -0.3)),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
