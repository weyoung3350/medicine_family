import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/providers/family_provider.dart';

class HealthProfileScreen extends StatefulWidget {
  final String familyId;
  final Map<String, dynamic> member;

  const HealthProfileScreen({super.key, required this.familyId, required this.member});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  bool _loading = true;
  bool _saving = false;

  final _birthDateCtrl = TextEditingController();
  String? _gender;
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  String? _bloodType;
  List<String> _medicalHistory = [];
  List<String> _allergyList = [];
  List<String> _chronicMeds = [];
  final _notesCtrl = TextEditingController();

  final _newItemCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _birthDateCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    _newItemCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final family = context.read<FamilyProvider>();
      final res = await family.loadHealthProfile(widget.familyId, widget.member['id']);
      if (res != null) {
        _birthDateCtrl.text = res['birthDate'] ?? '';
        _gender = res['gender'];
        _heightCtrl.text = (res['heightCm'] ?? '').toString();
        _weightCtrl.text = (res['weightKg'] ?? '').toString();
        _bloodType = res['bloodType'];
        _medicalHistory = List<String>.from(res['medicalHistory'] ?? []);
        _allergyList = List<String>.from(res['allergyList'] ?? []);
        _chronicMeds = List<String>.from(res['chronicMeds'] ?? []);
        _notesCtrl.text = res['notes'] ?? '';
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.member['displayName'] ?? ''}的健康档案'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('保存', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Birth date
                TextFormField(
                  controller: _birthDateCtrl,
                  decoration: const InputDecoration(
                    labelText: '出生日期',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.tryParse(_birthDateCtrl.text) ?? DateTime(2000),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      _birthDateCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Gender
                const Text('性别', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'male', label: Text('男')),
                    ButtonSegment(value: 'female', label: Text('女')),
                  ],
                  selected: _gender != null ? {_gender!} : {},
                  emptySelectionAllowed: true,
                  onSelectionChanged: (s) => setState(() => _gender = s.isNotEmpty ? s.first : null),
                  style: ButtonStyle(
                    shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                ),
                const SizedBox(height: 16),

                // Height & Weight
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _heightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '身高 (cm)'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _weightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '体重 (kg)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Blood type
                DropdownButtonFormField<String>(
                  value: _bloodType,
                  decoration: const InputDecoration(labelText: '血型'),
                  items: const [
                    DropdownMenuItem(value: 'A', child: Text('A型')),
                    DropdownMenuItem(value: 'B', child: Text('B型')),
                    DropdownMenuItem(value: 'AB', child: Text('AB型')),
                    DropdownMenuItem(value: 'O', child: Text('O型')),
                  ],
                  onChanged: (v) => setState(() => _bloodType = v),
                ),
                const SizedBox(height: 20),

                // Medical history
                _chipSection(
                  title: '病史',
                  items: _medicalHistory,
                  onAdd: (v) => setState(() => _medicalHistory.add(v)),
                  onRemove: (i) => setState(() => _medicalHistory.removeAt(i)),
                ),
                const SizedBox(height: 16),

                // Allergies
                _chipSection(
                  title: '过敏史',
                  items: _allergyList,
                  onAdd: (v) => setState(() => _allergyList.add(v)),
                  onRemove: (i) => setState(() => _allergyList.removeAt(i)),
                  chipColor: AppColors.danger,
                ),
                const SizedBox(height: 16),

                // Chronic medications
                _chipSection(
                  title: '长期用药',
                  items: _chronicMeds,
                  onAdd: (v) => setState(() => _chronicMeds.add(v)),
                  onRemove: (i) => setState(() => _chronicMeds.removeAt(i)),
                  chipColor: AppColors.accent,
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: '备注'),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _chipSection({
    required String title,
    required List<String> items,
    required Function(String) onAdd,
    required Function(int) onRemove,
    Color chipColor = AppColors.primary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showAddItemDialog(title, onAdd),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('添加'),
            ),
          ],
        ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('暂无', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: items.asMap().entries.map((e) {
              return Chip(
                label: Text(e.value, style: TextStyle(color: chipColor, fontSize: 13)),
                backgroundColor: chipColor.withValues(alpha: 0.1),
                deleteIcon: Icon(Icons.close, size: 16, color: chipColor),
                onDeleted: () => onRemove(e.key),
              );
            }).toList(),
          ),
      ],
    );
  }

  void _showAddItemDialog(String title, Function(String) onAdd) {
    _newItemCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('添加$title'),
        content: TextField(
          controller: _newItemCtrl,
          autofocus: true,
          decoration: InputDecoration(hintText: '输入$title'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (_newItemCtrl.text.trim().isNotEmpty) {
                onAdd(_newItemCtrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'medicalHistory': _medicalHistory,
        'allergyList': _allergyList,
        'chronicMeds': _chronicMeds,
        'notes': _notesCtrl.text,
      };
      if (_birthDateCtrl.text.isNotEmpty) data['birthDate'] = _birthDateCtrl.text;
      if (_gender != null) data['gender'] = _gender;
      if (_heightCtrl.text.isNotEmpty) data['heightCm'] = double.tryParse(_heightCtrl.text);
      if (_weightCtrl.text.isNotEmpty) data['weightKg'] = double.tryParse(_weightCtrl.text);
      if (_bloodType != null) data['bloodType'] = _bloodType;

      await context.read<FamilyProvider>().updateHealthProfile(
        widget.familyId,
        widget.member['id'],
        data,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('健康档案已保存'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }
}
