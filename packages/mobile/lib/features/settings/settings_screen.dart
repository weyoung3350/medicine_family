import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/app_surface_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppSurfaceCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    (user?['nickname'] ?? 'U')[0],
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  user?['nickname'] ?? '',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.lg),
                _infoRow(Icons.phone, '手机', user?['phone'] ?? '未设置'),
                _infoRow(Icons.email_outlined, '邮箱', user?['email'] ?? '未设置'),
                if (user?['createdAt'] != null)
                  _infoRow(Icons.calendar_today, '注册时间', _formatDate(user!['createdAt'])),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSurfaceCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('系统信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.md),
                _infoRow(Icons.info_outline, '版本', '1.0.0'),
                _infoRow(Icons.smart_toy_outlined, 'AI模型', 'Qwen (Vision + Function Calling)'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                auth.logout();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.logout, color: AppColors.danger),
              label: const Text('退出登录', style: TextStyle(color: AppColors.danger, fontSize: 16)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 60,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}
