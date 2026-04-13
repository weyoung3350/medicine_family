import 'package:flutter/material.dart';
import '../network/api_client.dart';

class AiProvider extends ChangeNotifier {
  final _api = ApiClient().dio;
  List<dynamic> consultations = [];

  Future<void> loadConsultations(String familyId) async {
    try {
      final res = await _api.get('/ai/consultations', queryParameters: {'familyId': familyId});
      consultations = res.data;
    } catch (_) {
      consultations = [];
    }
    notifyListeners();
  }
}
