import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/providers/family_provider.dart';
import '../../core/providers/medicine_provider.dart';
import '../../core/providers/medication_provider.dart';
import '../../core/widgets/app_drilldown_tile.dart';
import '../../core/widgets/app_surface_card.dart';
import '../home/home_screen.dart';
import '../family/family_screen.dart';
import '../medicine/medicine_detail_screen.dart';
import '../medication/medication_event_detail_sheet.dart';
import 'dashboard_helpers.dart';

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

  // ─────────────────────── 数据加载（不改） ───────────────────────
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
    var sourceIdx = 0;
    for (final m in family.members) {
      await medcProv.loadToday(family.currentFamilyId!, m['id']);
      for (final item in medcProv.todayItems) {
        _allTodayItems.add({
          ...Map<String, dynamic>.from(item),
          '_memberName': m['displayName'] ?? '',
          '_memberId': m['id'] ?? '',
          '_sourceIndex': sourceIdx++,
        });
      }
    }
    _allTodayItems.sort((a, b) => compareTimelineItems(a, b));
    if (family.members.isNotEmpty) {
      await medcProv.loadAdherence(
        family.currentFamilyId!,
        family.members[0]['id'],
      );
    }
    if (mounted) setState(() => _loading = false);
  }

  // ─────────────────────── 导航（不改） ───────────────────────
  Future<void> _openMedicineDetail(dynamic med) async {
    final family = context.read<FamilyProvider>();
    if (family.currentFamilyId == null) return;
    try {
      final detail = await context.read<MedicineProvider>().getMedicineDetail(
        family.currentFamilyId!,
        med['id'],
      );
      if (mounted) MedicineDetailSheet.show(context, detail);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('无法加载药品详情')));
      }
    }
  }

  // ─────────────────────── BUILD ───────────────────────
  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyProvider>();
    final medProv = context.watch<MedicineProvider>();
    final medcProv = context.watch<MedicationProvider>();
    final pendingCount = _allTodayItems
        .where(
          (i) => (i['status'] ?? i['log']?['status'] ?? 'pending') == 'pending',
        )
        .length;
    final adherenceRate = medcProv.adherence?['adherenceRate'];
    final familyName = family.families.isNotEmpty
        ? family.families.firstWhere(
                (f) => f['id'] == family.currentFamilyId,
                orElse: () => family.families.first,
              )['name'] ??
              ''
        : '';
    final isWide = MediaQuery.of(context).size.width >= 800;

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bgMain,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (isWide) {
      return _buildWideDashboard(
        context,
        family,
        medProv,
        medcProv,
        pendingCount,
        adherenceRate,
        familyName,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // ── 顶部：家庭身份 + 切换 ──
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: AppColors.bgMain,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: 56,
              title: Text(
                familyName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              centerTitle: false,
              actions: [
                if (family.families.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: TextButton.icon(
                      onPressed: () => _showFamilySwitcher(family),
                      icon: const Icon(Icons.expand_more, size: 18),
                      label: const Text('切换家庭', style: TextStyle(fontSize: 13)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() => _loading = true);
                    _loadData();
                  },
                ),
              ],
            ),

            // ── 内容 ──
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── 2×2 指标 Bento ──
                  _buildMetricsBento(
                    family,
                    medProv,
                    pendingCount,
                    adherenceRate,
                  ),
                  const SizedBox(height: AppSpacing.section),

                  // ── 临期药品预警 ──
                  if (medProv.expiringMeds.isNotEmpty) ...[
                    _sectionTitle('临期药品预警'),
                    const SizedBox(height: AppSpacing.md),
                    ...medProv.expiringMeds.map(
                      (med) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _expiryTile(med),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],

                  // ── 库存不足提醒 ──
                  if (medProv.lowStockMeds.isNotEmpty) ...[
                    _sectionTitle('库存不足提醒'),
                    const SizedBox(height: AppSpacing.md),
                    _stockList(medProv.lowStockMeds),
                    const SizedBox(height: AppSpacing.xxl),
                  ],

                  // ── 今日服药 ──
                  _sectionTitle('今日服药'),
                  const SizedBox(height: AppSpacing.md),
                  if (_allTodayItems.isEmpty)
                    _emptySchedule()
                  else
                    _buildTimeline(),
                  // 底部留出足够空间避开 BottomNavigationBar + 安全区
                  SizedBox(
                    height:
                        kBottomNavigationBarHeight +
                        MediaQuery.of(context).padding.bottom +
                        AppSpacing.lg,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideDashboard(
    BuildContext context,
    FamilyProvider family,
    MedicineProvider medProv,
    MedicationProvider medcProv,
    int pendingCount,
    dynamic adherenceRate,
    String familyName,
  ) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final gap = AppSpacing.lg;
            final metricWidth = ((width - gap * 3) / 4)
                .clamp(180.0, 260.0)
                .toDouble();
            final leftWidth = (width * 0.35).clamp(340.0, 420.0).toDouble();

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              familyName.isNotEmpty ? familyName : '家庭健康概览',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.7,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Pad 控制台 · 集中查看家庭风险、库存与今日服药执行',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (family.families.length > 1)
                        TextButton.icon(
                          onPressed: () => _showFamilySwitcher(family),
                          icon: const Icon(Icons.swap_horiz, size: 18),
                          label: const Text('切换家庭'),
                        ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton(
                        onPressed: () {
                          setState(() => _loading = true);
                          _loadData();
                        },
                        icon: const Icon(
                          Icons.refresh,
                          color: AppColors.textSecondary,
                        ),
                        tooltip: '刷新',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      SizedBox(
                        width: metricWidth,
                        child: _wideMetricCard(
                          icon: Icons.family_restroom,
                          iconBg: AppColors.primaryLight,
                          iconColor: AppColors.primary,
                          value: '${family.members.length}',
                          label: '家庭成员',
                          unit: '位',
                          hint: '查看和管理代管成员',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FamilyScreen(),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: metricWidth,
                        child: _wideMetricCard(
                          icon: Icons.medical_services_outlined,
                          iconBg: const Color(0xFFEFFAF2),
                          iconColor: AppColors.success,
                          value: '${medProv.medicines.length}',
                          label: '药箱药品',
                          unit: '种',
                          hint: '药品库存与临期预警',
                          onTap: () =>
                              homeScreenKey.currentState?.switchToTab(2),
                        ),
                      ),
                      SizedBox(
                        width: metricWidth,
                        child: _wideMetricCard(
                          icon: Icons.schedule,
                          iconBg: const Color(0xFFFFF6E8),
                          iconColor: AppColors.warning,
                          value: '$pendingCount',
                          label: '今日待服',
                          unit: '次',
                          hint: '需要家属确认打卡',
                          onTap: () =>
                              homeScreenKey.currentState?.switchToTab(1),
                          isHero: true,
                        ),
                      ),
                      SizedBox(
                        width: metricWidth,
                        child: _wideMetricCard(
                          icon: Icons.show_chart,
                          iconBg: AppColors.primaryLight,
                          iconColor: AppColors.primary,
                          value: adherenceRate != null
                              ? (adherenceRate as num).toStringAsFixed(0)
                              : '--',
                          label: '周依从率',
                          unit: '%',
                          hint: '最近 7 天服药完成度',
                          onTap: () =>
                              homeScreenKey.currentState?.switchToTab(1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.section),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: leftWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _wideSectionCard(
                              title: '家庭管理区',
                              subtitle: '先处理最需要关注的事项',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (family.families.length > 1)
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            _showFamilySwitcher(family),
                                        icon: const Icon(Icons.swap_horiz),
                                        label: const Text('切换家庭'),
                                      ),
                                    ),
                                  if (family.families.length > 1)
                                    const SizedBox(height: AppSpacing.sm),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => homeScreenKey
                                          .currentState
                                          ?.switchToTab(5),
                                      icon: const Icon(Icons.family_restroom),
                                      label: const Text('进入家庭管理'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _wideSectionCard(
                              title: '临期药品预警',
                              subtitle: medProv.expiringMeds.isEmpty
                                  ? '暂无临期药品'
                                  : '${medProv.expiringMeds.length} 个药品需要关注',
                              child: medProv.expiringMeds.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: AppSpacing.lg,
                                      ),
                                      child: Text(
                                        '暂无临期药品',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        for (
                                          int i = 0;
                                          i < medProv.expiringMeds.length;
                                          i++
                                        ) ...[
                                          if (i > 0)
                                            const SizedBox(
                                              height: AppSpacing.sm,
                                            ),
                                          _wideMedicineTile(
                                            medProv.expiringMeds[i],
                                            leadingIcon: Icons.warning_rounded,
                                            leadingColor: AppColors.danger,
                                            leadingBg: AppColors.danger
                                                .withValues(alpha: 0.1),
                                            subtitleBuilder: (med) =>
                                                _getExpiryInfo(med),
                                            badgeText: _expiryBadgeText(
                                              medProv.expiringMeds[i],
                                            ),
                                            onTap: () => _openMedicineDetail(
                                              medProv.expiringMeds[i],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _wideSectionCard(
                              title: '库存不足提醒',
                              subtitle: medProv.lowStockMeds.isEmpty
                                  ? '暂无库存不足的药品'
                                  : '${medProv.lowStockMeds.length} 个药品低于阈值',
                              child: medProv.lowStockMeds.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: AppSpacing.lg,
                                      ),
                                      child: Text(
                                        '暂无库存不足的药品',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        for (
                                          int i = 0;
                                          i < medProv.lowStockMeds.length;
                                          i++
                                        ) ...[
                                          if (i > 0)
                                            const SizedBox(
                                              height: AppSpacing.sm,
                                            ),
                                          _wideMedicineTile(
                                            medProv.lowStockMeds[i],
                                            leadingIcon:
                                                Icons.inventory_2_outlined,
                                            leadingColor: AppColors.warning,
                                            leadingBg: AppColors.warning
                                                .withValues(alpha: 0.1),
                                            subtitleBuilder: (med) {
                                              final inventories =
                                                  med['inventories'] as List? ??
                                                  [];
                                              final remaining = inventories
                                                  .fold<int>(
                                                    0,
                                                    (s, inv) =>
                                                        s +
                                                        ((inv['remainingQty'] ??
                                                                0)
                                                            as int),
                                                  );
                                              return '剩余 $remaining${med['unit'] ?? ''}';
                                            },
                                            onTap: () => _openMedicineDetail(
                                              medProv.lowStockMeds[i],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: _wideSectionCard(
                          title: '今日用药安排',
                          subtitle: _allTodayItems.isEmpty
                              ? '今日暂无待执行事项'
                              : '按时间整理，成员状态一目了然',
                          child: _allTodayItems.isEmpty
                              ? _emptySchedule()
                              : _buildTimeline(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _wideMetricCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
    required String unit,
    required String hint,
    required VoidCallback onTap,
    bool isHero = false,
  }) {
    return AppSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: AppRadius.mdBorder,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: isHero ? 38 : 34,
                  fontWeight: FontWeight.w800,
                  color: isHero ? AppColors.primary : AppColors.textPrimary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _wideSectionCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _wideMedicineTile(
    dynamic med, {
    required IconData leadingIcon,
    required Color leadingColor,
    required Color leadingBg,
    required String Function(dynamic med) subtitleBuilder,
    String? badgeText,
    VoidCallback? onTap,
  }) {
    return AppDrilldownTile(
      icon: leadingIcon,
      iconColor: leadingColor,
      iconBgColor: leadingBg,
      title: med['name'] ?? '',
      subtitle: subtitleBuilder(med),
      badge: _parseBadgeValue(badgeText),
      trailing: badgeText != null
          ? Text(
              badgeText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  int _parseBadgeValue(String? value) {
    if (value == null) return 0;
    final stripped = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(stripped) ?? 0;
  }

  String? _expiryBadgeText(dynamic med) {
    final daysLeft = _daysUntilExpiry(med);
    if (daysLeft == null || daysLeft > 30) return null;
    if (daysLeft < 0) return '过期';
    if (daysLeft == 0) return '今天';
    return '$daysLeft天';
  }

  // ─────────────────────── 家庭切换 ───────────────────────
  void _showFamilySwitcher(FamilyProvider family) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              '选择家庭',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...family.families.map(
              (f) => ListTile(
                leading: Icon(
                  Icons.home_outlined,
                  color: f['id'] == family.currentFamilyId
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                title: Text(f['name'] ?? ''),
                trailing: f['id'] == family.currentFamilyId
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  if (f['id'] != family.currentFamilyId) {
                    family.setCurrentFamily(f['id']);
                    setState(() => _loading = true);
                    _loadData();
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  // ─────────────────────── 2×2 Bento 指标区 ───────────────────────
  Widget _buildMetricsBento(
    FamilyProvider family,
    MedicineProvider medProv,
    int pendingCount,
    dynamic adherenceRate,
  ) {
    return Column(
      children: [
        Row(
          children: [
            _bentoCard('${family.members.length}', '家庭成员', '位', false, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FamilyScreen()),
              );
            }),
            const SizedBox(width: AppSpacing.md),
            _bentoCard('${medProv.medicines.length}', '药箱药品', '种', false, () {
              homeScreenKey.currentState?.switchToTab(2);
            }),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _bentoCard('$pendingCount', '今日待服', '次', true, () {
              homeScreenKey.currentState?.switchToTab(1);
            }),
            const SizedBox(width: AppSpacing.md),
            _bentoCard(
              adherenceRate != null
                  ? (adherenceRate as num).toStringAsFixed(0)
                  : '--',
              '周依从率',
              '%',
              false,
              () {
                homeScreenKey.currentState?.switchToTab(1);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _bentoCard(
    String value,
    String label,
    String unit,
    bool isHero,
    VoidCallback onTap,
  ) {
    final bg = isHero ? AppColors.primary : AppColors.surface;
    final textColor = isHero ? Colors.white : AppColors.textPrimary;
    final labelColor = isHero ? Colors.white70 : AppColors.textSecondary;
    final unitColor = isHero ? Colors.white60 : AppColors.textSecondary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.lgBorder,
            boxShadow: isHero
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(unit, style: TextStyle(fontSize: 13, color: unitColor)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────── Section 标题 ───────────────────────
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }

  // ─────────────────────── 临期预警 tile ───────────────────────
  Widget _expiryTile(dynamic med) {
    final daysLeft = _daysUntilExpiry(med);
    final urgent = daysLeft != null && daysLeft <= 30;
    return GestureDetector(
      onTap: () => _openMedicineDetail(med),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgBorder,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: urgent
                    ? AppColors.danger.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: AppRadius.mdBorder,
              ),
              child: Icon(
                urgent ? Icons.warning_rounded : Icons.history,
                color: urgent ? AppColors.danger : AppColors.warning,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getExpiryInfo(med),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (daysLeft != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: urgent
                      ? AppColors.danger.withValues(alpha: 0.1)
                      : AppColors.bgMain,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  expiryLabel(daysLeft),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: urgent ? AppColors.danger : AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  int? _daysUntilExpiry(dynamic med) {
    final inventories = med['inventories'] as List? ?? [];
    for (final inv in inventories) {
      final d = inv['expiryDate'];
      if (d != null) {
        try {
          return daysUntilExpiry(d);
        } catch (_) {}
      }
    }
    return null;
  }

  // ─────────────────────── 库存不足（紧凑列表） ───────────────────────
  Widget _stockList(List<dynamic> meds) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < meds.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 44),
            _stockRow(meds[i]),
          ],
        ],
      ),
    );
  }

  Widget _stockRow(dynamic med) {
    final inventories = med['inventories'] as List? ?? [];
    final remaining = inventories.fold<int>(
      0,
      (s, inv) => s + ((inv['remainingQty'] ?? 0) as int),
    );
    return InkWell(
      onTap: () => _openMedicineDetail(med),
      borderRadius: AppRadius.lgBorder,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 20,
              color: AppColors.warning,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                med['name'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              '$remaining${med['unit'] ?? ''}',
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────── 今日服药时间轴 ───────────────────────
  Widget _emptySchedule() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.section),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 40,
              color: AppColors.success.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              '今日暂无服药计划',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return Stack(
      children: [
        // 纵向轨道线
        Positioned(
          left: 21,
          top: 20,
          bottom: 20,
          child: Container(width: 2, color: AppColors.divider),
        ),
        // 事件列表
        Column(
          children: _allTodayItems.map((item) => _timelineItem(item)).toList(),
        ),
      ],
    );
  }

  Widget _timelineItem(dynamic item) {
    final status = item['status'] ?? item['log']?['status'] ?? 'pending';
    final memberName = item['_memberName'] ?? '';
    final medicineName =
        item['medicineName'] ?? item['medicine']?['name'] ?? '';
    final scheduledTime =
        item['scheduledTime'] ?? item['schedule']?['timeOfDay'] ?? '';
    final timeLabel = item['timeLabel'] ?? item['schedule']?['label'] ?? '';
    final dosageAmount =
        item['dosageAmount'] ?? item['plan']?['dosageAmount'] ?? '';
    final dosageUnit = item['dosageUnit'] ?? item['plan']?['dosageUnit'] ?? '';
    final isPending = status == 'pending';
    final isTaken = status == 'taken';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧：时间轴圆形图标
          _timelineNode(status),
          const SizedBox(width: AppSpacing.lg),
          // 右侧：事件卡片
          Expanded(
            child: GestureDetector(
              onTap: () => MedicationEventDetailSheet.show(
                context,
                Map<String, dynamic>.from(item),
                memberId: item['_memberId'],
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isTaken ? 0.55 : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.lgBorder,
                    border: isPending
                        ? Border.all(
                            color: AppColors.primary.withValues(alpha: 0.15),
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 第一行：时间 + 状态，窄宽度下允许换行，避免溢出
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '$scheduledTime',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isPending
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bgMain,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$timeLabel',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isPending
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          if (isTaken)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 14,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '已服用',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          if (status == 'missed')
                            Text(
                              '漏服',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.danger,
                              ),
                            ),
                          if (status == 'skipped')
                            Text(
                              '已跳过',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // 第二行：药品名
                      Text(
                        '$medicineName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // 第三行：剂量 + 成员
                      Row(
                        children: [
                          Icon(
                            Icons.medication_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '$dosageAmount$dosageUnit · $memberName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // 待服用：主操作按钮
                      if (isPending) ...[
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () => MedicationEventDetailSheet.show(
                              context,
                              Map<String, dynamic>.from(item),
                              memberId: item['_memberId'],
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.mdBorder,
                              ),
                            ),
                            child: const Text(
                              '确认服用',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineNode(String status) {
    final isPending = status == 'pending';
    final isTaken = status == 'taken';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPending
            ? AppColors.primary
            : (isTaken ? AppColors.bgMain : AppColors.surface),
        border: (!isPending && !isTaken)
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
                width: 2,
              )
            : null,
        boxShadow: isPending
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Icon(
        isPending
            ? Icons.medication
            : (isTaken ? Icons.check_circle : Icons.schedule),
        size: 22,
        color: isPending
            ? Colors.white
            : (isTaken ? AppColors.success : AppColors.primary),
      ),
    );
  }

  // ─────────────────────── Helpers ───────────────────────
  String _getExpiryInfo(dynamic med) {
    final inventories = med['inventories'] as List? ?? [];
    for (final inv in inventories) {
      if (inv['expiryDate'] != null) return '有效期至: ${inv['expiryDate']}';
    }
    return '即将到期';
  }
}
