import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/providers/medicine_provider.dart';
import '../../core/providers/medication_provider.dart';

class CreatePlanScreen extends StatefulWidget {
  final String familyId;
  final String memberId;
  /// OCR 识别后预填的药品 ID 和用法用量信息
  final Map<String, dynamic>? prefill;

  const CreatePlanScreen({super.key, required this.familyId, required this.memberId, this.prefill});

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // Form state
  String? _selectedMedicineId;
  final _dosageAmountCtrl = TextEditingController();
  final _dosageUnitCtrl = TextEditingController(text: '粒');
  String _frequencyType = 'daily';
  final List<int> _weeklyDays = [];
  final _customIntervalCtrl = TextEditingController(text: '2');
  String _mealRelation = 'after_meal';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  int _gracePeriod = 30;

  // Schedule time points
  final List<Map<String, dynamic>> _schedules = [
    {'time': const TimeOfDay(hour: 8, minute: 0), 'label': '早餐后'},
  ];

  @override
  void initState() {
    super.initState();
    context.read<MedicineProvider>().loadMedicines(widget.familyId);
    _applyPrefill();
  }

  void _applyPrefill() {
    final p = widget.prefill;
    if (p == null) return;
    _selectedMedicineId = p['medicineId'] as String?;
    if (p['dosageAmount'] != null) _dosageAmountCtrl.text = '${p['dosageAmount']}';
    if (p['dosageUnit'] != null) _dosageUnitCtrl.text = p['dosageUnit'] as String;
    if (p['usageGuide'] != null) {
      // 从用法用量文本推测服药频次和时间（简单解析）
      final usage = (p['usageGuide'] as String).toLowerCase();
      if (usage.contains('一日三次') || usage.contains('3次')) {
        _schedules.clear();
        _schedules.addAll([
          {'time': const TimeOfDay(hour: 8, minute: 0), 'label': '早餐后'},
          {'time': const TimeOfDay(hour: 12, minute: 0), 'label': '午餐后'},
          {'time': const TimeOfDay(hour: 18, minute: 0), 'label': '晚餐后'},
        ]);
      } else if (usage.contains('一日两次') || usage.contains('2次')) {
        _schedules.clear();
        _schedules.addAll([
          {'time': const TimeOfDay(hour: 8, minute: 0), 'label': '早餐后'},
          {'time': const TimeOfDay(hour: 18, minute: 0), 'label': '晚餐后'},
        ]);
      }
      if (usage.contains('饭前')) _mealRelation = 'before_meal';
      if (usage.contains('饭后')) _mealRelation = 'after_meal';
      if (usage.contains('空腹')) _mealRelation = 'empty_stomach';
    }
  }

