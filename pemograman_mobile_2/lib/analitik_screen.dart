import 'package:flutter/material.dart';
import 'package:pemograman_mobile_2/app_theme.dart';
import 'package:pemograman_mobile_2/analitik_controller.dart';
import 'package:pemograman_mobile_2/penjualan_controller.dart';

class AnalitikScreen extends StatefulWidget {
  @override
  _AnalitikScreenState createState() => _AnalitikScreenState();
}

class _AnalitikScreenState extends State<AnalitikScreen> {
  final AnalitikController _analitikController = AnalitikController();
  List<Map<String, dynamic>> _analitikList = [];
  bool _isLoading = true;
  double _totalOmzet = 0.0;
  double _totalLaba = 0.0;
  int _totalTx = 0;
  Map<String, double> _categorySales = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final list = await _analitikController.fetchAnalitikLabaRugi();
      double tempOmzet = 0.0;
      double tempLaba = 0.0;
      int tempTx = 0;

      for (var item in list) {
        tempOmzet += ((item['total_omzet'] ?? 0) as num).toDouble();
        tempLaba += ((item['laba_bersih'] ?? 0) as num).toDouble();
        tempTx += ((item['total_transaksi'] ?? 0) as num).toInt();
      }

      // Hitung kontribusi penjualan per kategori barang dari riwayat
      final historyList = await PenjualanController().fetchHistory();
      Map<String, double> tempCategorySales = {};
      for (var item in historyList) {
        final String category = item['kategori'] ?? 'Umum';
        final double harga = (item['harga'] ?? 0).toDouble();
        final double jumlah = (item['jumlah'] ?? 0).toDouble();
        tempCategorySales[category] = (tempCategorySales[category] ?? 0) + (harga * jumlah);
      }

      setState(() {
        _analitikList = list;
        _totalOmzet = tempOmzet;
        _totalLaba = tempLaba;
        _totalTx = tempTx;
        _categorySales = tempCategorySales;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat analitik: $e', style: const TextStyle(color: AppTheme.textPrimary)),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Analitik Laba/Rugi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.gold, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.gold, size: 22),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold)))
          : RefreshIndicator(
              color: AppTheme.gold,
              backgroundColor: AppTheme.surface,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTheme.sectionTitle('Rangkuman 30 Hari Terakhir'),
                    
                    // Metric Cards Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Total Omzet',
                            'Rp ${_formatMoney(_totalOmzet.toInt())}',
                            Icons.trending_up_rounded,
                            AppTheme.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Laba Bersih',
                            'Rp ${_formatMoney(_totalLaba.toInt())}',
                            Icons.monetization_on_rounded,
                            AppTheme.gold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildMetricCard(
                      'Total Transaksi Sukses',
                      '$_totalTx Transaksi',
                      Icons.shopping_bag_outlined,
                      AppTheme.info,
                      isFullWidth: true,
                    ),

                    const SizedBox(height: 28),
                    AppTheme.sectionTitle('Grafik Keuntungan Bersih'),
                    _buildChartCard(),

                    const SizedBox(height: 28),
                    AppTheme.sectionTitle('Penjualan Per Kategori'),
                    _buildCategoryChartCard(),

                    const SizedBox(height: 28),
                    AppTheme.sectionTitle('Rincian Harian'),
                    _analitikList.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(32),
                            decoration: AppTheme.cardDecoration,
                            child: const Center(
                              child: Text(
                                'Tidak ada data rincian harian',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _analitikList.length,
                            itemBuilder: (context, index) {
                              final item = _analitikList[index];
                              final date = item['tanggal']?.toString().substring(0, 10) ?? '';
                              final omzet = (item['total_omzet'] ?? 0).toDouble();
                              final laba = (item['laba_bersih'] ?? 0).toDouble();
                              final txCount = item['total_transaksi'] ?? 0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: AppTheme.cardDecoration,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            date,
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 14),
                                          ),
                                          AppTheme.badge(
                                            text: '$txCount Transaksi',
                                            color: AppTheme.info,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Divider(color: AppTheme.surfaceBorder, height: 1),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Omzet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                              const SizedBox(height: 4),
                                              Text('Rp ${_formatMoney(omzet.toInt())}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              const Text('Laba Bersih', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                              const SizedBox(height: 4),
                                              Text('Rp ${_formatMoney(laba.toInt())}', style: TextStyle(color: laba >= 0 ? AppTheme.success : AppTheme.error, fontWeight: FontWeight.bold, fontSize: 14)),
                                            ],
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, {bool isFullWidth = false}) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            AppTheme.iconContainer(icon: icon, color: color, size: 40, iconSize: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    if (_analitikList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.cardDecoration,
        child: const Center(
          child: Text('Data tidak cukup untuk grafik', style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    // Ambil maksimal 7 hari terakhir
    final chartData = _analitikList.reversed.take(7).toList();
    double maxLaba = 1.0;
    for (var d in chartData) {
      double l = (d['laba_bersih'] ?? 0).toDouble();
      if (l > maxLaba) maxLaba = l;
    }

    return Container(
      decoration: AppTheme.cardDecorationGold,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            SizedBox(
              height: 160,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: chartData.map((d) {
                  final double val = (d['laba_bersih'] ?? 0).toDouble();
                  final double pct = (val / maxLaba) * 100; // normalize height max 100
                  final date = d['tanggal']?.toString().substring(8, 10) ?? '';

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${_formatCompact(val.toInt())}',
                        style: TextStyle(
                          color: val >= 0 ? AppTheme.success : AppTheme.error,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 16,
                        height: pct.clamp(4.0, 100.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: const LinearGradient(
                            colors: [AppTheme.gold, AppTheme.goldLight],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.gold.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        date,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: AppTheme.surfaceBorder, height: 1),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline_rounded, color: AppTheme.gold, size: 14),
                const SizedBox(width: 6),
                const Text(
                  'Grafik keuntungan bersih 7 hari transaksi terakhir',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w500),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  String _formatMoney(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _formatCompact(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }

  Widget _buildCategoryChartCard() {
    if (_categorySales.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.cardDecoration,
        child: const Center(
          child: Text('Tidak ada data kategori', style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    // Urutkan kategori berdasarkan total penjualan terbesar
    final sortedCategories = _categorySales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    double maxCategorySales = sortedCategories.first.value;
    if (maxCategorySales <= 0) maxCategorySales = 1.0;

    final List<Color> barColors = [
      AppTheme.gold,
      const Color(0xFF0D9488),
      const Color(0xFF2563EB),
      const Color(0xFFEA580C),
      const Color(0xFFDB2777),
      const Color(0xFF7C3AED),
    ];

    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sortedCategories.asMap().entries.map((entry) {
          final index = entry.key;
          final cat = entry.value.key;
          final val = entry.value.value;
          final percentage = (val / maxCategorySales);
          final color = barColors[index % barColors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cat,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Rp ${_formatMoney(val.toInt())}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Stack(
                  children: [
                    // Background bar
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Foreground progress bar
                    FractionallySizedBox(
                      widthFactor: percentage.clamp(0.01, 1.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
