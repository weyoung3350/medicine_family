import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final _api = ApiClient().dio;
  Map<String, dynamic>? _user;
  bool _isLoggedIn = false;

  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _isLoggedIn;

  AuthProvider() {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      try {
        final res = await _api.get('/auth/profile');
        _user = res.data;
        _isLoggedIn = true;
      } catch (_) {
        await prefs.remove('token');
      }
    }
    notifyListeners();
  }

  Future<void> login(String account, String password) async {
    final res = await _api.post('/auth/login', data: {
      'account': account,
      'password': password,
    });
    final token = res.data['access_token'];
    _user = res.data['user'];
    _isLoggedIn = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    notifyListeners();
  }

  Future<void> register(String phone, String nickname, String password) async {
    final res = await _api.post('/auth/register', data: {
      'phone': phone,
      'nickname': nickname,
      'password': password,
    });
    final token = res.data['access_token'];
    _user = res.data['user'];
    _isLoggedIn = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _isLoggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }
}
