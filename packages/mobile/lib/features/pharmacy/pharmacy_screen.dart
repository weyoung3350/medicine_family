import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/providers/pharmacy_provider.dart';

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key});
  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  bool _locating = true;
  String? _error;
  final _searchCtrl = TextEditingController(text: '药店');
  int _radius = 3000;

  @override
  void initState() {
    super.initState();
    _locate();
  }

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      // 使用后端代理方式，传入默认坐标（实际使用时会通过 geolocator 插件获取真实位置）
      // 这里先用一个模拟位置，用户可以手动搜索
      // 实际项目中应使用 geolocator 包获取真实GPS坐标
      await _searchNearby(120.15, 30.28); // 默认杭州坐标
    } catch (e) {
      setState(() => _error = '定位失败: $e');
    } finally {
      setState(() => _locating = false);
    }
  }

  Future<void> _searchNearby(double lng, double lat) async {
    await context.read<PharmacyProvider>().searchNearby(
      lng: lng,
      lat: lat,
      radius: _radius,
      keyword: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : '药店',
    );
  }

  String _formatDistance(dynamic d) {
    final n = d is num ? d : num.tryParse('$d') ?? 0;
    return n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}km' : '${n.round()}m';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PharmacyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('附近药店'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _locate,
            tooltip: '重新定位',
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: '搜索药店',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onSubmitted: (_) => _locate(),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<int>(
                  initialValue: _radius,
                  onSelected: (v) {
                    setState(() => _radius = v);
                    _locate();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${_radius ~/ 1000}km', style: const TextStyle(fontSize: 14)),
                        const Icon(Icons.arrow_drop_down, size: 18),
                      ],
                    ),
                  ),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 1000, child: Text('1公里内')),
                    PopupMenuItem(value: 3000, child: Text('3公里内')),
                    PopupMenuItem(value: 5000, child: Text('5公里内')),
                    PopupMenuItem(value: 10000, child: Text('10公里内')),
                  ],
                ),
              ],
            ),
          ),

          // 结果列表
          Expanded(
            child: _locating || provider.loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_off, size: 48, color: AppColors.textSecondary),
                            const SizedBox(height: 12),
                            Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _locate, child: const Text('重试')),
                          ],
                        ),
                      )
                    : provider.pharmacies.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.local_pharmacy_outlined, size: 48, color: AppColors.textSecondary),
                                SizedBox(height: 12),
                                Text('附近没有找到药店', style: TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _locate,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: provider.pharmacies.length,
                              itemBuilder: (context, i) => _buildPharmacyCard(provider.pharmacies[i], i),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyCard(dynamic pharmacy, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 序号
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pharmacy['name'] ?? '',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          pharmacy['address'] ?? '',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (pharmacy['tel'] != null && pharmacy['tel'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 14, color: AppColors.primary),
                        const SizedBox(width: 2),
                        Text(
                          pharmacy['tel'] is List ? (pharmacy['tel'] as List).join(', ') : '${pharmacy['tel']}',
                          style: const TextStyle(color: AppColors.primary, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // 距离
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _formatDistance(pharmacy['distance'] ?? 0),
                style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}
