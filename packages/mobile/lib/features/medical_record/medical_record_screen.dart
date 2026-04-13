import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../app/theme.dart';
import '../../core/providers/family_provider.dart';
import '../../core/providers/medical_record_provider.dart';
import '../../core/network/api_client.dart';

class MedicalRecordScreen extends StatefulWidget {
  const MedicalRecordScreen({super.key});
  @override
  State<MedicalRecordScreen> createState() => _MedicalRecordScreenState();
}

class _MedicalRecordScreenState extends State<MedicalRecordScreen> {
  bool _loading = true;
  dynamic _selectedRecord; // iPad 双栏：右侧详情

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final family = context.read<FamilyProvider>();
    if (family.currentFamilyId == null) await family.loadFamilies();
    if (family.currentFamilyId != null) {
      await context.read<MedicalRecordProvider>().loadRecords(family.currentFamilyId!);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MedicalRecordProvider>();

    final isWide = MediaQuery.of(context).size.width >= 700;

    final listView = _loading
        ? const Center(child: CircularProgressIndicator())
        : provider.records.isEmpty
            ? const Center(child: Text('暂无病历记录', style: TextStyle(color: AppColors.textSecondary)))
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.records.length,
                  itemBuilder: (context, i) => _buildRecordCard(provider.records[i]),
                ),
              );

    Widget body;
    if (isWide) {
      body = Row(
        children: [
          SizedBox(width: 380, child: listView),
          const VerticalDivider(width: 1),
          Expanded(
            child: _selectedRecord != null
                ? _buildDetailPanel(_selectedRecord)
                : const Center(child: Text('选择病历查看详情', style: TextStyle(color: AppColors.textSecondary, fontSize: 16))),
          ),
        ],
      );
    } else {
      body = listView;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('病历管理')),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildRecordCard(dynamic rec) {
    final prescriptions = _extractPrescriptions(rec['prescriptions']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(rec),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description, color: Color(0xFFFF9800)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec['diagnosis'] ?? '未填写诊断',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (rec['hospital'] != null)
                          Text(
                            '${rec['hospital']}${rec['department'] != null ? ' - ${rec['department']}' : ''}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                  if (rec['visitDate'] != null)
                    Text(
                      rec['visitDate'],
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                ],
              ),
              if (rec['member'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '就诊人: ${rec['member']['displayName']}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ],
              if (rec['chiefComplaint'] != null) ...[
                const SizedBox(height: 6),
                Text(
                  '主诉: ${rec['chiefComplaint']}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (prescriptions.isNotEmpty) ...[
                const Divider(height: 16),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: prescriptions.take(4).map<Widget>((p) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        p['name'] ?? '',
                        style: const TextStyle(color: AppColors.primary, fontSize: 12),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note, color: AppColors.primary),
              title: const Text('手动录入'),
              onTap: () {
                Navigator.pop(ctx);
                _showManualAddDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFFF9800)),
              title: const Text('AI识别(拍照)'),
              subtitle: const Text('拍摄病历/处方自动识别', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _showOcrDialog();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImage(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
    });
    final res = await ApiClient().dio.post('/upload/image', data: formData);
    return res.data['url'];
  }

  void _showOcrDialog() {
    File? selectedImage;
    final imageUrlCtrl = TextEditingController();
    bool loading = false;
    String statusText = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('AI识别病历'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 拍照和相册按钮
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: loading ? null : () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                          if (picked != null) {
                            setDialogState(() {
                              selectedImage = File(picked.path);
                              imageUrlCtrl.clear();
                            });
                          }
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('拍照'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: loading ? null : () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                          if (picked != null) {
                            setDialogState(() {
                              selectedImage = File(picked.path);
                              imageUrlCtrl.clear();
                            });
                          }
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('相册'),
                      ),
                    ),
                  ],
                ),
                // 图片预览
                if (selectedImage != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(selectedImage!, height: 160, width: double.infinity, fit: BoxFit.cover),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: imageUrlCtrl,
                  decoration: const InputDecoration(
                    labelText: '或输入图片URL',
                    hintText: '输入图片链接',
                  ),
                ),
                const SizedBox(height: 12),
                if (statusText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(statusText, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (loading || (selectedImage == null && imageUrlCtrl.text.isEmpty)) ? null : () async {
                      setDialogState(() { loading = true; statusText = ''; });
                      try {
                        String imageUrl = imageUrlCtrl.text;
                        // 如果选了图片，先上传
                        if (selectedImage != null) {
                          setDialogState(() => statusText = '上传图片中...');
                          imageUrl = await _uploadImage(selectedImage!) ?? '';
                          if (imageUrl.isEmpty) throw Exception('上传失败');
                        }
                        setDialogState(() => statusText = 'AI识别中...');
                        final family = context.read<FamilyProvider>();
                        final result = await context.read<MedicalRecordProvider>()
                            .ocrRecognize(family.currentFamilyId!, imageUrl);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _showManualAddDialog(prefill: result, imageUrl: imageUrl);
                      } catch (e) {
                        setDialogState(() { loading = false; statusText = ''; });
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('识别失败: $e')),
                          );
                        }
                      }
                    },
                    icon: loading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome),
                    label: Text(loading ? statusText : 'AI识别'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9800)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: loading ? null : () => Navigator.pop(ctx), child: const Text('取消')),
          ],
        ),
      ),
    );
  }

  void _showManualAddDialog({Map<String, dynamic>? prefill, String? imageUrl}) {
    final diagnosisCtrl = TextEditingController(text: prefill?['diagnosis'] ?? '');
    final hospitalCtrl = TextEditingController(text: prefill?['hospital'] ?? '');
    final departmentCtrl = TextEditingController(text: prefill?['department'] ?? '');
    final doctorCtrl = TextEditingController(text: prefill?['doctor'] ?? '');
    final chiefCtrl = TextEditingController(text: prefill?['chiefComplaint'] ?? '');
    final adviceCtrl = TextEditingController(text: prefill?['doctorAdvice'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(prefill != null ? '校对病历信息' : '手动录入病历'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (prefill != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFFFF9800), size: 16),
                      SizedBox(width: 6),
                      Expanded(child: Text('AI已识别，请校对后保存', style: TextStyle(fontSize: 13, color: Color(0xFFE65100)))),
                    ],
                  ),
                ),
              TextField(controller: diagnosisCtrl, decoration: const InputDecoration(labelText: '诊断')),
              const SizedBox(height: 8),
              TextField(controller: hospitalCtrl, decoration: const InputDecoration(labelText: '医院')),
              const SizedBox(height: 8),
              TextField(controller: departmentCtrl, decoration: const InputDecoration(labelText: '科室')),
              const SizedBox(height: 8),
              TextField(controller: doctorCtrl, decoration: const InputDecoration(labelText: '医生')),
              const SizedBox(height: 8),
              TextField(controller: chiefCtrl, decoration: const InputDecoration(labelText: '主诉'), maxLines: 2),
              const SizedBox(height: 8),
              TextField(controller: adviceCtrl, decoration: const InputDecoration(labelText: '医嘱'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              final family = context.read<FamilyProvider>();
              await context.read<MedicalRecordProvider>().createRecord(
                family.currentFamilyId!,
                {
                  'diagnosis': diagnosisCtrl.text,
                  'hospital': hospitalCtrl.text,
                  'department': departmentCtrl.text,
                  'doctor': doctorCtrl.text,
                  'chiefComplaint': chiefCtrl.text,
                  'doctorAdvice': adviceCtrl.text,
                  'prescriptions': prefill?['prescriptions'] ?? [],
                  'imageUrl': imageUrl,
                  'ocrRawData': prefill,
                },
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDetail(dynamic rec) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    if (isWide) {
      setState(() => _selectedRecord = rec);
      return;
    }

    final prescriptions = _extractPrescriptions(rec['prescriptions']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rec['diagnosis'] ?? '病历详情',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showEditDialog(rec);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final family = context.read<FamilyProvider>();
                      await context.read<MedicalRecordProvider>()
                          .deleteRecord(family.currentFamilyId!, rec['id']);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _detailRow('医院', rec['hospital']),
                  _detailRow('科室', rec['department']),
                  _detailRow('医生', rec['doctor']),
                  _detailRow('就诊日期', rec['visitDate']),
                  _detailRow('就诊人', rec['member']?['displayName']),
                  _detailRow('主诉', rec['chiefComplaint']),
                  _detailRow('现病史', rec['presentIllness']),
                  _detailRow('检查结果', rec['examinations']),
                  _detailRow('医嘱', rec['doctorAdvice']),
                  if (prescriptions.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(top: 16, bottom: 8),
                      child: Text('处方药品', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    ...prescriptions.map<Widget>((p) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.medication, color: AppColors.primary),
                        title: Text(p['name'] ?? ''),
                        subtitle: Text(
                          '${p['dosage'] ?? ''} ${p['frequency'] ?? ''} ${p['duration'] ?? ''}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    )),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(dynamic rec) {
    final diagnosisCtrl = TextEditingController(text: rec['diagnosis'] ?? '');
    final hospitalCtrl = TextEditingController(text: rec['hospital'] ?? '');
    final departmentCtrl = TextEditingController(text: rec['department'] ?? '');
    final doctorCtrl = TextEditingController(text: rec['doctor'] ?? '');
    final chiefCtrl = TextEditingController(text: rec['chiefComplaint'] ?? '');
    final adviceCtrl = TextEditingController(text: rec['doctorAdvice'] ?? '');
    final presentCtrl = TextEditingController(text: rec['presentIllness'] ?? '');
    final examCtrl = TextEditingController(text: rec['examinations'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑病历'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: diagnosisCtrl, decoration: const InputDecoration(labelText: '诊断')),
              const SizedBox(height: 8),
              TextField(controller: hospitalCtrl, decoration: const InputDecoration(labelText: '医院')),
              const SizedBox(height: 8),
              TextField(controller: departmentCtrl, decoration: const InputDecoration(labelText: '科室')),
              const SizedBox(height: 8),
              TextField(controller: doctorCtrl, decoration: const InputDecoration(labelText: '医生')),
              const SizedBox(height: 8),
              TextField(controller: chiefCtrl, decoration: const InputDecoration(labelText: '主诉'), maxLines: 2),
              const SizedBox(height: 8),
              TextField(controller: presentCtrl, decoration: const InputDecoration(labelText: '现病史'), maxLines: 2),
              const SizedBox(height: 8),
              TextField(controller: examCtrl, decoration: const InputDecoration(labelText: '检查结果'), maxLines: 2),
              const SizedBox(height: 8),
              TextField(controller: adviceCtrl, decoration: const InputDecoration(labelText: '医嘱'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              final family = context.read<FamilyProvider>();
              await context.read<MedicalRecordProvider>().updateRecord(
                family.currentFamilyId!,
                rec['id'],
                {
                  'diagnosis': diagnosisCtrl.text,
                  'hospital': hospitalCtrl.text,
                  'department': departmentCtrl.text,
                  'doctor': doctorCtrl.text,
                  'chiefComplaint': chiefCtrl.text,
                  'presentIllness': presentCtrl.text,
                  'examinations': examCtrl.text,
                  'doctorAdvice': adviceCtrl.text,
                },
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                // 编辑后刷新右侧面板
                setState(() => _selectedRecord = null);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('病历已更新'), backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel(dynamic rec) {
    final prescriptions = _extractPrescriptions(rec['prescriptions']);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(rec['diagnosis'] ?? '病历详情',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                onPressed: () => _showEditDialog(rec),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                onPressed: () async {
                  final family = context.read<FamilyProvider>();
                  await context.read<MedicalRecordProvider>()
                      .deleteRecord(family.currentFamilyId!, rec['id']);
                  if (mounted) setState(() => _selectedRecord = null);
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _detailRow('医院', rec['hospital']),
              _detailRow('科室', rec['department']),
              _detailRow('医生', rec['doctor']),
              _detailRow('就诊日期', rec['visitDate']),
              _detailRow('主诉', rec['chiefComplaint']),
              _detailRow('现病史', rec['presentIllness']),
              _detailRow('检查结果', rec['examinations']),
              _detailRow('医嘱', rec['doctorAdvice']),
              if (prescriptions.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 8),
                  child: Text('处方药品', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                ...prescriptions.map<Widget>((p) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.medication, color: AppColors.primary),
                    title: Text(p['name'] ?? ''),
                    subtitle: Text('${p['dosage'] ?? ''} ${p['frequency'] ?? ''}',
                        style: const TextStyle(fontSize: 13)),
                  ),
                )),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  /// prescriptions 可能是 List（旧格式）或 {"items": [...]}（新格式）
  static List _extractPrescriptions(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) return raw['items'] as List? ?? [];
    return [];
  }
}
