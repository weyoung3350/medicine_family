import 'package:flutter/material.dart';
import 'package:medicine_family/app/theme.dart';
import 'package:medicine_family/core/providers/family_provider.dart';
import 'package:medicine_family/core/providers/medication_provider.dart';
import 'package:medicine_family/core/providers/medicine_provider.dart';
import 'package:medicine_family/features/dashboard/dashboard_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const DashboardCaptureApp());
}

class DashboardCaptureApp extends StatelessWidget {
  const DashboardCaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dashboard Capture',
      theme: AppTheme.lightTheme,
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<FamilyProvider>(
            create: (_) => FakeFamilyProvider(),
          ),
          ChangeNotifierProvider<MedicineProvider>(
            create: (_) => FakeMedicineProvider(),
          ),
          ChangeNotifierProvider<MedicationProvider>(
            create: (_) => FakeMedicationProvider(),
          ),
        ],
        child: const DashboardScreen(),
      ),
    );
  }
}

class FakeFamilyProvider extends FamilyProvider {
  FakeFamilyProvider() {
    currentFamilyId = 'family-001';
    families = const [
      {'id': 'family-001', 'name': '温馨一家'},
      {'id': 'family-002', 'name': '外婆家'},
    ];
    members = const [
      {'id': 'member-001', 'displayName': '爷爷', 'role': 'dependent'},
      {'id': 'member-002', 'displayName': '奶奶', 'role': 'dependent'},
      {'id': 'member-003', 'displayName': '我', 'role': 'owner'},
    ];
  }

  @override
  Future<void> loadFamilies() async {}

  @override
  Future<void> setCurrentFamily(String id) async {
    currentFamilyId = id;
    notifyListeners();
  }

  @override
  Future<void> loadMembers() async {}
}

class FakeMedicineProvider extends MedicineProvider {
  FakeMedicineProvider() {
    medicines = [
      _med(
        id: 'med-001',
        name: '氨氯地平片',
        unit: '盒',
        remainingQty: 2,
        expiryDate: '2026-05-10',
      ),
      _med(
        id: 'med-002',
        name: '阿司匹林肠溶片',
        unit: '盒',
        remainingQty: 1,
        expiryDate: '2026-04-28',
      ),
      _med(
        id: 'med-003',
        name: '二甲双胍缓释片',
        unit: '盒',
        remainingQty: 6,
        expiryDate: '2026-10-18',
      ),
      _med(
        id: 'med-004',
        name: '辅酶Q10胶囊',
        unit: '瓶',
        remainingQty: 3,
        expiryDate: '2026-06-03',
      ),
      _med(
        id: 'med-005',
        name: '维生素D滴剂',
        unit: '瓶',
        remainingQty: 8,
        expiryDate: '2026-12-21',
      ),
    ];
    expiringMeds = [medicines[1], medicines[0]];
    lowStockMeds = [medicines[1], medicines[0]];
  }

  static Map<String, dynamic> _med({
    required String id,
    required String name,
    required String unit,
    required int remainingQty,
    required String expiryDate,
  }) {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'inventories': [
        {
          'remainingQty': remainingQty,
          'expiryDate': expiryDate,
        },
      ],
    };
  }

  @override
  Future<void> loadMedicines(String familyId) async {}

  @override
  Future<void> loadExpiring(String familyId) async {}

  @override
  Future<void> loadLowStock(String familyId) async {}

  @override
  Future<Map<String, dynamic>> getMedicineDetail(
    String familyId,
    String medicineId,
  ) async {
    return Map<String, dynamic>.from(
      medicines.firstWhere((m) => m['id'] == medicineId) as Map,
    );
  }
}

class FakeMedicationProvider extends MedicationProvider {
  final Map<String, List<dynamic>> _itemsByMember = {
    'member-001': [
      {
        'medicineName': '氨氯地平片',
        'dosageAmount': 1,
        'dosageUnit': '片',
        'scheduledTime': '07:30',
        'timeLabel': '早餐后',
        'status': 'pending',
        'planId': 'plan-001',
        'scheduleId': 'schedule-001',
        'medicineId': 'med-001',
      },
      {
        'medicineName': '阿司匹林肠溶片',
        'dosageAmount': 1,
        'dosageUnit': '片',
        'scheduledTime': '12:00',
        'timeLabel': '午餐后',
        'status': 'pending',
        'planId': 'plan-002',
        'scheduleId': 'schedule-002',
        'medicineId': 'med-002',
      },
    ],
    'member-002': [
      {
        'medicineName': '二甲双胍缓释片',
        'dosageAmount': 2,
        'dosageUnit': '片',
        'scheduledTime': '08:00',
        'timeLabel': '早餐时',
        'status': 'taken',
        'planId': 'plan-003',
        'scheduleId': 'schedule-003',
        'medicineId': 'med-003',
      },
      {
        'medicineName': '辅酶Q10胶囊',
        'dosageAmount': 1,
        'dosageUnit': '粒',
        'scheduledTime': '20:00',
        'timeLabel': '晚饭后',
        'status': 'pending',
        'planId': 'plan-004',
        'scheduleId': 'schedule-004',
        'medicineId': 'med-004',
      },
    ],
    'member-003': [],
  };

  @override
  Future<void> loadToday(String familyId, String memberId) async {
    todayItems = List<dynamic>.from(_itemsByMember[memberId] ?? const []);
  }

  @override
  Future<void> loadAdherence(
    String familyId,
    String memberId, {
    String range = 'week',
  }) async {
    adherence = {
      'adherenceRate': 91.6,
      'totalPlanned': 24,
      'taken': 22,
      'missed': 2,
    };
  }
}
