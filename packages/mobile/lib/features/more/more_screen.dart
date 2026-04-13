import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/providers/elder_mode_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/widgets/app_drilldown_tile.dart';
import '../../core/widgets/app_surface_card.dart';
import '../notifications/notification_screen.dart';
import '../medical_record/medical_record_screen.dart';
import '../pharmacy/pharmacy_screen.dart';
import '../family/family_screen.dart';
import '../settings/settings_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});
  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  bool _notifLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUnread();
  }

  Future<void> _loadUnread() async {
    if (_notifLoaded) return;
    _notifLoaded = true;
    await context.read<NotificationProvider>().loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    final elderMode = context.watch<ElderModeProvider>();
    final notifications = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('更多')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppDrilldownTile(
            icon: Icons.notifications_outlined,
            title: '消息中心',
            subtitle: notifications.unreadCount > 0 ? '${notifications.unreadCount} 条未读消息' : '查看历史通知消息',
            badge: notifications.unreadCount,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
          ),
          const SizedBox(height: AppSpacing.md),

          // 长辈模式 — 特殊：有 Switch，不用 drilldown
          AppSurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.smBorder),
                  child: const Icon(Icons.elderly, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('长辈模式', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                      const Padding(padding: EdgeInsets.only(top: 2), child: Text('大字体、大按钮、极简打卡', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))),
                    ],
                  ),
                ),
                Switch(
                  value: elderMode.enabled,
                  onChanged: (_) => elderMode.toggle(),
                  activeTrackColor: AppColors.primary,
                  activeThumbColor: AppColors.surface,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          AppDrilldownTile(
            icon: Icons.description_outlined,
            title: '病历管理',
            subtitle: '查看和管理家庭病历记录',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicalRecordScreen())),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDrilldownTile(
            icon: Icons.local_pharmacy_outlined,
            title: '附近药店',
            subtitle: '查找周边药店信息',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PharmacyScreen())),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDrilldownTile(
            icon: Icons.family_restroom,
            title: '家庭管理',
            subtitle: '管理家庭成员与健康档案',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyScreen())),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDrilldownTile(
            icon: Icons.settings_outlined,
            title: '设置',
            subtitle: '账户信息与系统设置',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }
}
