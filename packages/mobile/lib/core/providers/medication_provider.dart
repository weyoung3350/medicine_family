import 'package:flutter/material.dart';
import '../network/api_client.dart';

class MedicationProvider extends ChangeNotifier {
  final _api = ApiClient().dio;
  List<dynamic> todayItems = [];
  List<dynamic> plans = [];
  Map<String, dynamic>? adherence;

  Future<void> loadToday(String familyId, String memberId) async {
    try {
      final res = await _api.get('/families/$familyId/members/$memberId/plans/today');
      todayItems = res.data;
    } catch (_) {
      todayItems = [];
    }
    notifyListeners();
  }

  Future<void> loadPlans(String familyId, String memberId) async {
    final res = await _api.get('/families/$familyId/members/$memberId/plans');
    plans = res.data;
    notifyListeners();
  }

  Future<void> checkIn(String familyId, String memberId, String planId, String scheduleId, {bool skip = false}) async {
    await _api.post(
      '/families/$familyId/members/$memberId/plans/$planId/schedules/$scheduleId/check-in',
      data: {'skip': skip},
    );
    await loadToday(familyId, memberId);
  }

  Future<void> loadAdherence(String familyId, String memberId, {String range = 'week'}) async {
    try {
      final res = await _api.get('/families/$familyId/members/$memberId/plans/adherence', queryParameters: {'range': range});
      adherence = res.data;
    } catch (_) {
      adherence = null;
    }
    notifyListeners();
  }

  Future<void> createPlan(String familyId, String memberId, Map<String, dynamic> data) async {
    await _api.post('/families/$familyId/members/$memberId/plans', data: data);
    await loadPlans(familyId, memberId);
    await loadToday(familyId, memberId);
  }
}
