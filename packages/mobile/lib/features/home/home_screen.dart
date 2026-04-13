import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/elder_mode_provider.dart';
import '../dashboard/dashboard_screen.dart';
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

  final _pages = const [
    DashboardScreen(),
    MedicationScreen(),
    CabinetScreen(),
    AiChatScreen(),
    MoreScreen(),
  ];

  /// 外部调用：切换到指定 tab（0概览 1服药 2药箱 3AI 4更多）
  void switchToTab(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() => _currentIndex = index);
    }
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

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: '概览'),
            BottomNavigationBarItem(icon: Icon(Icons.medication_outlined), activeIcon: Icon(Icons.medication), label: '服药'),
            BottomNavigationBarItem(icon: Icon(Icons.medical_services_outlined), activeIcon: Icon(Icons.medical_services), label: '药箱'),
            BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), activeIcon: Icon(Icons.smart_toy), label: 'AI'),
            BottomNavigationBarItem(icon: Icon(Icons.more_horiz), activeIcon: Icon(Icons.more_horiz), label: '更多'),
          ],
        ),
      ),
    );
  }
}
