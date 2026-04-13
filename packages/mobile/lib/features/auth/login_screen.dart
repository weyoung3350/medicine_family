import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _accountCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;

  Future<void> _handleLogin() async {
    if (_accountCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      _showMsg('请填写完整信息');
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().login(_accountCtrl.text, _passwordCtrl.text);
    } catch (e) {
      _showMsg('登录失败: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _handleRegister() async {
    if (_phoneCtrl.text.isEmpty || _nicknameCtrl.text.isEmpty || _regPassCtrl.text.isEmpty) {
      _showMsg('请填写完整信息');
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().register(_phoneCtrl.text, _nicknameCtrl.text, _regPassCtrl.text);
    } catch (e) {
      _showMsg('注册失败: $e');
    }
    setState(() => _loading = false);
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1B2A), Color(0xFF1B2A4A), Color(0xFF1a3a5c)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // Logo
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Icons.local_pharmacy, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text('家庭健康管家', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 4)),
                  const SizedBox(height: 4),
                  Text('家庭健康管理与服药提醒', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
                  const SizedBox(height: 40),

                  // 毛玻璃卡片
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        // 切换登录/注册
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isLogin = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border(bottom: BorderSide(color: _isLogin ? AppColors.primary : Colors.transparent, width: 2)),
                                  ),
                                  child: Text('登录', textAlign: TextAlign.center, style: TextStyle(color: _isLogin ? Colors.white : Colors.white54, fontSize: 16, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isLogin = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border(bottom: BorderSide(color: !_isLogin ? AppColors.primary : Colors.transparent, width: 2)),
                                  ),
                                  child: Text('注册', textAlign: TextAlign.center, style: TextStyle(color: !_isLogin ? Colors.white : Colors.white54, fontSize: 16, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        if (_isLogin) ...[
                          _buildInput(_accountCtrl, '手机号或邮箱', Icons.person_outline),
                          const SizedBox(height: 16),
                          _buildInput(_passwordCtrl, '密码', Icons.lock_outline, obscure: true),
                          const SizedBox(height: 24),
                          _buildButton('登录', _handleLogin),
                        ] else ...[
                          _buildInput(_phoneCtrl, '手机号', Icons.phone_outlined),
                          const SizedBox(height: 16),
                          _buildInput(_nicknameCtrl, '昵称', Icons.face_outlined),
                          const SizedBox(height: 16),
                          _buildInput(_regPassCtrl, '密码(至少6位)', Icons.lock_outline, obscure: true),
                          const SizedBox(height: 24),
                          _buildButton('注册', _handleRegister),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String hint, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _loading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
