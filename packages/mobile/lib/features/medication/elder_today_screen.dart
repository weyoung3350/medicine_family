import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/providers/elder_mode_provider.dart';
import '../../core/providers/family_provider.dart';
import '../../core/providers/medication_provider.dart';

/// 适老化今日服药页面。
/// 特点：超大字体、高对比度、一键打卡、最少操作步骤。
class ElderTodayScreen extends StatefulWidget {
  const ElderTodayScreen({super.key});
  @override
  State<ElderTodayScreen> createState() => _ElderTodayScreenState();
}

class _ElderTodayScreenState extends State<ElderTodayScreen> {
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
      final dep = family.members.where((m) => m['role'] == 'dependent').toList();
      _selectedMemberId ??= (dep.isNotEmpty ? dep.first : family.members[0])['id'];
      await _loadToday();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadToday() async {
    if (_selectedMemberId == null) return;
    final family = context.read<FamilyProvider>();
    if (family.currentFamilyId == null) return;
    await context.read<MedicationProvider>().loadToday(
      family.currentFamilyId!,
      _selectedMemberId!,
    );
  }

  Future<void> _checkIn(dynamic item, bool skip) async {
    final family = context.read<FamilyProvider>();
    try {
      await context.read<MedicationProvider>().checkIn(
        family.currentFamilyId!,
        _selectedMemberId!,
        item['planId'] ?? item['plan']?['id'],
        item['scheduleId'] ?? item['schedule']?['id'],
        skip: skip,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            skip ? '已跳过' : '服药成功！',
            style: const TextStyle(fontSize: 20),
          ),
          backgroundColor: skip ? Colors.grey : AppColors.success,
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('操作失败: $e', style: const TextStyle(fontSize: 18)),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyProvider>();
    final medication = context.watch<MedicationProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        toolbarHeight: 64,
        title: const Text(
          '今日服药',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          // 成员切换
          if (family.members.length > 1)
            PopupMenuButton<String>(
              icon: const Icon(Icons.person, size: 28, color: Colors.white),
              onSelected: (id) {
                setState(() => _selectedMemberId = id);
                _loadToday();
              },
              itemBuilder: (_) => family.members.map<PopupMenuEntry<String>>((m) {
                return PopupMenuItem(
                  value: m['id'],
                  child: Text(m['displayName'] ?? '', style: const TextStyle(fontSize: 20)),
                );
              }).toList(),
            ),
          // 退出老人模式
          IconButton(
            icon: const Icon(Icons.exit_to_app, size: 28, color: Colors.white),
            tooltip: '退出长辈模式',
            onPressed: () => context.read<ElderModeProvider>().setEnabled(false),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 4))
          : RefreshIndicator(
              onRefresh: _loadToday,
              child: _buildBody(medication),
            ),
    );
  }

  Widget _buildBody(MedicationProvider medication) {
    // 当前选中成员名称
    final family = context.read<FamilyProvider>();
    final matched = family.members.where((m) => m['id'] == _selectedMemberId);
    final memberName = matched.isNotEmpty ? (matched.first['displayName'] ?? '') : '';

    if (medication.todayItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 96, color: AppColors.success.withValues(alpha: 0.6)),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              memberName.isNotEmpty ? '$memberName 今日无需服药' : '今日无需服药',
              style: const TextStyle(fontSize: 24, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // 分离待处理和已完成
    final pending = medication.todayItems.where((i) => (i['status'] ?? i['log']?['status'] ?? 'pending') == 'pending').toList();
    final done = medication.todayItems.where((i) => (i['status'] ?? i['log']?['status'] ?? 'pending') != 'pending').toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        if (memberName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Text(
              '$memberName 的服药清单',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
        // 待服药（大卡片）
        ...pending.map((item) => _buildElderCard(item)),
        // 已完成（紧凑显示）
        if (done.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            '已完成 (${done.length})',
            style: const TextStyle(fontSize: 20, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...done.map((item) => _buildDoneCard(item)),
        ],
      ],
    );
  }

  Widget _buildElderCard(dynamic item) {
    final scheduledTime = item['scheduledTime'] ?? item['schedule']?['timeOfDay'] ?? '';
    final timeLabel = item['timeLabel'] ?? item['schedule']?['label'] ?? '';
    final medicineName = item['medicineName'] ?? item['medicine']?['name'] ?? '药品';
    final dosageAmount = item['dosageAmount'] ?? item['plan']?['dosageAmount'] ?? '';
    final dosageUnit = item['dosageUnit'] ?? item['plan']?['dosageUnit'] ?? '';
    final mealRelation = item['mealRelation'] ?? item['plan']?['mealRelation'];

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg + 4)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 时间 + 标签
            Row(
              children: [
                const Icon(Icons.access_time, size: 28, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '$scheduledTime',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '$timeLabel',
                  style: const TextStyle(fontSize: 22, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // 药品名称 — 超大
            Text(
              '$medicineName',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            // 剂量
            Text(
              '$dosageAmount$dosageUnit · ${_getMealLabel(mealRelation)}',
              style: const TextStyle(fontSize: 22, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            // 大按钮：我已服药
            SizedBox(
              width: double.infinity,
              height: 72,
              child: ElevatedButton.icon(
                onPressed: () => _checkIn(item, false),
                icon: const Icon(Icons.check_circle, size: 36),
                label: const Text('我已服药', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg + 4)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // 跳过按钮
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => _checkIn(item, true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
                ),
                child: const Text('跳过本次', style: TextStyle(fontSize: 20)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoneCard(dynamic item) {
    final medicineName = item['medicineName'] ?? item['medicine']?['name'] ?? '';
    final status = item['status'] ?? item['log']?['status'] ?? '';
    final scheduledTime = item['scheduledTime'] ?? item['schedule']?['timeOfDay'] ?? '';

    final isTaken = status == 'taken';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: isTaken ? const Color(0xFFF0F9F4) : AppColors.bgMain,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
        child: Row(
          children: [
            Icon(
              isTaken ? Icons.check_circle : Icons.remove_circle,
              size: 32,
              color: isTaken ? AppColors.success : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$medicineName',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '$scheduledTime · ${isTaken ? '已服用' : '已跳过'}',
                    style: const TextStyle(fontSize: 18, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMealLabel(String? r) {
    const m = {'before_meal': '饭前', 'after_meal': '饭后', 'with_meal': '随餐', 'empty_stomach': '空腹', 'anytime': '不限'};
    return m[r] ?? '';
  }
}
