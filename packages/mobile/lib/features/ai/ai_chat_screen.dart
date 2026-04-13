import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/theme.dart';
import '../../core/network/api_client.dart';
import '../../core/providers/family_provider.dart';
import 'consultation_history_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});
  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _api = ApiClient().dio;
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  // 每条消息可以附带结构化数据
  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'assistant',
      'content': '你好！我是你的AI药品助手。\n\n可以问我：\n- 药物相互作用\n- 服药注意事项\n- 药箱库存查询\n\n请问有什么需要帮助的？',
    },
  ];
  bool _loading = false;

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _loading) return;
    _inputCtrl.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _loading = true;
    });
    _scrollToBottom();

    try {
      final family = context.read<FamilyProvider>();
      final familyId = family.currentFamilyId ?? '';
      final memberId = family.members.isNotEmpty ? family.members[0]['id'] ?? '' : '';
      final res = await _api.post('/ai/chat', data: {
        'familyId': familyId,
        'memberId': memberId,
        'message': text,
      });
      final reply = res.data['reply'] ?? '暂无回复';
      final detail = res.data['resultDetail'];
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': reply,
          'resultDetail': detail,
        });
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': '抱歉，出错了。请检查网络连接。'});
      });
    }
    setState(() => _loading = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 助手'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '咨询历史',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConsultationHistoryScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          // 快捷操作
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _quickChip('查相互作用', Icons.compare_arrows),
                const SizedBox(width: 8),
                _quickChip('服药指南', Icons.menu_book),
                const SizedBox(width: 8),
                _quickChip('查库存', Icons.inventory),
              ],
            ),
          ),
          const Divider(height: 1),

          // 消息列表
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 8),
                          Text('AI 正在思考...', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  );
                }
                final msg = _messages[i];
                final isUser = msg['role'] == 'user';

                if (!isUser && msg['resultDetail'] != null) {
                  return _buildStructuredReply(msg);
                }
                return _buildBubble(msg, isUser);
              },
            ),
          ),

          // 输入框
          Container(
            padding: EdgeInsets.only(left: 16, right: 8, top: 8, bottom: MediaQuery.of(context).padding.bottom + 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: '输入问题...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: AppColors.bgMain,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: _pickAndAnalyze,
                  icon: const Icon(Icons.camera_alt, color: AppColors.accent),
                  tooltip: '拍照分析',
                ),
                IconButton(
                  onPressed: _send,
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  style: IconButton.styleFrom(backgroundColor: AppColors.primaryLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 普通聊天气泡
  Widget _buildBubble(Map<String, dynamic> msg, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.primaryLight,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          msg['content'] ?? '',
          style: TextStyle(color: isUser ? Colors.white : AppColors.textPrimary, fontSize: 15, height: 1.5),
        ),
      ),
    );
  }

  /// 结构化回复卡片：回复正文 + 高亮要点 + 免责声明
  Widget _buildStructuredReply(Map<String, dynamic> msg) {
    final detail = msg['resultDetail'] as Map<String, dynamic>;
    final reply = msg['content'] as String? ?? '';
    final highlights = (detail['highlights'] as List<dynamic>?)?.cast<String>() ?? [];

    // 检测是否包含风险/警告关键词
    final hasRisk = reply.contains('风险') || reply.contains('禁忌') ||
        reply.contains('冲突') || reply.contains('不建议') || reply.contains('注意');

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 风险提示横幅
                if (hasRisk)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber, color: AppColors.danger, size: 20),
                        SizedBox(width: 8),
                        Text('包含用药安全提示，请仔细阅读',
                            style: TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),

                // 回复正文
                Text(reply, style: const TextStyle(fontSize: 15, height: 1.6)),

                // 关键要点
                if (highlights.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_outline, size: 16, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text('关键要点', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...highlights.map((h) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                              Expanded(child: Text(h, style: const TextStyle(fontSize: 14))),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ],

                // 免责声明（结构化回复始终显示）
                const SizedBox(height: 10),
                const Text(
                  '⚕ 以上建议仅供参考，请遵医嘱',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndAnalyze() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('拍照'), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('相册'), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
          ],
        ),
      ),
    );
    if (source == null) return;
    final image = await picker.pickImage(source: source, imageQuality: 85);
    if (image == null) return;

    final bytes = await File(image.path).readAsBytes();
    final base64Img = 'data:image/jpeg;base64,${base64Encode(bytes)}';

    setState(() {
      _messages.add({'role': 'user', 'content': '[已上传图片] 请分析这张诊疗单/药品包装'});
      _loading = true;
    });
    _scrollToBottom();

    try {
      final family = context.read<FamilyProvider>();
      final familyId = family.currentFamilyId ?? '';
      final memberId = family.members.isNotEmpty ? family.members[0]['id'] ?? '' : '';
      final res = await _api.post('/ai/chat', data: {
        'familyId': familyId,
        'memberId': memberId,
        'message': '请分析这张图片',
        'images': [base64Img],
      });
      final reply = res.data['reply'] ?? '无法识别';
      final detail = res.data['resultDetail'];
      setState(() => _messages.add({
        'role': 'assistant',
        'content': reply,
        'resultDetail': detail,
      }));
    } catch (e) {
      setState(() => _messages.add({'role': 'assistant', 'content': '分析失败，请重试。'}));
    }
    setState(() => _loading = false);
    _scrollToBottom();
  }

  Widget _quickChip(String label, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.primary),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () {
        _inputCtrl.text = label == '查相互作用'
            ? '请检查我当前正在服用的所有药物之间是否有相互作用。'
            : label == '服药指南'
                ? '请告诉我当前服用药物的注意事项。'
                : '请查看我家药箱的库存情况。';
        _send();
      },
    );
  }
}
