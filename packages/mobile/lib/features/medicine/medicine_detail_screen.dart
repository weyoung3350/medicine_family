import 'package:flutter/material.dart';
import '../../app/theme.dart';

class MedicineDetailSheet extends StatelessWidget {
  final Map<String, dynamic> medicine;
  /// embedded=true 时作为右侧面板渲染，不使用 DraggableScrollableSheet
  final bool embedded;
  const MedicineDetailSheet({super.key, required this.medicine, this.embedded = false});

  static void show(BuildContext context, Map<String, dynamic> medicine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MedicineDetailSheet(medicine: medicine),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventories = medicine['inventories'] as List? ?? [];

    if (embedded) return _buildContent(inventories, null);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: AppRadius.smBorder),
          ),
          Expanded(child: _buildContent(inventories, scrollCtrl)),
        ],
      ),
    );
  }

  Widget _buildContent(List inventories, ScrollController? scrollCtrl) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.mdBorder,
                ),
                child: const Icon(Icons.medication, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine['name'] ?? '',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (medicine['brandName'] != null)
                      Text(medicine['brandName'], style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (medicine['category'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: AppRadius.smBorder,
                  ),
                  child: Text(medicine['category'], style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _infoSection('基本信息', [
                _infoRow('规格', medicine['specification']),
                _infoRow('剂型', medicine['dosageForm']),
                _infoRow('单位', medicine['unit']),
                _infoRow('厂家', medicine['manufacturer']),
                _infoRow('批准文号', medicine['approvalNumber']),
              ]),
              const SizedBox(height: AppSpacing.lg),
              _infoSection('用药信息', [
                _infoRow('适应症', medicine['indications']),
                _infoRow('用法用量', medicine['usageGuide']),
                _infoRow('禁忌', medicine['contraindications']),
                _infoRow('不良反应', medicine['sideEffects']),
                _infoRow('药物相互作用', medicine['interactions']),
              ]),
              if (inventories.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                const Text('库存记录', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: AppSpacing.sm),
                ...inventories.map((inv) => _inventoryCard(inv)),
              ],
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoSection(String title, List<Widget> children) {
    final filtered = children.where((w) => w is! SizedBox).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: AppSpacing.sm),
        ...children,
      ],
    );
  }

  Widget _infoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _inventoryCard(dynamic inv) {
    final remaining = inv['remainingQty'] ?? 0;
    final isLow = inv['isLowStock'] == true;
    final status = inv['status'];
    String statusText;
    Color statusColor;

    switch (status) {
      case 2:
        statusText = '临期';
        statusColor = AppColors.accent;
        break;
      case 3:
        statusText = '已过期';
        statusColor = AppColors.danger;
        break;
      case 4:
        statusText = '已用完';
        statusColor = Colors.grey;
        break;
      default:
        statusText = '正常';
        statusColor = AppColors.success;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgMain,
        borderRadius: AppRadius.mdBorder,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (inv['batchNumber'] != null)
                  Text('批号: ${inv['batchNumber']}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                if (inv['expiryDate'] != null)
                  Text('有效期: ${inv['expiryDate']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '剩余 $remaining',
                style: TextStyle(
                  color: isLow ? AppColors.danger : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: AppRadius.smBorder,
                ),
                child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
