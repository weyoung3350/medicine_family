import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_family/features/medication/medication_event_detail_sheet.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {});

  group('MedicationEventDetailSheet', () {
    testWidgets('renders pending event with action buttons', (WidgetTester tester) async {
      final event = <String, dynamic>{
        'medicineName': '硝苯地平控释片',
        'dosageAmount': 1.0,
        'dosageUnit': '片',
        'mealRelation': 'after_meal',
        'scheduledTime': '08:00',
        'timeLabel': '早餐后',
        'status': 'pending',
        'planId': 'plan-123',
        'scheduleId': 'sched-456',
        'medicineId': 'med-789',
        '_memberName': '爷爷',
        '_memberId': 'member-001',
      };

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MedicationEventDetailSheet(event: event, memberId: 'member-001', embedded: true),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('硝苯地平控释片'), findsOneWidget);
      expect(find.text('待服用'), findsOneWidget);
      expect(find.text('我已服药'), findsOneWidget);
      expect(find.text('跳过本次'), findsOneWidget);
      expect(find.text('查看药品详情'), findsOneWidget);
    });

    testWidgets('renders taken event read-only (no action buttons)', (WidgetTester tester) async {
      final event = <String, dynamic>{
        'medicineName': '二甲双胍缓释片',
        'dosageAmount': 1.0,
        'dosageUnit': '片',
        'mealRelation': 'with_meal',
        'scheduledTime': '07:30',
        'timeLabel': '早餐时',
        'status': 'taken',
        'planId': 'plan-abc',
        'scheduleId': 'sched-def',
        'medicineId': 'med-ghi',
        '_memberName': '奶奶',
      };

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MedicationEventDetailSheet(event: event, embedded: true),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('已服用'), findsOneWidget);
      expect(find.text('二甲双胍缓释片'), findsOneWidget);
      expect(find.text('我已服药'), findsNothing);
      expect(find.text('跳过本次'), findsNothing);
      expect(find.text('查看药品详情'), findsOneWidget);
    });

    testWidgets('refuses check-in when memberId is missing', (WidgetTester tester) async {
      // 事件没有 _memberId，也没有显式传入 memberId
      final event = <String, dynamic>{
        'medicineName': '测试药品',
        'dosageAmount': 1.0,
        'dosageUnit': '片',
        'mealRelation': 'after_meal',
        'scheduledTime': '09:00',
        'timeLabel': '早餐后',
        'status': 'pending',
        'planId': 'plan-xxx',
        'scheduleId': 'sched-yyy',
        // 注意：没有 _memberId，也没有传 memberId
      };

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MedicationEventDetailSheet(event: event, embedded: true),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // 按钮存在
      expect(find.text('我已服药'), findsOneWidget);

      // 点击"我已服药"
      await tester.tap(find.text('我已服药'));
      await tester.pumpAndSettle();

      // 应该显示"无法确定服药人"提示，而不是执行打卡
      expect(find.text('无法确定服药人，请从成员列表重新进入'), findsOneWidget);
    });
  });
}
