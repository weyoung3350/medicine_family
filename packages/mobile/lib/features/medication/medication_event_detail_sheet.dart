import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/providers/family_provider.dart';
import '../../core/providers/medication_provider.dart';
import '../../core/providers/medicine_provider.dart';
import '../medicine/medicine_detail_screen.dart';

/// 服药事件详情底部弹层。
///
/// 接收扁平结构的事件数据（与 API /plans/today 返回格式一致）：
///   medicineName, dosageAmount, dosageUnit, mealRelation,
///   scheduledTime, timeLabel, status, planId, scheduleId, logId
/// 以及 Dashboard 附加的 _memberName。
class MedicationEventDetailSheet extends StatelessWidget {
  final Map<String, dynamic> event;
  final String? memberId;
  final bool embedded;
  const MedicationEventDetailSheet({super.key, required this.event, this.memberId, this.embedded = false});

  static void show(BuildContext context, Map<String, dynamic> event, {String? memberId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => MedicationEventDetailSheet(event: event, memberId: memberId),
    );
  }

  // 兼容扁平和嵌套两种字段格式
  String _f(String flatKey, [String? nestedPath1, String? nestedPath2]) {
    // 优先取扁平字段
    final flat = event[flatKey];
    if (flat != null) return '$flat';
    // 回退到嵌套
    if (nestedPath1 != null && nestedPath2 != null) {
      final nested = event[nestedPath1];
      if (nested is Map) return '${nested[nestedPath2] ?? ''}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final medicineName = _f('medicineName', 'medicine', 'name');
    final dosageAmount = _f('dosageAmount', 'plan', 'dosageAmount');
    final dosageUnit = _f('dosageUnit', 'plan', 'dosageUnit');
    final mealRelation = _f('mealRelation', 'plan', 'mealRelation');
    final scheduledTime = _f('scheduledTime', 'schedule', 'timeOfDay');
    final timeLabel = _f('timeLabel', 'schedule', 'label');
    final status = event['status'] ?? event['log']?['status'] ?? 'pending';
    final memberName = event['_memberName'] ?? '';
    final planId = event['planId'] ?? event['plan']?['id'] ?? '';
    final scheduleId = event['scheduleId'] ?? event['schedule']?['id'] ?? '';

    final (statusColor, statusIcon, statusText) = _statusStyle(status);

    final contentChildren = <Widget>[
      Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.pill)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 20, color: statusColor),
              const SizedBox(width: AppSpacing.sm),
              Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      Center(child: Text(medicineName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
      const SizedBox(height: AppSpacing.xl),
      _detailRow(Icons.access_time, '服药时间', '$scheduledTime $timeLabel'),
      if (memberName.isNotEmpty) _detailRow(Icons.person, '服药人', memberName),
      _detailRow(Icons.medical_services, '剂量', '$dosageAmount$dosageUnit'),
      _detailRow(Icons.restaurant, '饭前饭后', _mealLabel(mealRelation)),
      const SizedBox(height: AppSpacing.xxl),
      if (status == 'pending') ...[
        _actionButton(context, '我已服药', AppColors.primary, Icons.check_circle, planId, scheduleId, false),
        const SizedBox(height: AppSpacing.md),
        _actionButton(context, '跳过本次', Colors.grey, Icons.remove_circle_outline, planId, scheduleId, true),
        const SizedBox(height: AppSpacing.lg),
      ],
      OutlinedButton.icon(
        onPressed: () => _openMedicineDetail(context, medicineName),
        icon: const Icon(Icons.medication, size: 18),
        label: const Text('查看药品详情'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
        ),
      ),
    ];

    if (embedded) {
      return ListView(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.all(AppSpacing.xl), children: contentChildren);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.85,
      minChildSize: 0.35,
      expand: false,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          Expanded(child: ListView(controller: scrollCtrl, padding: const EdgeInsets.all(AppSpacing.xl), children: contentChildren)),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
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

  Widget _actionButton(BuildContext context, String text, Color color, IconData icon, String planId, String scheduleId, bool skip) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () => _doCheckIn(context, planId, scheduleId, skip),
        icon: Icon(icon, size: 22),
        label: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
        ),
      ),
    );
  }

  /// 确定成员 ID：显式传入 > event['_memberId']，不允许回退猜测
  String? get _resolvedMemberId => memberId ?? event['_memberId'] as String?;

  Future<void> _doCheckIn(BuildContext context, String planId, String scheduleId, bool skip) async {
    final mid = _resolvedMemberId;
    if (mid == null || mid.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('无法确定服药人，请从成员列表重新进入'), backgroundColor: AppColors.danger));
      }
      return;
    }
    final family = context.read<FamilyProvider>();
    if (family.currentFamilyId == null || planId.isEmpty || scheduleId.isEmpty) return;
    try {
      await context.read<MedicationProvider>().checkIn(family.currentFamilyId!, mid, planId, scheduleId, skip: skip);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(skip ? '已跳过' : '打卡成功'),
          backgroundColor: skip ? Colors.grey : AppColors.success,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e'), backgroundColor: AppColors.danger));
      }
    }
  }

  void _openMedicineDetail(BuildContext context, String medicineName) async {
    final family = context.read<FamilyProvider>();
    if (family.currentFamilyId == null) return;
    final medProv = context.read<MedicineProvider>();

    // 优先用 medicineId 直接拉取（最稳）
    final medicineId = event['medicineId'] ?? event['medicine']?['id'];
    if (medicineId != null && '$medicineId'.isNotEmpty) {
      try {
        final detail = await medProv.getMedicineDetail(family.currentFamilyId!, '$medicineId');
        if (context.mounted) {
          MedicineDetailSheet.show(context, detail);
          return;
        }
      } catch (_) {}
    }

    // 回退：按名称匹配已加载列表
    final match = medProv.medicines.cast<Map<String, dynamic>?>().firstWhere(
      (m) => m?['name'] == medicineName,
      orElse: () => null,
    );
    if (match != null && context.mounted) {
      try {
        final detail = await medProv.getMedicineDetail(family.currentFamilyId!, match['id']);
        if (context.mounted) MedicineDetailSheet.show(context, detail);
      } catch (_) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('无法加载药品详情')));
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('无法加载药品详情')));
    }
  }

  (Color, IconData, String) _statusStyle(String status) {
    switch (status) {
      case 'taken':
        return (AppColors.success, Icons.check_circle, '已服用');
      case 'missed':
        return (AppColors.danger, Icons.cancel, '漏服');
      case 'skipped':
        return (Colors.grey, Icons.remove_circle, '已跳过');
      default:
        return (AppColors.primary, Icons.access_time, '待服用');
    }
  }

  String _mealLabel(String r) {
    const m = {'before_meal': '饭前', 'after_meal': '饭后', 'with_meal': '随餐', 'empty_stomach': '空腹', 'anytime': '不限'};
    return m[r] ?? '';
  }
}
