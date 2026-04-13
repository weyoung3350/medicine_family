import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// 成员横向标签选择器，替代原始下拉框。
class MemberSelector extends StatelessWidget {
  final List<dynamic> members;
  final String? selectedId;
  final ValueChanged<String> onChanged;

  const MemberSelector({
    super.key,
    required this.members,
    required this.selectedId,
    required this.onChanged,
  });

  /// 排序：dependent 在前（通常有服药计划），owner/member 在后
  List<dynamic> get _sorted {
    final list = List<dynamic>.from(members);
    list.sort((a, b) {
      const order = {'dependent': 0, 'member': 1, 'owner': 2};
      return (order[a['role']] ?? 1).compareTo(order[b['role']] ?? 1);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();
    final sorted = _sorted;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: sorted.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final m = sorted[i];
          final id = m['id'] as String;
          final name = m['displayName'] ?? '';
          final selected = id == selectedId;
          return GestureDetector(
            onTap: () => onChanged(id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.divider,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: selected ? Colors.white.withValues(alpha: 0.3) : AppColors.primaryLight,
                    child: Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? Colors.white : AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
