import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/theme.dart';
import '../../core/providers/family_provider.dart';
import '../../core/providers/medicine_provider.dart';
import 'medicine_detail_screen.dart';
import 'ocr_confirm_screen.dart';

class CabinetScreen extends StatefulWidget {
  const CabinetScreen({super.key});
  @override
  State<CabinetScreen> createState() => _CabinetScreenState();
}

class _CabinetScreenState extends State<CabinetScreen> {
  bool _loading = true;
  Map<String, dynamic>? _selectedMed; // iPad 双栏：右侧详情

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final family = context.read<FamilyProvider>();
    if (family.currentFamilyId == null) await family.loadFamilies();
    if (family.currentFamilyId != null) {
      final med = context.read<MedicineProvider>();
      await med.loadMedicines(family.currentFamilyId!);
      await med.loadExpiring(family.currentFamilyId!);
      await med.loadLowStock(family.currentFamilyId!);
    }
    setState(() => _loading = false);
  }

  bool get _isWide => MediaQuery.of(context).size.width >= 700;

  @override
  Widget build(BuildContext context) {
    final medProv = context.watch<MedicineProvider>();

    final listView = _loading
        ? const Center(child: CircularProgressIndicator())
        : medProv.medicines.isEmpty
            ? const Center(child: Text('药箱为空，点击右下角添加药品', style: TextStyle(color: AppColors.textSecondary)))
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: medProv.medicines.length,
                  itemBuilder: (context, i) => _buildMedCard(medProv.medicines[i]),
                ),
              );

    Widget body;
    if (_isWide) {
      body = Row(
        children: [
          SizedBox(width: 360, child: listView),
          const VerticalDivider(width: 1),
          Expanded(
            child: _selectedMed != null
                ? MedicineDetailSheet(medicine: _selectedMed!, embedded: true)
                : const Center(child: Text('选择药品查看详情', style: TextStyle(color: AppColors.textSecondary, fontSize: 16))),
          ),
        ],
      );
    } else {
      body = listView;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('药箱管理')),
      body: body,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'camera',
            onPressed: _scanMedicine,
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            label: const Text('拍照识别', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: AppSpacing.sm),
          FloatingActionButton.small(
            heroTag: 'manual',
            onPressed: _showAddDialog,
            backgroundColor: Colors.white,
            child: const Icon(Icons.edit, color: AppColors.primary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildMedCard(dynamic med) {
    final inventories = med['inventories'] as List? ?? [];
    final totalRemaining = inventories.fold<int>(0, (sum, inv) => sum + ((inv['remainingQty'] ?? 0) as int));
    final isLow = inventories.any((inv) => inv['isLowStock'] == true);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        borderRadius: AppRadius.mdBorder,
        onTap: () => _showMedicineDetail(med),
        child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: AppRadius.mdBorder,
                  ),
                  child: const Icon(Icons.medication, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(med['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      if (med['brandName'] != null)
                        Text(med['brandName'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                if (med['category'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: AppRadius.smBorder,
                    ),
                    child: Text(med['category'], style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                  ),
              ],
            ),
            if (med['specification'] != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('规格: ${med['specification']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
            const Divider(height: AppSpacing.xl),
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 16, color: isLow ? AppColors.danger : AppColors.success),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '库存: $totalRemaining${med['unit'] ?? ''}',
                  style: TextStyle(
                    color: isLow ? AppColors.danger : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                if (isLow) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.08), borderRadius: AppRadius.smBorder),
                    child: const Text('库存不足', style: TextStyle(color: AppColors.danger, fontSize: 11)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _showMedicineDetail(dynamic med) async {
    final family = context.read<FamilyProvider>();
    if (family.currentFamilyId == null) return;
    try {
      final detail = await context.read<MedicineProvider>().getMedicineDetail(family.currentFamilyId!, med['id']);
      if (!mounted) return;
      if (_isWide) {
        setState(() => _selectedMed = detail);
      } else {
        MedicineDetailSheet.show(context, detail);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('加载详情失败: $e'), backgroundColor: AppColors.danger));
      }
    }
  }

  Future<void> _scanMedicine() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('拍照'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('从相册选择'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final image = await picker.pickImage(source: source, imageQuality: 85);
    if (image == null) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: Card(child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.lg),
          Text('AI 正在识别药品信息...'),
        ]),
      ))),
    );

    try {
      final bytes = await File(image.path).readAsBytes();
      final base64Img = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      final family = context.read<FamilyProvider>();
      final result = await context.read<MedicineProvider>().ocrRecognize(family.currentFamilyId!, base64Img);

      if (!mounted) return;
      Navigator.pop(context); // 关闭加载弹窗
      _showOcrResultDialog(result);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('识别失败: $e'), backgroundColor: AppColors.danger));
    }
  }

  void _showOcrResultDialog(Map<String, dynamic> result) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OcrConfirmScreen(ocrResult: result)),
    ).then((_) {
      if (mounted) _loadData();
    });
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: '粒');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加药品'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '药品名称')),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: '单位(粒/片/ml)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              final family = context.read<FamilyProvider>();
              await context.read<MedicineProvider>().addMedicine(family.currentFamilyId!, {
                'name': nameCtrl.text,
                'unit': unitCtrl.text,
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}
