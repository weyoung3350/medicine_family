import 'package:flutter/material.dart';
import '../network/api_client.dart';

class PharmacyProvider extends ChangeNotifier {
  final _api = ApiClient().dio;
  List<dynamic> pharmacies = [];
  bool loading = false;

  Future<void> searchNearby({
    required double lng,
    required double lat,
    int radius = 3000,
    String keyword = '药店',
  }) async {
    loading = true;
    notifyListeners();
    try {
      final res = await _api.get('/pharmacy/nearby', queryParameters: {
        'lng': lng,
        'lat': lat,
        'radius': radius,
        'keyword': keyword,
      });
      pharmacies = res.data;
    } catch (_) {
      pharmacies = [];
    }
    loading = false;
    notifyListeners();
  }
}
