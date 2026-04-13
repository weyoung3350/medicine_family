import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/providers/ai_provider.dart';
import '../../core/providers/family_provider.dart';

class ConsultationHistoryScreen extends StatefulWidget {
  const ConsultationHistoryScreen({super.key});
  @override
  State<ConsultationHistoryScreen> createState() => _ConsultationHistoryScreenState();
}

class _ConsultationHistoryScreenState extends State<ConsultationHistoryScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final family = context.read<FamilyProvider>();
    if (family.currentFamilyId != null) {
      await context.read<AiProvider>().loadConsultations(family.currentFamilyId!);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final aiProv = context.watch<AiProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('咨询历史')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : aiProv.consultations.isEmpty
              ? const Center(
                  child: Text('暂无咨询记录', style: TextStyle(color: AppColors.textSecondary)),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: aiProv.consultations.length,
                    itemBuilder: (context, i) => _buildCard(aiProv.consultations[i]),
                  ),
                ),
    );
  }

  Widget _buildCard(dynamic consultation) {
    final type = consultation['type'] ?? '';
    final summary = consultation['resultSummary'] ?? consultation['inputText'] ?? '';
    final createdAt = consultation['createdAt'] ?? '';

    Color typeColor;
    String typeLabel;
    switch (type) {
      case 'prescription_ocr':
        typeColor = const Color(0xFFFF9800);
        typeLabel = '处方识别';
        break;
      case 'medication_check':
        typeColor = AppColors.danger;
        typeLabel = '用药检查';
        break;
      case 'interaction_check':
        typeColor = const Color(0xFF9C27B0);
        typeLabel = '相互作用';
        break;
      case 'image_analysis':
        typeColor = AppColors.primary;
        typeLabel = '图片分析';
        break;
      default:
        typeColor = AppColors.success;
        typeLabel = '问答咨询';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(consultation),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(typeLabel, style: TextStyle(color: typeColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  Text(_formatTime(createdAt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                summary,
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(dynamic consultation) {
    final detail = consultation['resultDetail'] ?? consultation['resultSummary'] ?? '无详情';
    final input = consultation['inputText'] ?? '';
    final type = consultation['type'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
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
                  const Text('咨询详情', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(type, style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(16),
                children: [
                  if (input.isNotEmpty) ...[
                    const Text('提问', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(input, style: const TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text('回复', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Text(detail, style: const TextStyle(fontSize: 14, height: 1.6)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}
