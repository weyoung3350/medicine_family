import 'package:flutter/material.dart';
import '../network/api_client.dart';

/// 站内消息 Provider。
class NotificationProvider extends ChangeNotifier {
  final _api = ApiClient();

  List<Map<String, dynamic>> _messages = [];
  int _unreadCount = 0;
  bool _loading = false;

  List<Map<String, dynamic>> get messages => _messages;
  int get unreadCount => _unreadCount;
  bool get loading => _loading;

  Future<void> loadMessages() async {
    _loading = true;
    notifyListeners();
    try {
      final resp = await _api.dio.get('/notifications');
      _messages = List<Map<String, dynamic>>.from(resp.data ?? []);
    } catch (_) {
      _messages = [];
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadUnreadCount() async {
    try {
      final resp = await _api.dio.get('/notifications/unread-count');
      _unreadCount = (resp.data?['count'] ?? 0) as int;
    } catch (_) {
      _unreadCount = 0;
    }
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    try {
      await _api.dio.post('/notifications/$id/read');
      final idx = _messages.indexWhere((m) => m['id'] == id);
      if (idx >= 0) {
        _messages[idx] = {..._messages[idx], 'isRead': true};
      }
      notifyListeners();
      await loadUnreadCount();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _api.dio.post('/notifications/read-all');
      _messages = _messages.map((m) => {...m, 'isRead': true}).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }
}
