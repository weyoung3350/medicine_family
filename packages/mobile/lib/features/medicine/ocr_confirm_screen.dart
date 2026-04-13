import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/providers/family_provider.dart';
import '../../core/providers/medicine_provider.dart';
import '../medication/create_plan_screen.dart';

/// OCR 识别结果确认页。
/// 流程：拍照识别 → 本页（编辑确认）→ 添加药品 → 可选创建计划
class OcrConfirmScreen extends StatefulWidget {
  final Map<String, dynamic> ocrResult;
  const OcrConfirmScreen({super.key, required this.ocrResult});
  @override
  State<OcrConfirmScreen> createState() => _OcrConfirmScreenState();
}

class _OcrConfirmScreenState extends State<OcrConfirmScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _specCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _formCtrl;
  late final TextEditingController _mfrCtrl;
  late final TextEditingController _indicationsCtrl;
  late final TextEditingController _contraindicationsCtrl;
  late final TextEditingController _usageCtrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final r = widget.ocrResult;
    _nameCtrl = TextEditingController(text: r['name'] ?? '');
    _brandCtrl = TextEditingController(text: r['brandName'] ?? '');
    _specCtrl = TextEditingController(text: r['specification'] ?? '');
    _unitCtrl = TextEditingController(text: '粒');
    _formCtrl = TextEditingController(text: r['dosageForm'] ?? '');
    _mfrCtrl = TextEditingController(text: r['manufacturer'] ?? '');
    _indicationsCtrl = TextEditingController(text: r['indications'] ?? '');
    _contraindicationsCtrl = TextEditingController(text: r['contraindications'] ?? '');
    _usageCtrl = TextEditingController(text: r['usageGuide'] ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _specCtrl.dispose();
    _unitCtrl.dispose();
    _formCtrl.dispose();
    _mfrCtrl.dispose();
    _indicationsCtrl.dispose();
    _contraindicationsCtrl.dispose();
    _usageCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildMedicineData() => {
    'name': _nameCtrl.text,
    'brandName': _brandCtrl.text,
    'specification': _specCtrl.text,
    'unit': _unitCtrl.text,
    'dosageForm': _formCtrl.text,
    'manufacturer': _mfrCtrl.text,
    'indications': _indicationsCtrl.text,
    'contraindications': _contraindicationsCtrl.text,
    'usageGuide': _usageCtrl.text,
  };

  Future<void> _addOnly() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写药品名称'), backgroundColor: AppColors.accent),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final family = context.read<FamilyProvider>();
      await context.read<MedicineProvider>().addMedicine(
        family.currentFamilyId!, _buildMedicineData(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('药品已添加'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
    if (mounted) setState(() => _submitting = false);
  }

  Future<void> _addAndCreatePlan() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写药品名称'), backgroundColor: AppColors.accent),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final family = context.read<FamilyProvider>();
      final med = await context.read<MedicineProvider>().addMedicine(
        family.currentFamilyId!, _buildMedicineData(),
      );
      if (!mounted) return;

      if (family.members.isEmpty) await family.loadFamilies();
      if (!mounted) return;
      if (family.members.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先添加家庭成员'), backgroundColor: AppColors.accent),
        );
        setState(() => _submitting = false);
        return;
      }

      // 替换当前页面为计划创建页
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => CreatePlanScreen(
          familyId: family.currentFamilyId!,
          memberId: family.members[0]['id'],
          prefill: {
            'medicineId': med?['id'],
            'dosageUnit': _unitCtrl.text,
            'usageGuide': _usageCtrl.text,
          },
        ),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e'), backgroundColor: AppColors.danger),
        );
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final confidence = (widget.ocrResult['confidence'] as num?)?.toDouble() ?? 0;
    final needsReview = widget.ocrResult['needsReview'] == true;

    return Scaffold(
      appBar: AppBar(title: const Text('确认识别结果')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // 置信度提示
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: needsReview
                  ? AppColors.accent.withValues(alpha: 0.06)
                  : AppColors.success.withValues(alpha: 0.06),
              borderRadius: AppRadius.mdBorder,
            ),
            child: Row(
              children: [
                Icon(
                  needsReview ? Icons.edit_note : Icons.check_circle_outline,
                  color: needsReview ? AppColors.accent : AppColors.success,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    needsReview
                        ? '识别置信度 ${(confidence * 100).toStringAsFixed(0)}%，请核对以下信息'
                        : '识别置信度 ${(confidence * 100).toStringAsFixed(0)}%，信息已填入',
                    style: TextStyle(
                      color: needsReview ? AppColors.accent : AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // 基本信息 - grouped card
          _sectionCard('基本信息', [
            _field(_nameCtrl, '药品名称 *', widget.ocrResult['name']),
            _field(_brandCtrl, '品牌名', widget.ocrResult['brandName']),
            Row(
              children: [
                Expanded(child: _field(_specCtrl, '规格', widget.ocrResult['specification'])),
                const SizedBox(width: AppSpacing.md),
                SizedBox(width: 100, child: _field(_unitCtrl, '单位', null)),
              ],
            ),
            Row(
              children: [
                Expanded(child: _field(_formCtrl, '剂型', widget.ocrResult['dosageForm'])),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _field(_mfrCtrl, '生产企业', widget.ocrResult['manufacturer'])),
              ],
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),

          // 用药信息 - grouped card
          _sectionCard('用药信息', [
            _field(_indicationsCtrl, '适应症/功效', widget.ocrResult['indications'], maxLines: 3),
            _field(_usageCtrl, '用法用量', widget.ocrResult['usageGuide'], maxLines: 3),
            _field(_contraindicationsCtrl, '禁忌', widget.ocrResult['contraindications'], maxLines: 2),
          ]),
          const SizedBox(height: AppSpacing.section),

          // 操作按钮
          ElevatedButton.icon(
            onPressed: _submitting ? null : _addAndCreatePlan,
            icon: const Icon(Icons.playlist_add_check),
            label: const Text('确认并创建服药计划'),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: _submitting ? null : _addOnly,
            child: const Text('仅添加到药箱'),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }

  /// 输入字段。当原始值与当前值不同时，显示"已修改"标记。
  Widget _field(TextEditingController ctrl, String label, String? original, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: (original != null && original.isNotEmpty && ctrl.text != original)
              ? const Tooltip(
                  message: '已修改',
                  child: Icon(Icons.edit, size: 16, color: AppColors.accent),
                )
              : null,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}
