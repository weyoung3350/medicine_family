import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';

class FamilyProvider extends ChangeNotifier {
  final _api = ApiClient().dio;
  List<dynamic> families = [];
  List<dynamic> members = [];
  String? currentFamilyId;

  Future<void> loadFamilies() async {
    final res = await _api.get('/families');
    families = res.data;
    if (families.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final stored = currentFamilyId ?? prefs.getString('familyId');
      // 校验存储的 familyId 是否仍在列表中
      final valid = families.any((f) => f['id'] == stored);
      currentFamilyId = valid ? stored : families[0]['id'];
      await prefs.setString('familyId', currentFamilyId!);
      try {
        await loadMembers();
      } catch (_) {
        members = [];
      }
    }
    notifyListeners();
  }

  Future<void> setCurrentFamily(String id) async {
    currentFamilyId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('familyId', id);
    await loadMembers();
    notifyListeners();
  }

  Future<void> loadMembers() async {
    if (currentFamilyId == null) return;
    final res = await _api.get('/families/$currentFamilyId/members');
    members = res.data;
    notifyListeners();
  }

  Future<void> createFamily(String name) async {
    await _api.post('/families', data: {'name': name});
    await loadFamilies();
  }

  Future<void> joinFamily(String code) async {
    await _api.post('/families/join', data: {'inviteCode': code});
    await loadFamilies();
  }

  Future<Map<String, dynamic>?> loadHealthProfile(String familyId, String memberId) async {
    try {
      final res = await _api.get('/families/$familyId/members/$memberId/health');
      return Map<String, dynamic>.from(res.data);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateHealthProfile(String familyId, String memberId, Map<String, dynamic> data) async {
    await _api.put('/families/$familyId/members/$memberId/health', data: data);
    await loadMembers();
  }
}
