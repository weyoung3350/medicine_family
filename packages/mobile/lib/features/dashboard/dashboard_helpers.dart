// Dashboard 首页纯函数 helper，可被测试直接 import。

/// 解析 "HH:MM" 为分钟数。非法值返回 9999 排末尾。
/// 合法范围：小时 0..23，分钟 0..59。
int parseDashboardTime(String? t) {
  if (t == null || t.isEmpty) return 9999;
  final parts = t.split(':');
  if (parts.length < 2) return 9999;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return 9999;
  if (h < 0 || h > 23 || m < 0 || m > 59) return 9999;
  return h * 60 + m;
}

/// 按纯日期粒度计算到期剩余天数，不受时分秒影响。
/// 返回值：正数=还有 N 天，0=今天到期，负数=已过期 N 天。
int daysUntilExpiry(String expiryDateStr) {
  final expiry = DateTime.parse(expiryDateStr);
  final today = DateTime.now();
  return DateTime(expiry.year, expiry.month, expiry.day)
      .difference(DateTime(today.year, today.month, today.day))
      .inDays;
}

/// 到期文案。
String expiryLabel(int days) {
  if (days < 0) return '已过期';
  if (days == 0) return '今天到期';
  return '$days天后';
}

/// 全家庭时间轴排序 comparator。
/// 保证完全确定的稳定顺序：时间 → 成员名 → 药品名 → sourceIndex。
int compareTimelineItems(Map<String, dynamic> a, Map<String, dynamic> b) {
  // 1. 时间升序
  final ta = parseDashboardTime(a['scheduledTime'] ?? a['schedule']?['timeOfDay']);
  final tb = parseDashboardTime(b['scheduledTime'] ?? b['schedule']?['timeOfDay']);
  var cmp = ta.compareTo(tb);
  if (cmp != 0) return cmp;

  // 2. 成员名
  cmp = (a['_memberName'] ?? '').compareTo(b['_memberName'] ?? '');
  if (cmp != 0) return cmp;

  // 3. 药品名
  final nameA = a['medicineName'] ?? a['medicine']?['name'] ?? '';
  final nameB = b['medicineName'] ?? b['medicine']?['name'] ?? '';
  cmp = nameA.compareTo(nameB);
  if (cmp != 0) return cmp;

  // 4. 原始加载索引（由 dashboard 写入 _sourceIndex）
  final ia = a['_sourceIndex'] as int? ?? 0;
  final ib = b['_sourceIndex'] as int? ?? 0;
  return ia.compareTo(ib);
}
