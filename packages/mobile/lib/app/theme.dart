import 'package:flutter/material.dart';

// ─── 设计令牌 ───────────────────────────────────────────────
// 灵感来源 DESIGN.md（Apple 风格）：
//   • 蓝色是唯一的交互色
//   • 红/绿/橙只用于健康状态，不做装饰
//   • 低边框、低阴影、强层级

class AppColors {
  // ── 主交互色 ──
  static const primary     = Color(0xFF007AFF);
  static const primaryDark = Color(0xFF0056CC);
  static const primaryLight= Color(0xFFE8F0FE);

  // ── 状态色（仅用于健康/风险状态，不做装饰） ──
  static const success = Color(0xFF34C759);
  static const danger  = Color(0xFFFF3B30);
  static const warning = Color(0xFFFF9500);
  // accent 统一收敛到 warning，不再单独定义
  static const accent  = Color(0xFFFF9500);

  // ── 文字 ──
  static const textPrimary   = Color(0xFF1D1D1F);
  static const textSecondary = Color(0xFF8E8E93);

  // ── 背景与表面 ──
  static const bgMain      = Color(0xFFF5F5F7);
  static const surface      = Colors.white;
  static const divider      = Color(0xFFE5E5EA);

  // ── 旧别名兼容 ──
  static const sidebarBg = Color(0xFF1B2A4A);
}

// ─── 间距 ──────────────────────────────────────────────────
class AppSpacing {
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double xxl = 24;
  static const double section = 32;
}

// ─── 圆角 ──────────────────────────────────────────────────
class AppRadius {
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double pill = 980;

  static final smBorder  = BorderRadius.circular(sm);
  static final mdBorder  = BorderRadius.circular(md);
  static final lgBorder  = BorderRadius.circular(lg);
}

// ─── 全局主题 ──────────────────────────────────────────────
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.bgMain,

      // ── AppBar ──
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),

      // ── 卡片：无边框、极轻阴影 ──
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
        color: AppColors.surface,
        shadowColor: Colors.black.withValues(alpha: 0.06),
      ),

      // ── 主按钮 ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.3),
        ),
      ),

      // ── 轮廓按钮 ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: -0.2),
        ),
      ),

      // ── 文字按钮 ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: -0.2),
        ),
      ),

      // ── 输入框：柔边框 ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgMain,
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── 底栏 ──
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),

      // ── 分割线 ──
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 0.5,
        space: 0,
      ),

      // ── TabBar ──
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: -0.2),
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primaryLight,
        labelStyle: const TextStyle(color: AppColors.primary, fontSize: 13, letterSpacing: -0.1),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smBorder),
        side: BorderSide.none,
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smBorder),
      ),
    );
  }
}
