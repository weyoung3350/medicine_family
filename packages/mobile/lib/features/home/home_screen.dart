import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/providers/elder_mode_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../family/family_screen.dart';
import '../medication/elder_today_screen.dart';
import '../medication/medication_screen.dart';
import '../medicine/cabinet_screen.dart';
import '../ai/ai_chat_screen.dart';
import '../more/more_screen.dart';

/// 全局 key，供消息中心等外部页面切换 tab。
final homeScreenKey = GlobalKey<HomeScreenState>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<WidgetBuilder> _mobilePageBuilders = [
    (_) => const DashboardScreen(),
    (_) => const MedicationScreen(),
    (_) => const CabinetScreen(),
    (_) => const AiChatScreen(),
    (_) => const MoreScreen(),
  ];

  final List<WidgetBuilder> _widePageBuilders = [
    (_) => const DashboardScreen(),
    (_) => const MedicationScreen(),
    (_) => const CabinetScreen(),
    (_) => const AiChatScreen(),
    (_) => const MoreScreen(),
    (_) => const FamilyScreen(),
  ];

  /// 外部调用：切换到指定 tab（0概览 1服药 2药箱 3AI 4更多，5家庭管理仅 Pad）
  void switchToTab(int index) {
    if (index >= 0) {
      setState(() => _currentIndex = index);
    }
  }

  bool _isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= 800;

  List<WidgetBuilder> _buildersFor(bool isWide) =>
      isWide ? _widePageBuilders : _mobilePageBuilders;

  List<_NavDestination> _destinationsFor(bool isWide) {
    final items = <_NavDestination>[
      const _NavDestination(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: '概览',
      ),
      const _NavDestination(
        icon: Icons.medication_outlined,
        selectedIcon: Icons.medication,
        label: '服药',
      ),
      const _NavDestination(
        icon: Icons.medical_services_outlined,
        selectedIcon: Icons.medical_services,
        label: '药箱',
      ),
      const _NavDestination(
        icon: Icons.smart_toy_outlined,
        selectedIcon: Icons.smart_toy,
        label: 'AI',
      ),
      const _NavDestination(
        icon: Icons.more_horiz,
        selectedIcon: Icons.more_horiz,
        label: '更多',
      ),
    ];
    if (isWide) {
      items.add(
        const _NavDestination(
          icon: Icons.family_restroom_outlined,
          selectedIcon: Icons.family_restroom,
          label: '家庭管理',
        ),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final elderMode = context.watch<ElderModeProvider>();

    if (!elderMode.loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (elderMode.enabled) {
      return const ElderTodayScreen();
    }

    final isWide = _isWide(context);
    final builders = _buildersFor(isWide);
    final destinations = _destinationsFor(isWide);
    final effectiveIndex = _currentIndex.clamp(0, builders.length - 1).toInt();

    if (_currentIndex != effectiveIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentIndex != effectiveIndex) {
          setState(() => _currentIndex = effectiveIndex);
        }
      });
    }

    if (isWide) {
      return Scaffold(
        backgroundColor: AppColors.bgMain,
        body: SafeArea(
          child: Row(
            children: [
              SizedBox(
                width: 284,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      right: BorderSide(
                        color: AppColors.divider.withValues(alpha: 0.9),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(2, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.md,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: AppRadius.mdBorder,
                              ),
                              child: const Icon(
                                Icons.medication_outlined,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '家庭健康管家',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Pad 控制台',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: destinations.length,
                          separatorBuilder: (context, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final item = destinations[index];
                            return _WideNavItem(
                              icon: item.icon,
                              selectedIcon: item.selectedIcon,
                              label: item.label,
                              selected: index == effectiveIndex,
                              onTap: () => switchToTab(index),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: AppColors.bgMain,
                  child: _LazyPageStack(
                    index: effectiveIndex,
                    builders: builders,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: _LazyPageStack(index: effectiveIndex, builders: builders),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: effectiveIndex,
          onTap: switchToTab,
          items: destinations
              .take(5)
              .map(
                (item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  activeIcon: Icon(item.selectedIcon),
                  label: item.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _NavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class _WideNavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _WideNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primaryLight : Colors.transparent;
    final iconBg = selected ? AppColors.primary : AppColors.bgMain;
    final iconColor = selected ? Colors.white : AppColors.textSecondary;
    final textColor = selected ? AppColors.primary : AppColors.textPrimary;
    final weight = selected ? FontWeight.w700 : FontWeight.w500;

    return Material(
      color: bg,
      borderRadius: AppRadius.mdBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdBorder,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: AppRadius.smBorder,
                ),
                child: Icon(
                  selected ? selectedIcon : icon,
                  size: 20,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: weight,
                    color: textColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LazyPageStack extends StatefulWidget {
  final int index;
  final List<WidgetBuilder> builders;

  const _LazyPageStack({required this.index, required this.builders});

  @override
  State<_LazyPageStack> createState() => _LazyPageStackState();
}

class _LazyPageStackState extends State<_LazyPageStack> {
  final Map<int, Widget> _cache = {};

  @override
  void didUpdateWidget(covariant _LazyPageStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.builders.length != widget.builders.length) {
      _cache.removeWhere((key, _) => key >= widget.builders.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    _cache.putIfAbsent(
      widget.index,
      () => widget.builders[widget.index](context),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        for (int i = 0; i < widget.builders.length; i++)
          if (_cache.containsKey(i))
            Offstage(
              offstage: i != widget.index,
              child: TickerMode(enabled: i == widget.index, child: _cache[i]!),
            ),
      ],
    );
  }
}
