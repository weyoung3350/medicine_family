import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/providers/family_provider.dart';
import '../../core/providers/medication_provider.dart';
import '../../core/providers/medicine_provider.dart';
import '../../core/widgets/app_surface_card.dart';
import '../../core/widgets/member_selector.dart';
import '../medicine/medicine_detail_screen.dart';
import 'create_plan_screen.dart';

class PlansTab extends StatefulWidget {
  const PlansTab({super.key});
  @override
  State<PlansTab> createState() => _PlansTabState();
}

class _PlansTabState extends State<PlansTab> {
  bool _loading = true;
  String? _selectedMemberId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final family = context.read<FamilyProvider>();
    if (family.currentFamilyId == null) await family.loadFamilies();
    if (family.members.isNotEmpty) {
      _selectedMemberId ??= _pickDefault(family.members);
      await _loadPlans();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadPlans() async {
    if (_selectedMemberId == null) return;
    final family = context.read<FamilyProvider>();
    if (family.currentFamilyId == null) return;
    await context.read<MedicationProvider>().loadPlans(family.currentFamilyId!, _selectedMemberId!);
  }

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyProvider>();
    final medication = context.watch<MedicationProvider>();

    return Scaffold(
      floatingActionButton: medication.plans.isNotEmpty
          ? FloatingActionButton(
              onPressed: _goCreatePlan,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Column(
      children: [
        // Member selector
        if (family.members.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
            child: MemberSelector(
              members: family.members,
              selectedId: _selectedMemberId,
              onChanged: (id) { setState(() => _selectedMemberId = id); _loadPlans(); },
            ),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : medication.plans.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_note, size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
                          const SizedBox(height: AppSpacing.lg),
                          const Text('暂无服药计划', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                          const SizedBox(height: AppSpacing.lg),
                          ElevatedButton.icon(
                            onPressed: () => _goCreatePlan(),
                            icon: const Icon(Icons.add),
                            label: const Text('创建计划'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPlans,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: medication.plans.length,
                        itemBuilder: (context, i) => _buildPlanCard(medication.plans[i]),
                      ),
                    ),
        ),
      ],
      ),
    );
  }

  void _goCreatePlan() async {
    final family = context.read<FamilyProvider>();
    if (family.currentFamilyId == null || _selectedMemberId == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePlanScreen(
          familyId: family.currentFamilyId!,
          memberId: _selectedMemberId!,
        ),
      ),
    );
    if (result == true) {
      _loadPlans();
    }
  }

  Widget _buildPlanCard(dynamic plan) {
    final medicine = plan['medicine'];
    final schedules = plan['schedules'] as List? ?? [];
    final frequencyType = plan['frequencyType'] ?? '';
    final isActive = plan['isActive'] ?? true;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppSurfaceCard(
        onTap: () => _showPlanDetail(plan),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primaryLight : Colors.grey[100],
                    borderRadius: AppRadius.mdBorder,
                  ),
                  child: Icon(Icons.medication, color: isActive ? AppColors.primary : Colors.grey, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine?['name'] ?? '药品',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${plan['dosageAmount'] ?? ''}${plan['dosageUnit'] ?? ''} · ${_getFreqLabel(frequencyType)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.success.withValues(alpha: 0.1) : Colors.grey[100],
                    borderRadius: AppRadius.smBorder,
                  ),
                  child: Text(
                    isActive ? '进行中' : '已结束',
                    style: TextStyle(
                      color: isActive ? AppColors.success : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Meal relation
            Row(
              children: [
                const Icon(Icons.restaurant, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Text(_getMealLabel(plan['mealRelation']), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Schedule time tags
            if (schedules.isNotEmpty)
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: schedules.map<Widget>((s) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: AppRadius.smBorder,
                    ),
                    child: Text(
                      '${s['timeOfDay'] ?? ''} ${s['label'] ?? ''}',
                      style: const TextStyle(color: AppColors.primary, fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: AppSpacing.sm),
            // Date range
            Row(
              children: [
                const Icon(Icons.date_range, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${plan['startDate'] ?? ''}${plan['endDate'] != null ? ' ~ ${plan['endDate']}' : ' ~ 长期'}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPlanDetail(dynamic plan) {
    final medicine = plan['medicine'];
    final schedules = plan['schedules'] as List? ?? [];
    final isActive = plan['isActive'] ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.35,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  // 状态
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: (isActive ? AppColors.success : Colors.grey).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(isActive ? '进行中' : '已结束', style: TextStyle(color: isActive ? AppColors.success : Colors.grey, fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(child: Text(medicine?['name'] ?? '药品', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                  const SizedBox(height: AppSpacing.xl),
                  _planDetailRow(Icons.medical_services, '剂量', '${plan['dosageAmount'] ?? ''}${plan['dosageUnit'] ?? ''}'),
                  _planDetailRow(Icons.repeat, '频次', _getFreqLabel(plan['frequencyType'] ?? '')),
                  _planDetailRow(Icons.restaurant, '饭前饭后', _getMealLabel(plan['mealRelation'])),
                  _planDetailRow(Icons.date_range, '起始日期', plan['startDate'] ?? ''),
                  _planDetailRow(Icons.event, '结束日期', plan['endDate'] ?? '长期'),
                  if (schedules.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const Text('服药时间', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: schedules.map<Widget>((s) => Chip(
                        label: Text('${s['timeOfDay'] ?? ''} ${s['label'] ?? ''}'),
                        backgroundColor: AppColors.primaryLight,
                        labelStyle: const TextStyle(color: AppColors.primary, fontSize: 13),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  // 查看药品详情
                  OutlinedButton.icon(
                    onPressed: () => _openMedicineFromPlan(medicine),
                    icon: const Icon(Icons.medication, size: 18),
                    label: const Text('查看药品详情'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planDetailRow(IconData icon, String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _openMedicineFromPlan(dynamic medicine) async {
    if (medicine == null || medicine['id'] == null) return;
    final family = context.read<FamilyProvider>();
    if (family.currentFamilyId == null) return;
    try {
      final detail = await context.read<MedicineProvider>().getMedicineDetail(family.currentFamilyId!, medicine['id']);
      if (mounted) MedicineDetailSheet.show(context, detail);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('无法加载药品详情')));
    }
  }

  String _getFreqLabel(String freq) {
    const m = {
      'daily': '每日',
      'every_other_day': '隔日',
      'weekly': '每周',
      'custom': '自定义',
    };
    return m[freq] ?? freq;
  }

  String _getMealLabel(String? r) {
    const m = {'before_meal': '饭前', 'after_meal': '饭后', 'with_meal': '随餐', 'empty_stomach': '空腹', 'anytime': '不限'};
    return m[r] ?? '不限';
  }

  static String _pickDefault(List<dynamic> members) {
    final dep = members.where((m) => m['role'] == 'dependent').toList();
    return (dep.isNotEmpty ? dep.first : members.first)['id'];
  }
}
