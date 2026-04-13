import 'package:flutter/material.dart';
import '../network/api_client.dart';

class MedicalRecordProvider extends ChangeNotifier {
  final _api = ApiClient().dio;
  List<dynamic> records = [];

  Future<void> loadRecords(String familyId, {String? memberId, String? keyword}) async {
    final params = <String, dynamic>{};
    if (memberId != null) params['memberId'] = memberId;
    if (keyword != null) params['keyword'] = keyword;
    final res = await _api.get('/families/$familyId/medical-records', queryParameters: params);
    records = res.data;
    notifyListeners();
  }

  Future<Map<String, dynamic>> ocrRecognize(String familyId, String imageUrl) async {
    final res = await _api.post(
      '/families/$familyId/medical-records/ocr',
      data: {'imageUrl': imageUrl},
    );
    return Map<String, dynamic>.from(res.data);
  }

  Future<void> createRecord(String familyId, Map<String, dynamic> data) async {
    await _api.post('/families/$familyId/medical-records', data: data);
    await loadRecords(familyId);
  }

  Future<void> deleteRecord(String familyId, String recordId) async {
    await _api.delete('/families/$familyId/medical-records/$recordId');
    await loadRecords(familyId);
  }

  Future<void> updateRecord(String familyId, String recordId, Map<String, dynamic> data) async {
    await _api.put('/families/$familyId/medical-records/$recordId', data: data);
    await loadRecords(familyId);
  }
}
