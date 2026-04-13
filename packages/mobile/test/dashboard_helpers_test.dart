import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_family/features/dashboard/dashboard_helpers.dart';

void main() {
  group('parseDashboardTime', () {
    test('parses valid HH:MM', () {
      expect(parseDashboardTime('00:00'), 0);
      expect(parseDashboardTime('08:00'), 480);
      expect(parseDashboardTime('12:30'), 750);
      expect(parseDashboardTime('23:59'), 1439);
    });

    test('rejects null and empty', () {
      expect(parseDashboardTime(null), 9999);
      expect(parseDashboardTime(''), 9999);
    });

    test('rejects non-numeric', () {
      expect(parseDashboardTime('abc'), 9999);
      expect(parseDashboardTime('xx:yy'), 9999);
      expect(parseDashboardTime('12'), 9999);
    });

    test('rejects out-of-range hours and minutes', () {
      expect(parseDashboardTime('24:00'), 9999);
      expect(parseDashboardTime('25:00'), 9999);
      expect(parseDashboardTime('99:99'), 9999);
      expect(parseDashboardTime('12:60'), 9999);
      expect(parseDashboardTime('-1:00'), 9999);
      expect(parseDashboardTime('08:-5'), 9999);
    });

    test('sorts times correctly', () {
      final times = ['18:30', '07:30', '12:00', '08:00'];
      times.sort((a, b) => parseDashboardTime(a).compareTo(parseDashboardTime(b)));
      expect(times, ['07:30', '08:00', '12:00', '18:30']);
    });
  });

  group('daysUntilExpiry', () {
    String fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    test('today returns 0', () {
      expect(daysUntilExpiry(fmt(DateTime.now())), 0);
    });

    test('tomorrow returns 1 regardless of current time', () {
      expect(daysUntilExpiry(fmt(DateTime.now().add(const Duration(days: 1)))), 1);
    });

    test('yesterday returns -1', () {
      expect(daysUntilExpiry(fmt(DateTime.now().subtract(const Duration(days: 1)))), -1);
    });

    test('30 days from now returns 30', () {
      expect(daysUntilExpiry(fmt(DateTime.now().add(const Duration(days: 30)))), 30);
    });
  });

  group('expiryLabel', () {
    test('negative days', () => expect(expiryLabel(-3), '已过期'));
    test('zero days', () => expect(expiryLabel(0), '今天到期'));
    test('positive days', () => expect(expiryLabel(14), '14天后'));
  });

  group('compareTimelineItems', () {
    Map<String, dynamic> item(String time, String member, String medicine, int idx) => {
      'scheduledTime': time,
      '_memberName': member,
      'medicineName': medicine,
      '_sourceIndex': idx,
    };

    test('sorts by time ascending', () {
      final items = [item('12:00', '爷爷', '药A', 0), item('08:00', '爷爷', '药A', 1)];
      items.sort(compareTimelineItems);
      expect(items[0]['scheduledTime'], '08:00');
      expect(items[1]['scheduledTime'], '12:00');
    });

    test('same time sorts by member name', () {
      final items = [item('08:00', '奶奶', '药A', 0), item('08:00', '爷爷', '药A', 1)];
      items.sort(compareTimelineItems);
      expect(items[0]['_memberName'], '奶奶');
      expect(items[1]['_memberName'], '爷爷');
    });

    test('same time same member sorts by medicine name', () {
      final items = [item('08:00', '爷爷', '硝苯地平', 0), item('08:00', '爷爷', '阿司匹林', 1)];
      items.sort(compareTimelineItems);
      expect(items[0]['medicineName'], '硝苯地平');
      expect(items[1]['medicineName'], '阿司匹林');
    });

    test('full tie-break uses sourceIndex', () {
      final items = [item('08:00', '爷爷', '药A', 5), item('08:00', '爷爷', '药A', 2)];
      items.sort(compareTimelineItems);
      expect(items[0]['_sourceIndex'], 2);
      expect(items[1]['_sourceIndex'], 5);
    });

    test('invalid time sorts to end', () {
      final items = [item('', '爷爷', '药A', 0), item('08:00', '爷爷', '药A', 1)];
      items.sort(compareTimelineItems);
      expect(items[0]['scheduledTime'], '08:00');
      expect(items[1]['scheduledTime'], '');
    });

    test('multiple items sort deterministically', () {
      final items = [
        item('18:30', '奶奶', '阿托伐他汀', 3),
        item('08:00', '爷爷', '硝苯地平', 0),
        item('07:30', '奶奶', '二甲双胍', 2),
        item('08:00', '爷爷', '阿司匹林', 1),
        item('07:30', '爷爷', '鱼油', 4),
      ];
      items.sort(compareTimelineItems);
      // 07:30 奶奶 < 07:30 爷爷, 08:00 爷爷 硝苯 < 08:00 爷爷 阿司, 18:30 奶奶
      final result = items.map((i) => '${i['scheduledTime']}-${i['_memberName']}-${i['medicineName']}').toList();
      expect(result, [
        '07:30-奶奶-二甲双胍',
        '07:30-爷爷-鱼油',
        '08:00-爷爷-硝苯地平',
        '08:00-爷爷-阿司匹林',
        '18:30-奶奶-阿托伐他汀',
      ]);

      // 再排一次，顺序必须一致
      items.sort(compareTimelineItems);
      final result2 = items.map((i) => '${i['scheduledTime']}-${i['_memberName']}-${i['medicineName']}').toList();
      expect(result2, result);
    });
  });
}
