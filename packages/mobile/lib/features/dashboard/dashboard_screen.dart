import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/providers/family_provider.dart';
import '../../core/providers/medicine_provider.dart';
import '../../core/providers/medication_provider.dart';
import '../../core/widgets/app_section_header.dart';
import '../../core/widgets/app_surface_card.dart';
import '../home/home_screen.dart';
import '../family/family_screen.dart';
import '../medicine/medicine_detail_screen.dart';
import '../medication/medication_event_detail_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  List<dynamic> _allTodayItems = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final family = context.read<FamilyProvider>();
    await family.loadFamilies();
    if (family.currentFamilyId == null) {
      setState(() => _loading = false);
      return;
    }

    final medProv = context.read<MedicineProvider>();
    final medcProv = context.read<MedicationProvider>();

    await Future.wait([
      medProv.loadMedicines(family.currentFamilyId!),
      medProv.loadExpiring(family.currentFamilyId!),
      medProv.loadLowStock(family.currentFamilyId!),
    ]);

    _allTodayItems = [];
    for (final m in family.members) {
      await medcProv.loadToday(family.currentFamilyId!, m['id']);
      _allTodayItems.addAll(medcProv.todayItems.map((item) => {
        ...Map<String, dynamic>.from(item),
        '_memberName': m['displayName'] ?? '',
        '_memberId': m['id'] ?? '',
      }));
    }

    if (family.members.isNotEmpty) {
      await medcProv.loadAdherence(family.currentFamilyId!, family.members[0]['id']);
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyProvider>();
    final medProv = context.watch<MedicineProvider>();
    final medcProv = context.watch<MedicationProvider>();

    final pendingCount = _allTodayItems.where((item) {
      final status = item['status'] ?? item['log']?['status'] ?? 'pending';
      return status == 'pending';
    }).length;

    final adherenceRate = medcProv.adherence?['adherenceRate'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('家庭健康管家'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () { setState(() => _loading = true); _loadData(); },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                children: [
                  // ── 家庭选择 ──
                  if (family.families.length > 1) ...[
                    AppSurfaceCard(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: family.currentFamilyId,
                          isExpanded: true,
                          icon: const Icon(Icons.expand_more, color: AppColors.textSecondary),
                          items: family.families.map<DropdownMenuItem<String>>((f) {
                            return DropdownMenuItem(value: f['id'], child: Text(f['name'] ?? ''));
                          }).toList(),
                          onChanged: (id) {
                            if (id != null) { family.setCurrentFamily(id); setState(() => _loading = true); _loadData(); }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // ── 指标卡：统一蓝色交互，数值突出 ──
                  Row(
                    children: [
                      _metricTile('${family.members.length}', '家庭成员', Icons.people_outline, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyScreen()));
                      }),
                      const SizedBox(width: AppSpacing.sm),
                      _metricTile('${medProv.medicines.length}', '药箱药品', Icons.medication_outlined, () {
                        homeScreenKey.currentState?.switchToTab(2);
                      }),
                      const SizedBox(width: AppSpacing.sm),
                      _metricTile('$pendingCount', '今日待服', Icons.schedule_outlined, () {
                        homeScreenKey.currentState?.switchToTab(1);
                      }),
                      const SizedBox(width: AppSpacing.sm),
                      _metricTile(
                        adherenceRate != null ? '${(adherenceRate as num).toStringAsFixed(0)}%' : '--',
                        '周依从率', Icons.insights_outlined, () {
                          homeScreenKey.currentState?.switchToTab(1);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── 临期药品预警 ──
                  if (medProv.expiringMeds.isNotEmpty) ...[
                    AppSectionHeader(title: '临期药品预警', icon: Icons.warning_amber_rounded, iconColor: AppColors.danger),
                    ...medProv.expiringMeds.map((med) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _alertTile(med['name'] ?? '', _getExpiryInfo(med), AppColors.danger, () => _openMedicineDetail(med)),
                    )),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // ── 库存不足提醒 ──
                  if (medProv.lowStockMeds.isNotEmpty) ...[
                    AppSectionHeader(title: '库存不足提醒', icon: Icons.inventory_2_outlined, iconColor: AppColors.warning),
                    ...medProv.lowStockMeds.map((med) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _alertTile(med['name'] ?? '', _getStockInfo(med), AppColors.warning, () => _openMedicineDetail(med)),
                    )),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // ── 今日服药时间轴 ──
                  AppSectionHeader(title: '今日服药', icon: Icons.timeline_outlined, iconColor: AppColors.primary),
                  if (_allTodayItems.isEmpty)
                    AppSurfaceCard(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_outline, size: 40, color: AppColors.success.withValues(alpha: 0.4)),
                            const SizedBox(height: AppSpacing.sm),
                            const Text('今日暂无服药计划', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._allTodayItems.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _timelineCard(item),
                    )),
                  const SizedBox(height: AppSpacing.section),
                ],
              ),
            ),
    );
  }

  // ── 指标卡：纯蓝交互色 ──
  Widget _metricTile(String value, String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: AppSurfaceCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const Spacer(),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5)),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, letterSpacing: -0.1)),
          ],
        ),
      ),
    );
  }

  // ── 预警条目 ──
  Widget _alertTile(String title, String subtitle, Color statusColor, VoidCallback onTap) {
    return AppSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(width: 3, height: 32, decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.textPrimary)),
                Text(subtitle, style: TextStyle(color: statusColor, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  // ── 时间轴卡片 ──
  Widget _timelineCard(dynamic item) {
    final status = item['status'] ?? item['log']?['status'] ?? 'pending';
    final memberName = item['_memberName'] ?? '';
    final medicineName = item['medicineName'] ?? item['medicine']?['name'] ?? '';
    final scheduledTime = item['scheduledTime'] ?? item['schedule']?['timeOfDay'] ?? '';
    final timeLabel = item['timeLabel'] ?? item['schedule']?['label'] ?? '';
    final dosageAmount = item['dosageAmount'] ?? item['plan']?['dosageAmount'] ?? '';
    final dosageUnit = item['dosageUnit'] ?? item['plan']?['dosageUnit'] ?? '';

    final (statusColor, statusText) = _statusPair(status);

    return AppSurfaceCard(
      onTap: () => MedicationEventDetailSheet.show(context, Map<String, dynamic>.from(item), memberId: item['_memberId']),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Text('$scheduledTime', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary, letterSpacing: -0.3)),
                Text('$timeLabel', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(width: 3, height: 36, decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$medicineName', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.textPrimary)),
                Text('$dosageAmount$dosageUnit · $memberName', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.08), borderRadius: AppRadius.smBorder),
            child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 16),
        ],
      ),
    );
  }

  (Color, String) _statusPair(String status) {
    switch (status) {
      case 'taken':  return (AppColors.success, '已服用');
      case 'missed': return (AppColors.danger, '漏服');
      case 'skipped': return (Colors.grey, '已跳过');
      default:       return (AppColors.primary, '待服用');
    }
  }

  Future<void> _openMedicineDetail(dynamic med) async {
    final family = context.read<FamilyProvider>();
    if (family.currentFamilyId == null) return;
    try {
      final detail = await context.read<MedicineProvider>().getMedicineDetail(family.currentFamilyId!, med['id']);
      if (mounted) MedicineDetailSheet.show(context, detail);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('无法加载药品详情')));
    }
  }

  String _getExpiryInfo(dynamic med) {
    final inventories = med['inventories'] as List? ?? [];
    for (final inv in inventories) {
      if (inv['expiryDate'] != null) return '有效期至: ${inv['expiryDate']}';
    }
    return '即将到期';
  }

  String _getStockInfo(dynamic med) {
    final inventories = med['inventories'] as List? ?? [];
    final totalRemaining = inventories.fold<int>(0, (sum, inv) => sum + ((inv['remainingQty'] ?? 0) as int));
    return '剩余: $totalRemaining${med['unit'] ?? ''}';
  }
}
