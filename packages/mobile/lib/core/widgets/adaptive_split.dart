import 'package:flutter/material.dart';

/// 自适应双栏布局。
/// 宽屏（>= 700px，iPad 横屏/竖屏）时左右分栏，窄屏时只显示 list。
/// 选中 item 后窄屏 push 详情页，宽屏在右侧面板显示。
class AdaptiveSplit extends StatelessWidget {
  final Widget list;
  final Widget? detail;
  final double breakpoint;

  const AdaptiveSplit({
    super.key,
    required this.list,
    this.detail,
    this.breakpoint = 700,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < breakpoint) {
      return list;
    }
    return Row(
      children: [
        SizedBox(width: 360, child: list),
        const VerticalDivider(width: 1),
        Expanded(
          child: detail ?? const Center(
            child: Text('选择一项查看详情', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
