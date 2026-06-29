import 'package:flutter/material.dart';
import 'package:pemograman_mobile_2/app_theme.dart';
import 'package:pemograman_mobile_2/supplier_controller.dart';
import 'add_edit_supplier.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pemograman_mobile_2/penjualan_controller.dart';
import 'package:pemograman_mobile_2/add_edit_barang.dart';

class ListSupplierScreen extends StatefulWidget {
  @override
  _ListSupplierScreenState createState() => _ListSupplierScreenState();
}

class _ListSupplierScreenState extends State<ListSupplierScreen> {
  List<Map<String, dynamic>> supplier = [];
  List<Map<String, dynamic>> filteredSupplier = [];
  final SupplierController supplierController = SupplierController();
  final TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  double totalSales = 0.0;
  List<Map<String, dynamic>> recentTransactions = [];
  List<double> monthlySales = List.filled(12, 0);

  @override
  void initState() {
    super.initState();
    fetchSupplier();
    fetchDashboardMetrics();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchSupplier() async {
    try {
      final data = await supplierController.fetchSupplier();
      setState(() {
        supplier = data;
        filteredSupplier = data;
        isLoading = false;
      });
      if (searchController.text.isNotEmpty) {
        filterSearch(searchController.text);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showError(e.toString());
    }
  }

  Future<void> fetchDashboardMetrics() async {
    try {
      final List<Map<String, dynamic>> historyData = await PenjualanController().fetchHistory();
      double tempSales = 0.0;
      List<double> tempMonthlySales = List.filled(12, 0);

      for (var item in historyData) {
        final double harga = (item['harga'] ?? 0).toDouble();
        final double jumlah = (item['jumlah'] ?? 0).toDouble();
        final double subtotal = harga * jumlah;
        tempSales += subtotal;

        try {
          final String noNota = item['no_nota'] ?? '';
          if (noNota.contains('-')) {
            final parts = noNota.split('-');
            if (parts.length > 1) {
              final ts = int.tryParse(parts.last);
              if (ts != null) {
                final date = DateTime.fromMillisecondsSinceEpoch(ts);
                tempMonthlySales[date.month - 1] += subtotal;
              }
            }
          }
        } catch (_) {}
      }

      setState(() {
        totalSales = tempSales;
        recentTransactions = historyData;
        monthlySales = tempMonthlySales;
      });
    } catch (e) {
      print('Error fetching metrics for supplier screen: $e');
    }
  }

  void filterSearch(String query) {
    setState(() {
      filteredSupplier = supplier.where((item) {
        final nama = item['nama']?.toString().toLowerCase() ?? '';
        final idSup = item['id_sup']?.toString().toLowerCase() ?? '';
        final alamat = item['alamat']?.toString().toLowerCase() ?? '';
        return nama.contains(query.toLowerCase()) || 
               idSup.contains(query.toLowerCase()) || 
               alamat.contains(query.toLowerCase());
      }).toList();
    });
  }

  void deleteSupplier(String idSup) async {
    try {
      await supplierController.deleteSupplier(idSup);
      setState(() {
        supplier.removeWhere((item) => item['id_sup'].toString() == idSup);
        filteredSupplier.removeWhere((item) => item['id_sup'].toString() == idSup);
      });
    } catch (e) {
      showError(e.toString());
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}J';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String getSupplierLogoUrl(String supplierName) {
    final name = supplierName.toLowerCase();
    if (name.contains('indofood')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Indofood_CBP_logo.svg/200px-Indofood_CBP_logo.svg.png';
    }
    if (name.contains('tirta') || name.contains('aqua')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/30/Aqua_logo.svg/200px-Aqua_logo.svg.png';
    }
    return '';
  }

  String _formatMoney(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.gold,
        backgroundColor: AppTheme.surface,
        onRefresh: () async {
          await fetchSupplier();
          await fetchDashboardMetrics();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header + Stats ──
              _buildHeaderAndStats(),
              const SizedBox(height: 52), // Spacing for metrics overlay

              // ── Bar Chart ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statistik Penjualan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildSalesChart(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // ── Pemasok Utama Section ──
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Pemasok Utama',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── Supplier List ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold),
                          ),
                        ),
                      )
                    : filteredSupplier.isEmpty
                        ? SizedBox(height: 200, child: _buildEmptyState())
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 120),
                            itemCount: filteredSupplier.length,
                            itemBuilder: (context, index) {
                              final item = filteredSupplier[index];
                              return _buildSupplierCard(item);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOptionsSheet,
        elevation: 0,
        backgroundColor: Colors.transparent,
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF97316), Color(0xFFEA580C)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEA580C).withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 20),
              SizedBox(width: 6),
              Text(
                'Tambah Barang/Pemasok',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeaderAndStats() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Premium Dark Slate background header
        Container(
          height: 195,
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            bottom: 60,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F172A), // Slate 900
                Color(0xFF1E293B), // Slate 800
              ],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top line: Store Name & Hi Lonika + Avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'LONIKA_STORE',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Row(
                    children: [
                      const Text(
                        'Hi Lonika, ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        '✨',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.amberAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 1.5),
                        ),
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey,
                          backgroundImage: NetworkImage(
                            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=150',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Search Input Row (from mockup)
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: filterSearch,
                  style: const TextStyle(color: Color(0xFF1F2937), fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Cari produk, transaksi, dll.',
                    hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 18),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Stat Cards Overlay
        Positioned(
          left: 16,
          right: 16,
          bottom: -40, // push it down to overlap the white background
          child: Row(
            children: [
              // Hari Ini Penjualan
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.payments_rounded,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Hari Ini Penjualan',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Color(0xFF94A3B8),
                                  size: 11,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rp ${_formatMoney(totalSales.toInt())}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Total Transaksi
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.credit_card_rounded,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Transaksi',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Container(
                                  width: 11,
                                  height: 11,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF94A3B8),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'i',
                                    style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${recentTransactions.length} TRX',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '▲ 1.50%',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Color(0xFF22C55E),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSalesChart() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    final maxValue = monthlySales.isEmpty ? 1.0 : (monthlySales.reduce((a, b) => a > b ? a : b));
    final safeMax = maxValue == 0 ? 1.0 : maxValue;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Juta Rp',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              AppTheme.badge(text: DateTime.now().year.toString(), fontSize: 9),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 130,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: safeMax * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 6,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final index = group.x.toInt();
                      final monthName = (index >= 0 && index < months.length) ? months[index] : '';
                      final salesVal = (index >= 0 && index < monthlySales.length) ? monthlySales[index] : 0.0;
                      return BarTooltipItem(
                        '$monthName\nRp ${_formatNumber(salesVal.toInt())}',
                        const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= months.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            months[index],
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) {
                          return const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Text(
                              'Rp 0',
                              textAlign: TextAlign.right,
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            _formatNumber(value.toInt()),
                            textAlign: TextAlign.right,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: safeMax / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.surfaceBorder,
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(12, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: monthlySales[i],
                        width: 9,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xFF1E293B),
                            Color(0xFF0F172A),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierCard(Map<String, dynamic> item) {
    final logoUrl = getSupplierLogoUrl(item['nama'] ?? '');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: logoUrl.isNotEmpty
                ? Image.network(
                    logoUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => _buildInitialsLogo(item['nama'] ?? 'S'),
                  )
                : _buildInitialsLogo(item['nama'] ?? 'S'),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'ID: ${item['id_sup']}, ${item['nama']}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Actions on top right
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddEditSupplierScreen(data: item),
                              ),
                            );
                            if (result == true) {
                              fetchSupplier();
                            }
                          },
                          child: const Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => deleteSupplier(item['id_sup'].toString()),
                          child: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Contact : ${item['no_hp']}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Address : ${item['alamat']}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsLogo(String name) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(
          name.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_shipping_rounded, color: AppTheme.textMuted, size: 48),
          ),
          const SizedBox(height: 20),
          Text(
            supplier.isEmpty ? 'Belum ada data supplier' : 'Data supplier tidak ditemukan',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tambah supplier baru untuk memulai',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showAddOptionsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tambah Data Baru',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.slate800,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.goldMuted,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.inventory_2_rounded, color: AppTheme.gold),
                  ),
                  title: const Text(
                    'Tambah Barang Baru',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Input item, kategori, harga, dan stok awal'),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddEditBarangScreen()),
                    );
                    if (result == true) {
                      fetchSupplier();
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0F2FE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Color(0xFF0284C7)),
                  ),
                  title: const Text(
                    'Tambah Pemasok / Supplier Baru',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Input nama supplier, kontak, dan alamat'),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddEditSupplierScreen()),
                    );
                    if (result == true) {
                      fetchSupplier();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