  @override
  void dispose() {
    _dosageAmountCtrl.dispose();
    _dosageUnitCtrl.dispose();
    _customIntervalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final medProv = context.watch<MedicineProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('创建服药计划')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Medicine selection
            const Text('选择药品', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedMedicineId,
              decoration: const InputDecoration(hintText: '请选择药品'),
              items: medProv.medicines.map<DropdownMenuItem<String>>((m) {
                return DropdownMenuItem(
                  value: m['id'] as String,
                  child: Text('${m['name'] ?? ''} ${m['specification'] != null ? "(${m['specification']})" : ""}'),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedMedicineId = v),
              validator: (v) => v == null ? '请选择药品' : null,
            ),
            const SizedBox(height: 20),

            // Dosage
            const Text('剂量', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _dosageAmountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '用量'),
                    validator: (v) => (v == null || v.isEmpty) ? '请输入用量' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _dosageUnitCtrl,
                    decoration: const InputDecoration(labelText: '单位'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Frequency
            const Text('频率', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'daily', label: Text('每日')),
                ButtonSegment(value: 'every_other_day', label: Text('隔日')),
                ButtonSegment(value: 'weekly', label: Text('每周')),
                ButtonSegment(value: 'custom', label: Text('自定义')),
              ],
              selected: {_frequencyType},
              onSelectionChanged: (s) => setState(() => _frequencyType = s.first),
            ),

            // Weekly day selection
            if (_frequencyType == 'weekly') ...[
              const SizedBox(height: 12),
              const Text('选择星期', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(7, (i) {
                  final labels = ['一', '二', '三', '四', '五', '六', '日'];
                  final selected = _weeklyDays.contains(i + 1);
                  return FilterChip(
                    label: Text('周${labels[i]}'),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _weeklyDays.add(i + 1);
                        } else {
                          _weeklyDays.remove(i + 1);
                        }
                      });
                    },
                  );
                }),
              ),
            ],

            // Custom interval
            if (_frequencyType == 'custom') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('每 '),
                  SizedBox(
                    width: 60,
                    child: TextFormField(
                      controller: _customIntervalCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Text(' 天一次'),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // Schedule time points
            Row(
              children: [
                const Text('服药时间', style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addSchedule,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加时间'),
                ),
              ],
            ),
            ..._schedules.asMap().entries.map((e) {
              final i = e.key;
              final s = e.value;
              final time = s['time'] as TimeOfDay;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: InkWell(
                    onTap: () => _pickTime(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ),
                  ),
                  title: TextFormField(
                    initialValue: s['label'] as String,
                    decoration: const InputDecoration(
                      hintText: '标签（如：早餐后）',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (v) => _schedules[i]['label'] = v,
                  ),
                  trailing: _schedules.length > 1
                      ? IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger, size: 20),
                          onPressed: () => setState(() => _schedules.removeAt(i)),
                        )
                      : null,
                ),
              );
            }),
            const SizedBox(height: 20),

            // Meal relation
            const Text('餐时关系', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _mealRelation,
              items: const [
                DropdownMenuItem(value: 'before_meal', child: Text('饭前')),
                DropdownMenuItem(value: 'after_meal', child: Text('饭后')),
                DropdownMenuItem(value: 'with_meal', child: Text('随餐')),
                DropdownMenuItem(value: 'empty_stomach', child: Text('空腹')),
                DropdownMenuItem(value: 'anytime', child: Text('不限')),
              ],
              onChanged: (v) => setState(() => _mealRelation = v!),
            ),
            const SizedBox(height: 20),

            // Date range
            const Text('起止日期', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(true),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_formatDate(_startDate)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('~'),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(false),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_endDate != null ? _formatDate(_endDate!) : '长期'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Grace period
            const Text('告警宽限期', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _gracePeriod.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    label: '$_gracePeriod 分钟',
                    onChanged: (v) => setState(() => _gracePeriod = v.round()),
                  ),
                ),
                Text('$_gracePeriod 分钟', style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 32),

            // Submit
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('创建计划', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _addSchedule() {
    setState(() {
      _schedules.add({'time': const TimeOfDay(hour: 12, minute: 0), 'label': ''});
    });
  }

  Future<void> _pickTime(int index) async {
    final current = _schedules[index]['time'] as TimeOfDay;
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null) {
      setState(() => _schedules[index]['time'] = picked);
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : (_endDate ?? DateTime.now().add(const Duration(days: 30)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final schedules = _schedules.map((s) {
        final time = s['time'] as TimeOfDay;
        return {
          'timeOfDay': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
          'label': s['label'],
        };
      }).toList();

      final data = <String, dynamic>{
        'medicineId': _selectedMedicineId,
        'dosageAmount': double.tryParse(_dosageAmountCtrl.text) ?? 1,
        'dosageUnit': _dosageUnitCtrl.text,
        'frequencyType': _frequencyType,
        'mealRelation': _mealRelation,
        'startDate': _formatDate(_startDate),
        'gracePeriodMinutes': _gracePeriod,
        'schedules': schedules,
      };

      if (_frequencyType == 'weekly') {
        data['frequencyDays'] = _weeklyDays;
      }
      if (_frequencyType == 'custom') {
        data['customInterval'] = int.tryParse(_customIntervalCtrl.text) ?? 2;
      }
      if (_endDate != null) {
        data['endDate'] = _formatDate(_endDate!);
      }

      await context.read<MedicationProvider>().createPlan(
        widget.familyId,
        widget.memberId,
        data,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('服药计划已创建'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
