import 'package:flutter/material.dart';
import '../../app/theme.dart';
import 'today_screen.dart';
import 'plans_tab.dart';
import 'stats_tab.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});
  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('服药管理'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: '今日'),
            Tab(text: '计划'),
            Tab(text: '统计'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          TodayScreen(embedded: true),
          PlansTab(),
          StatsTab(),
        ],
      ),
    );
  }
}
