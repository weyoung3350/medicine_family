import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/providers/family_provider.dart';
import '../../core/providers/medication_provider.dart';
import '../../core/widgets/app_surface_card.dart';
import '../../core/widgets/member_selector.dart';
import 'medication_event_detail_sheet.dart';

class TodayScreen extends StatefulWidget {
  final bool embedded;
  const TodayScreen({super.key, this.embedded = false});
  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  bool _loading = true;
  String? _selectedMemberId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final family = context.read<FamilyProvider>();
    await family.loadFamilies();
    if (family.members.isNotEmpty) {
      _selectedMemberId = _pickDefaultMember(family.members);
      await _loadToday();
    }
    setState(() => _loading = false);
  }

  Future<void> _loadToday() async {
    if (_selectedMemberId == null) return;
    final family = context.read<FamilyProvider>();
    if (family.currentFamilyId == null) return;
    await context.read<MedicationProvider>().loadToday(family.currentFamilyId!, _selectedMemberId!);
  }

  Future<void> _checkIn(dynamic item, bool skip) async {
    final family = context.read<FamilyProvider>();
    final planId = item['planId'] ?? item['plan']?['id'] ?? '';
    final scheduleId = item['scheduleId'] ?? item['schedule']?['id'] ?? '';
    if (planId.isEmpty || scheduleId.isEmpty) return;
    try {
      await context.read<MedicationProvider>().checkIn(
        family.currentFamilyId!,
        _selectedMemberId!,
        planId,
        scheduleId,
        skip: skip,
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(skip ? '已跳过' : '打卡成功'), backgroundColor: skip ? Colors.grey : AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e'), backgroundColor: AppColors.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyProvider>();
    final medication = context.watch<MedicationProvider>();

    final body = _loading
          ? const Center(child: CircularProgressIndicator())
          : medication.todayItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: AppColors.success.withValues(alpha: 0.5)),
                      const SizedBox(height: AppSpacing.lg),
                      const Text('今日暂无服药计划', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadToday,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: medication.todayItems.length,
                    itemBuilder: (context, index) {
                      final item = medication.todayItems[index];
                      return _buildMedCard(item);
                    },
                  ),
                );

    if (widget.embedded) {
      return Column(
        children: [
          if (family.members.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
              child: MemberSelector(
                members: family.members,
                selectedId: _selectedMemberId,
                onChanged: (id) { setState(() => _selectedMemberId = id); _loadToday(); },
              ),
            ),
          Expanded(child: body),
        ],
      );
    }

    return Column(
      children: [
        if (family.members.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
            child: MemberSelector(
              members: family.members,
              selectedId: _selectedMemberId,
              onChanged: (id) { setState(() => _selectedMemberId = id); _loadToday(); },
            ),
          ),
        Expanded(child: body),
      ],
    );
  }

  Widget _buildMedCard(dynamic item) {
    // 兼容扁平和嵌套两种格式
    final status = item['status'] ?? item['log']?['status'] ?? 'pending';
    final medicineName = item['medicineName'] ?? item['medicine']?['name'] ?? '药品';
    final scheduledTime = item['scheduledTime'] ?? item['schedule']?['timeOfDay'] ?? '';
    final timeLabel = item['timeLabel'] ?? item['schedule']?['label'] ?? '';
    final dosageAmount = item['dosageAmount'] ?? item['plan']?['dosageAmount'] ?? '';
    final dosageUnit = item['dosageUnit'] ?? item['plan']?['dosageUnit'] ?? '';
    final mealRelation = item['mealRelation'] ?? item['plan']?['mealRelation'] ?? '';

    Color statusColor;
    IconData statusIcon;
    String statusText;
    switch (status) {
      case 'taken':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusText = '已服用';
        break;
      case 'missed':
        statusColor = AppColors.danger;
        statusIcon = Icons.cancel;
        statusText = '漏服';
        break;
      case 'skipped':
        statusColor = Colors.grey;
        statusIcon = Icons.remove_circle;
        statusText = '已跳过';
        break;
      default:
        statusColor = AppColors.primary;
        statusIcon = Icons.access_time;
        statusText = '待服用';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppSurfaceCard(
        onTap: () => MedicationEventDetailSheet.show(context, Map<String, dynamic>.from(item), memberId: _selectedMemberId),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: AppRadius.smBorder,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: AppSpacing.xs),
                      Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '$scheduledTime $timeLabel',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              medicineName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$dosageAmount$dosageUnit · ${_getMealLabel(mealRelation)}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            if (status == 'pending') ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _checkIn(item, false),
                  icon: const Icon(Icons.check_circle, size: 28),
                  label: const Text('我已服药', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: TextButton(
                  onPressed: () => _checkIn(item, true),
                  child: const Text('跳过本次', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ],
            if (status == 'taken') ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: AppRadius.lgBorder,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success, size: 24),
                    SizedBox(width: AppSpacing.sm),
                    Text('已完成服药', style: TextStyle(color: AppColors.success, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getMealLabel(String? r) {
    const m = {'before_meal': '饭前', 'after_meal': '饭后', 'with_meal': '随餐', 'empty_stomach': '空腹', 'anytime': '不限'};
    return m[r] ?? '';
  }

  /// dependent 优先，避免默认选到没有服药计划的 owner
  static String _pickDefaultMember(List<dynamic> members) {
    final dep = members.where((m) => m['role'] == 'dependent').toList();
    return (dep.isNotEmpty ? dep.first : members.first)['id'];
  }
}
