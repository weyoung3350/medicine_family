import 'package:flutter/material.dart';
import '../network/api_client.dart';

class MedicineProvider extends ChangeNotifier {
  final _api = ApiClient().dio;
  List<dynamic> medicines = [];
  List<dynamic> expiringMeds = [];
  List<dynamic> lowStockMeds = [];

  Future<void> loadMedicines(String familyId) async {
    final res = await _api.get('/families/$familyId/medicines');
    medicines = res.data;
    notifyListeners();
  }

  Future<void> loadExpiring(String familyId) async {
    try {
      final res = await _api.get('/families/$familyId/medicines/expiring');
      expiringMeds = res.data;
    } catch (_) {
      expiringMeds = [];
    }
    notifyListeners();
  }

  Future<void> loadLowStock(String familyId) async {
    try {
      final res = await _api.get('/families/$familyId/medicines/low-stock');
      lowStockMeds = res.data;
    } catch (_) {
      lowStockMeds = [];
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> ocrRecognize(String familyId, String imageUrl) async {
    final res = await _api.post('/families/$familyId/medicines/ocr', data: {'imageUrl': imageUrl});
    return res.data;
  }

  Future<Map<String, dynamic>?> addMedicine(String familyId, Map<String, dynamic> data) async {
    final res = await _api.post('/families/$familyId/medicines', data: data);
    await loadMedicines(familyId);
    return res.data != null ? Map<String, dynamic>.from(res.data) : null;
  }

  Future<void> addInventory(String familyId, String medicineId, Map<String, dynamic> data) async {
    await _api.post('/families/$familyId/medicines/$medicineId/inventory', data: data);
    await loadMedicines(familyId);
  }

  Future<Map<String, dynamic>> getMedicineDetail(String familyId, String medicineId) async {
    final res = await _api.get('/families/$familyId/medicines/$medicineId');
    return Map<String, dynamic>.from(res.data);
  }
}
