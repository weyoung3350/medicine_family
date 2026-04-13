import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// 统一表面卡片：白底、统一圆角、极轻阴影、可选点击。
class AppSurfaceCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const AppSurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdBorder,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.mdBorder,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mdBorder,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
