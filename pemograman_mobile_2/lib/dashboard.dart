import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pemograman_mobile_2/app_theme.dart';
import 'package:pemograman_mobile_2/barang_controller.dart';
import 'package:pemograman_mobile_2/penjualan_controller.dart';
import 'package:pemograman_mobile_2/kasbon_screen.dart';
import 'package:pemograman_mobile_2/analitik_screen.dart';
import 'package:pemograman_mobile_2/sync_controller.dart';
import 'package:pemograman_mobile_2/penjualan_screen.dart';
import 'package:pemograman_mobile_2/list_barang_kategori.dart';
import 'package:pemograman_mobile_2/list_barang.dart';
import 'package:pemograman_mobile_2/history_screen.dart';
import 'package:pemograman_mobile_2/add_edit_barang.dart';
import 'package:pemograman_mobile_2/add_edit_supplier.dart';
import 'package:pemograman_mobile_2/pelanggan_screen.dart';
import 'package:pemograman_mobile_2/shift_screen.dart';
import 'package:pemograman_mobile_2/shift_controller.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ══════════════════════════════════════════════════════════════════
  // ALL BUSINESS LOGIC PRESERVED EXACTLY AS-IS
  // ══════════════════════════════════════════════════════════════════
  final BarangController barangController = BarangController();
  final PenjualanController penjualanController = PenjualanController();

  double totalSales = 0.0;
  int totalStock = 0;
  String topProduct = 'Belum ada data';
  int lowStockCount = 0;
  bool isLoading = true;
  bool isSyncing = false;

  // Monthly sales data for chart
  List<double> monthlySales = List.filled(12, 0);
  List<Map<String, dynamic>> recentTransactions = [];

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      final List<Map<String, dynamic>> barangData = await barangController.fetchBarang();
      final List<Map<String, dynamic>> historyData = await penjualanController.fetchHistory();

      // Calculate total stock
      int tempStock = 0;
      int tempLowStock = 0;
      for (var item in barangData) {
        final stok = (item['stok'] ?? 0) as int;
        tempStock += stok;
        if (stok <= 5) tempLowStock++;
      }

      // Calculate total sales and top selling product
      double tempSales = 0.0;
      Map<String, int> productSoldQty = {};
      List<double> tempMonthlySales = List.filled(12, 0);

      for (var item in historyData) {
        final double harga = (item['harga'] ?? 0).toDouble();
        final double jumlah = (item['jumlah'] ?? 0).toDouble();
        final double subtotal = harga * jumlah;
        tempSales += subtotal;

        final String name = item['nama'] ?? '';
        final int qty = (item['jumlah'] ?? 0).toInt();
        if (name.isNotEmpty) {
          productSoldQty[name] = (productSoldQty[name] ?? 0) + qty;
        }

        // Parse month for chart
        try {
          if (item['tanggal'] != null) {
            final date = DateTime.parse(item['tanggal'].toString());
            tempMonthlySales[date.month - 1] += subtotal;
          } else {
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
          }
        } catch (_) {}
      }

      String tempTopProd = 'Belum ada data';
      int maxQty = 0;
      productSoldQty.forEach((name, qty) {
        if (qty > maxQty) {
          maxQty = qty;
          tempTopProd = name;
        }
      });

      // Get recent transactions (newest 5)
      List<Map<String, dynamic>> tempRecent = [];
      if (historyData.isNotEmpty) {
        tempRecent = historyData.length > 5
            ? historyData.sublist(0, 5)
            : historyData;
      }

      setState(() {
        totalStock = tempStock;
        totalSales = tempSales;
        topProduct = tempTopProd;
        lowStockCount = tempLowStock;
        monthlySales = tempMonthlySales;
        recentTransactions = tempRecent;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading dashboard: $e')),
      );
    }
  }

  Future<void> runBackupSync() async {
    setState(() {
      isSyncing = true;
    });

    try {
      final result = await SyncController().synchronizeDataToCloud();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Sinkronisasi berhasil!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      setState(() {
        isSyncing = false;
      });
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // REDESIGNED UI — BUILD METHOD
  // ══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Memuat data...',
                    style: GoogleFonts.inter(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: AppTheme.gold,
              backgroundColor: AppTheme.surface,
              onRefresh: fetchDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Premium Header ──
                    _buildHeader(),

                    // ── Stat Cards (below header) ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: _buildStatCards(),
                    ),

                    // ── Quick Add Button ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: _buildQuickAddButton(),
                    ),

                    // ── Menu Utama Grid ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                      child: _buildMenuUtama(),
                    ),

                    // ── Sales Chart ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTheme.sectionTitle('Statistik Penjualan'),
                          _buildSalesChart(),
                        ],
                      ),
                    ),

                    // ── Recent Activity ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTheme.sectionTitle('Aktivitas Terkini'),
                          _buildRecentActivity(),
                        ],
                      ),
                    ),

                    // ── Sync Card ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                      child: _buildSyncCard(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // BOTTOM SHEET — PRESERVED EXACTLY AS-IS (LOGIC)
  // ══════════════════════════════════════════════════════════════════

  void _showAddOptionsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Tambah Data Baru',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pilih jenis data yang ingin ditambahkan',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                // Option 1: Tambah Barang
                _buildSheetOption(
                  icon: Icons.inventory_2_rounded,
                  iconColor: AppTheme.gold,
                  iconBgColor: AppTheme.goldMuted,
                  title: 'Tambah Barang Baru',
                  subtitle: 'Input item, kategori, harga, dan stok awal',
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddEditBarangScreen()),
                    );
                    if (result == true) {
                      fetchDashboardData();
                    }
                  },
                ),
                const SizedBox(height: 12),
                // Option 2: Tambah Supplier
                _buildSheetOption(
                  icon: Icons.storefront_rounded,
                  iconColor: AppTheme.accent,
                  iconBgColor: AppTheme.accentMuted,
                  title: 'Tambah Pemasok / Supplier Baru',
                  subtitle: 'Input nama supplier, kontak, dan alamat',
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddEditSupplierScreen()),
                    );
                    if (result == true) {
                      fetchDashboardData();
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetOption({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // REDESIGNED UI COMPONENTS
  // ══════════════════════════════════════════════════════════════════

  // ── Premium Header ──
  Widget _buildHeader() {
    final now = DateTime.now();
    final dayNames = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final monthNames = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    final formattedDate = "${dayNames[now.weekday % 7]}, ${now.day} ${monthNames[now.month - 1]} ${now.year}";

    // Time-aware greeting
    String greeting;
    if (now.hour < 12) {
      greeting = 'Selamat Pagi';
    } else if (now.hour < 17) {
      greeting = 'Selamat Siang';
    } else {
      greeting = 'Selamat Malam';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 28,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF064E3B), // Emerald 900
            Color(0xFF065F46), // Emerald 800
            Color(0xFF047857), // Emerald 700
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Greeting + Avatar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting 👋',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'LONIKA_STORE',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.goldLight,
                  child: Text(
                    'L',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Date & Status Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stat Cards ──
  Widget _buildStatCards() {
    return Row(
      children: [
        // Sales Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.cardShadow,
              border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF10B981)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.payments_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Total Penjualan',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Rp ${_formatMoney(totalSales.toInt())}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.successBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '▲ 1.50%',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: AppTheme.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Transaction Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.cardShadow,
              border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Total Transaksi',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${recentTransactions.length} TRX',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 12, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Stok: $totalStock',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Quick Add Button ──
  Widget _buildQuickAddButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showAddOptionsSheet,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF059669), Color(0xFF0D9488)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF059669).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Tambah Barang / Pemasok',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Menu Utama Grid ──
  Widget _buildMenuUtama() {
    final menuItems = [
      _MenuItemData('Kasir POS', Icons.point_of_sale_rounded, const Color(0xFF059669), () async {
        final shift = await ShiftController().checkActiveShift();
        if (shift == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Buka shift kasir terlebih dahulu!')),
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ShiftScreen()),
          ).then((_) => fetchDashboardData());
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PenjualanScreen()),
          ).then((_) => fetchDashboardData());
        }
      }),
      _MenuItemData('Produk', Icons.shopping_bag_outlined, const Color(0xFF2563EB), () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ListBarangKategoriScreen()),
        ).then((_) => fetchDashboardData());
      }),
      _MenuItemData('Stok', Icons.inventory_2_outlined, const Color(0xFF7C3AED), () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ListBarangScreen()),
        ).then((_) => fetchDashboardData());
      }),
      _MenuItemData('Riwayat', Icons.history_rounded, const Color(0xFF0D9488), () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HistoryScreen()),
        ).then((_) => fetchDashboardData());
      }),
      _MenuItemData('Laporan', Icons.bar_chart_rounded, const Color(0xFFEA580C), () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AnalitikScreen()),
        ).then((_) => fetchDashboardData());
      }),
      _MenuItemData('Kasbon', Icons.savings_outlined, const Color(0xFFDB2777), () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => KasbonScreen()),
        ).then((_) => fetchDashboardData());
      }),
      _MenuItemData('Pelanggan', Icons.groups_rounded, const Color(0xFF0284C7), () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PelangganScreen()),
        ).then((_) => fetchDashboardData());
      }),
      _MenuItemData('Shift Kasir', Icons.lock_clock_rounded, const Color(0xFF64748B), () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ShiftScreen()),
        ).then((_) => fetchDashboardData());
      }),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTheme.sectionTitle('Menu Utama'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: menuItems.length,
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return _buildMenuItem(
              title: item.title,
              icon: item.icon,
              color: item.color,
              onTap: item.onTap,
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Sales Chart ──
  Widget _buildSalesChart() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    final maxValue = monthlySales.isEmpty ? 1.0 : (monthlySales.reduce((a, b) => a > b ? a : b));
    final safeMax = maxValue == 0 ? 1.0 : maxValue;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.goldMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.trending_up_rounded, color: AppTheme.gold, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Penjualan Bulanan',
                      style: GoogleFonts.inter(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                AppTheme.badge(text: DateTime.now().year.toString(), fontSize: 10),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: safeMax * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 10,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final index = group.x.toInt();
                      final monthName = (index >= 0 && index < months.length) ? months[index] : '';
                      final salesVal = (index >= 0 && index < monthlySales.length) ? monthlySales[index] : 0.0;
                      return BarTooltipItem(
                        '$monthName\nRp ${_formatNumber(salesVal.toInt())}',
                        GoogleFonts.inter(
                          color: AppTheme.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
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
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= months.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            months[index],
                            style: GoogleFonts.inter(
                              color: AppTheme.textMuted,
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
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              'Rp 0',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 8, fontWeight: FontWeight.w600),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            _formatNumber(value.toInt()),
                            textAlign: TextAlign.right,
                            style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 8, fontWeight: FontWeight.w600),
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
                    color: AppTheme.surfaceBorder.withOpacity(0.5),
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
                        width: 10,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xFF10B981), // Emerald 500
                            Color(0xFF059669), // Emerald 600
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

  // ── Recent Activity ──
  Widget _buildRecentActivity() {
    if (recentTransactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: AppTheme.cardDecoration,
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: AppTheme.textMuted, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                'Belum ada transaksi',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Transaksi terbaru akan muncul di sini',
                style: GoogleFonts.inter(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: AppTheme.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: recentTransactions.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == recentTransactions.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.successBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt_rounded, color: AppTheme.success, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['nama'] ?? 'Produk',
                            style: GoogleFonts.inter(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Qty: ${item['jumlah'] ?? 0}',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rp ${_formatMoney(((item['harga'] ?? 0) * (item['jumlah'] ?? 0)).toInt())}',
                      style: GoogleFonts.inter(
                        color: AppTheme.gold,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  color: AppTheme.surfaceBorder.withOpacity(0.5),
                  indent: 68,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Sync Card ──
  Widget _buildSyncCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isSyncing ? null : runBackupSync,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.accent.withOpacity(0.05),
                AppTheme.accent.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppTheme.accent.withOpacity(0.15), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.accentMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isSyncing
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
                        ),
                      )
                    : const Icon(Icons.cloud_upload_rounded, color: AppTheme.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backup & Sync Cloud',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Ekspor data lokal (SQLite) ke MySQL Cloud',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_forward_rounded, color: AppTheme.accent, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // HELPERS — PRESERVED EXACTLY AS-IS
  // ══════════════════════════════════════════════════════════════════

  String _formatMoney(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}J';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

// ── Helper class for menu items (UI only, no logic) ──
class _MenuItemData {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _MenuItemData(this.title, this.icon, this.color, this.onTap);
}
