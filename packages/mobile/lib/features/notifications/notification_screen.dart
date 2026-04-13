import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/widgets/app_surface_card.dart';
import '../home/home_screen.dart';

/// 站内消息中心页面。
/// 点击消息后先标记已读，再根据 type 跳转到对应页面。
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<NotificationProvider>();
    provider.loadMessages();
    provider.loadUnreadCount();
  }

  /// 跳转规则：
  /// - reminder → tab 1（服药）
  /// - alert    → tab 2（药箱）
  /// - 其他     → 仅标记已读
  Future<void> _onTap(Map<String, dynamic> msg, NotificationProvider provider) async {
    final isRead = msg['isRead'] == true;
    final type = msg['type'] ?? 'info';

    // 先等标记已读完成，再跳转
    if (!isRead) await provider.markRead(msg['id']);

    // 根据 type 决定跳转目标
    int? targetTab;
    switch (type) {
      case 'reminder':
        targetTab = 1; // 服药
        break;
      case 'alert':
        targetTab = 2; // 药箱
        break;
      default:
        return; // info 类型仅标记已读，不跳转
    }

    // 先回到首页，再切换 tab
    if (!mounted) return;
    Navigator.popUntil(context, (route) => route.isFirst);
    homeScreenKey.currentState?.switchToTab(targetTab);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('消息中心'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () => provider.markAllRead(),
              child: const Text('全部已读'),
            ),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none, size: 64,
                           color: AppColors.textSecondary.withValues(alpha: 0.4)),
                      const SizedBox(height: AppSpacing.lg),
                      const Text('暂无消息', style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await provider.loadMessages();
                    await provider.loadUnreadCount();
                  },
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: provider.messages.length,
                        itemBuilder: (_, i) => _buildMessageCard(provider.messages[i], provider),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> msg, NotificationProvider provider) {
    final isRead = msg['isRead'] == true;
    final type = msg['type'] ?? 'info';

    IconData icon;
    Color color;
    String? trailingLabel;
    switch (type) {
      case 'reminder':
        icon = Icons.alarm;
        color = AppColors.primary;
        trailingLabel = '查看服药';
        break;
      case 'alert':
        icon = Icons.warning_amber;
        color = AppColors.danger;
        trailingLabel = '查看药箱';
        break;
      default:
        icon = Icons.info_outline;
        color = AppColors.textSecondary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppSurfaceCard(
        onTap: () => _onTap(msg, provider),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: AppRadius.mdBorder),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(msg['title'] ?? '', style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.w600, fontSize: 15)),
                      ),
                      if (!isRead)
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(msg['body'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Text(_formatTime(msg['createdAt']), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      if (trailingLabel != null) ...[
                        const Spacer(),
                        Text('$trailingLabel →', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String? time) {
    if (time == null) return '';
    try {
      final dt = DateTime.parse(time).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
      if (diff.inDays < 1) return '${diff.inHours}小时前';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return '';
    }
  }
}
