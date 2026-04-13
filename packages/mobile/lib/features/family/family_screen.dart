import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/family_provider.dart';
import 'health_profile_screen.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});
  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  @override
  void initState() {
    super.initState();
    context.read<FamilyProvider>().loadFamilies();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final family = context.watch<FamilyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('家庭管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 用户信息卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      (auth.user?['nickname'] ?? 'U')[0],
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(auth.user?['nickname'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      Text(auth.user?['phone'] ?? '', style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 家庭列表
          Row(
            children: [
              const Text('我的家庭', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('创建'),
              ),
              TextButton.icon(
                onPressed: _showJoinDialog,
                icon: const Icon(Icons.group_add, size: 18),
                label: const Text('加入'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (family.families.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('还没有家庭，请创建或加入'))))
          else
            ...family.families.map((f) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: f['id'] == family.currentFamilyId
                    ? const BorderSide(color: AppColors.primary, width: 2)
                    : BorderSide.none,
              ),
              child: ListTile(
                leading: const Icon(Icons.home, color: AppColors.primary),
                title: Text(f['name'] ?? ''),
                subtitle: Text('邀请码: ${f['inviteCode'] ?? ''}'),
                trailing: f['id'] == family.currentFamilyId
                    ? const Icon(Icons.check_circle, color: AppColors.success)
                    : null,
                onTap: () => family.setCurrentFamily(f['id']),
              ),
            )),

          const SizedBox(height: 24),

          // 成员列表
          if (family.members.isNotEmpty) ...[
            const Text('家庭成员', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...family.members.map((m) {
              final hp = m['healthProfile'];
              final diseases = (hp?['medicalHistory'] as List?)?.join(', ') ?? '';
              final allergies = (hp?['allergyList'] as List?)?.join(', ') ?? '';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: m['role'] == 'dependent' ? AppColors.accent.withValues(alpha: 0.2) : AppColors.primaryLight,
                        child: Text(
                          (m['displayName'] ?? '?')[0],
                          style: TextStyle(color: m['role'] == 'dependent' ? AppColors.accent : AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(m['displayName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(_getRoleLabel(m['role']), style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                                ),
                              ],
                            ),
                            if (diseases.isNotEmpty)
                              Text('病史: $diseases', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            if (allergies.isNotEmpty)
                              Text('过敏: $allergies', style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                        tooltip: '编辑健康档案',
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HealthProfileScreen(
                                familyId: family.currentFamilyId!,
                                member: Map<String, dynamic>.from(m),
                              ),
                            ),
                          );
                          if (result == true) family.loadMembers();
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  String _getRoleLabel(String? role) {
    const m = {'owner': '创建者', 'admin': '管理员', 'member': '成员', 'dependent': '被代管'};
    return m[role] ?? '';
  }

  void _showCreateDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('创建家庭'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: '家庭名称')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              await context.read<FamilyProvider>().createFamily(ctrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('加入家庭'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: '邀请码')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              await context.read<FamilyProvider>().joinFamily(ctrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('加入'),
          ),
        ],
      ),
    );
  }
}
