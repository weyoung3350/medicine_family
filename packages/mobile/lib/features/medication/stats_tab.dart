import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../app/theme.dart';
import '../../core/providers/family_provider.dart';
import '../../core/providers/medication_provider.dart';
import '../../core/widgets/app_surface_card.dart';
import '../../core/widgets/member_selector.dart';
import '../home/home_screen.dart';

class StatsTab extends StatefulWidget {
  const StatsTab({super.key});
  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  bool _loading = true;
  String? _selectedMemberId;
  String _range = 'week';

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
      await _loadAdherence();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadAdherence() async {
    if (_selectedMemberId == null) return;
    final family = context.read<FamilyProvider>();
    if (family.currentFamilyId == null) return;
    await context.read<MedicationProvider>().loadAdherence(
      family.currentFamilyId!,
      _selectedMemberId!,
      range: _range,
    );
  }

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyProvider>();
    final medication = context.watch<MedicationProvider>();
    final adherence = medication.adherence;

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadAdherence,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Member selector
                if (family.members.isNotEmpty)
                  MemberSelector(
                    members: family.members,
                    selectedId: _selectedMemberId,
                    onChanged: (id) { setState(() => _selectedMemberId = id); _loadAdherence(); },
                  ),
                const SizedBox(height: AppSpacing.md),

                // Range toggle
                Center(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'week', label: Text('本周')),
                      ButtonSegment(value: 'month', label: Text('本月')),
                    ],
                    selected: {_range},
                    onSelectionChanged: (s) {
                      setState(() => _range = s.first);
                      _loadAdherence();
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Metric cards
                if (adherence != null)
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 2.0,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _statCard('依从率', '${(adherence['adherenceRate'] as num? ?? 0).toStringAsFixed(1)}%', AppColors.primary, onTap: () {
                        homeScreenKey.currentState?.switchToTab(1);
                      }),
                      _statCard('总计划', '${adherence['totalPlanned'] ?? 0}', AppColors.textPrimary, onTap: () {
                        homeScreenKey.currentState?.switchToTab(1);
                      }),
                      _statCard('已服用', '${adherence['taken'] ?? 0}', AppColors.success, onTap: () {
                        homeScreenKey.currentState?.switchToTab(1);
                      }),
                      _statCard('漏服', '${adherence['missed'] ?? 0}', AppColors.danger, onTap: () {
                        homeScreenKey.currentState?.switchToTab(1);
                      }),
                    ],
                  ),
                const SizedBox(height: AppSpacing.xl),

                // Bar chart
                if (adherence != null && adherence['dailyBreakdown'] != null)
                  _buildChart(adherence['dailyBreakdown'] as List),

                if (adherence == null)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('暂无统计数据', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
              ],
            ),
          );
  }

  Widget _statCard(String label, String value, Color color, {VoidCallback? onTap}) {
    return AppSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildChart(List dailyBreakdown) {
    if (dailyBreakdown.isEmpty) return const SizedBox.shrink();

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('每日详情', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _legendDot(AppColors.success, '已服用'),
              const SizedBox(width: AppSpacing.lg),
              _legendDot(AppColors.danger, '漏服'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxY(dailyBreakdown),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final day = dailyBreakdown[groupIndex];
                        return BarTooltipItem(
                          '${day['date'] ?? ''}\n已服: ${day['taken'] ?? 0} 漏服: ${day['missed'] ?? 0}',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                    touchCallback: (event, response) {
                      if (event is FlTapUpEvent && response?.spot != null) {
                        final index = response!.spot!.touchedBarGroupIndex;
                        if (index >= 0 && index < dailyBreakdown.length) {
                          _showDaySummary(dailyBreakdown[index]);
                        }
                      }
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= dailyBreakdown.length) return const SizedBox.shrink();
                          final date = dailyBreakdown[index]['date'] ?? '';
                          final short = date.length >= 5 ? date.substring(5) : date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(short, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value == value.roundToDouble()) {
                            return Text('${value.toInt()}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary));
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(dailyBreakdown.length, (i) {
                    final day = dailyBreakdown[i];
                    final taken = (day['taken'] as num? ?? 0).toDouble();
                    final missed = (day['missed'] as num? ?? 0).toDouble();
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: taken + missed,
                          width: dailyBreakdown.length > 14 ? 8 : 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          rodStackItems: [
                            BarChartRodStackItem(0, taken, AppColors.success),
                            BarChartRodStackItem(taken, taken + missed, AppColors.danger),
                          ],
                          color: Colors.transparent,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  double _getMaxY(List data) {
    double maxVal = 0;
    for (final d in data) {
      final total = ((d['taken'] as num? ?? 0) + (d['missed'] as num? ?? 0)).toDouble();
      if (total > maxVal) maxVal = total;
    }
    return maxVal < 1 ? 1 : maxVal + 1;
  }

  void _showDaySummary(dynamic day) {
    final date = day['date'] ?? '';
    final taken = day['taken'] ?? 0;
    final missed = day['missed'] ?? 0;
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(date, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _dayStat('已服用', '$taken', AppColors.success),
                _dayStat('漏服', '$missed', AppColors.danger),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                homeScreenKey.currentState?.switchToTab(1);
              },
              icon: const Icon(Icons.calendar_today, size: 16),
              label: const Text('查看今日服药'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _dayStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      ],
    );
  }

  static String _pickDefault(List<dynamic> members) {
    final dep = members.where((m) => m['role'] == 'dependent').toList();
    return (dep.isNotEmpty ? dep.first : members.first)['id'];
  }
}
