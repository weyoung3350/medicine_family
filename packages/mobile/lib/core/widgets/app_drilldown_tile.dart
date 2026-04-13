import 'package:flutter/material.dart';
import '../../app/theme.dart';
import 'app_surface_card.dart';

/// 统一可下钻条目：左侧图标 + 标题/副标题 + 右侧箭头。
class AppDrilldownTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final int badge;
  final VoidCallback? onTap;

  const AppDrilldownTile({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor,
    this.iconBgColor,
    this.subtitle,
    this.trailing,
    this.badge = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBgColor ?? AppColors.primaryLight,
                  borderRadius: AppRadius.smBorder,
                ),
                child: Icon(icon, color: iconColor ?? AppColors.primary, size: 18),
              ),
              if (badge > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(8)),
                    child: Text(badge > 99 ? '99+' : '$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary, letterSpacing: -0.2)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
          if (onTap != null) ...[
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
          ],
        ],
      ),
    );
  }
}
