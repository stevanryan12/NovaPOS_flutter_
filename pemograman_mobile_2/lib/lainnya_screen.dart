import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pemograman_mobile_2/list_supplier.dart';
import 'package:pemograman_mobile_2/pelanggan_screen.dart';
import 'package:pemograman_mobile_2/kasbon_screen.dart';
import 'package:pemograman_mobile_2/shift_screen.dart';
import 'package:pemograman_mobile_2/analitik_screen.dart';
import 'package:pemograman_mobile_2/history_screen.dart';
import 'package:pemograman_mobile_2/sync_controller.dart';
import 'package:pemograman_mobile_2/signIn.dart';

class LainnyaScreen extends StatefulWidget {
  const LainnyaScreen({super.key});

  @override
  State<LainnyaScreen> createState() => _LainnyaScreenState();
}

class _LainnyaScreenState extends State<LainnyaScreen> {
  bool isSyncing = false;

  Future<void> runBackupSync() async {
    setState(() {
      isSyncing = true;
    });

    try {
      final result = await SyncController().synchronizeDataToCloud();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Sinkronisasi berhasil!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sinkronisasi gagal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<_LainnyaMenuItem> menuItems = [
      _LainnyaMenuItem(
        'Pemasok / Supplier',
        'Kelola data pemasok barang toko',
        Icons.storefront_rounded,
        const Color(0xFFEA580C),
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ListSupplierScreen()),
        ),
      ),
      _LainnyaMenuItem(
        'Pelanggan',
        'Kelola database pelanggan setia',
        Icons.groups_rounded,
        const Color(0xFF0284C7),
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PelangganScreen()),
        ),
      ),
      _LainnyaMenuItem(
        'Kasbon / Utang',
        'Catat utang & cicilan pelanggan',
        Icons.savings_outlined,
        const Color(0xFFDB2777),
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => KasbonScreen()),
        ),
      ),
      _LainnyaMenuItem(
        'Shift Kasir',
        'Buka / tutup modal laci kasir',
        Icons.lock_clock_rounded,
        const Color(0xFF64748B),
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ShiftScreen()),
        ),
      ),
      _LainnyaMenuItem(
        'Laporan Analitik',
        'Analisis omzet, untung & rugi',
        Icons.bar_chart_rounded,
        const Color(0xFF7C3AED),
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AnalitikScreen()),
        ),
      ),
      _LainnyaMenuItem(
        'Riwayat Transaksi',
        'Daftar nota transaksi penjualan',
        Icons.history_rounded,
        const Color(0xFF0D9488),
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HistoryScreen()),
        ),
      ),
      _LainnyaMenuItem(
        'Sinkronisasi Cloud',
        'Backup database SQLite ke server',
        Icons.cloud_upload_rounded,
        const Color(0xFF059669),
        runBackupSync,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Dark Slate Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 24,
                bottom: 24,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
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
                  Text(
                    'Menu Lainnya',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Akses fitur tambahan kasir & toko Anda',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            // Syncing indicator
            if (isSyncing)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(strokeWidth: 2),
                      SizedBox(width: 12),
                      Text('Sedang menyinkronkan data...'),
                    ],
                  ),
                ),
              ),

            // List of Menu Items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: menuItems.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, color: item.color, size: 24),
                      ),
                      title: Text(
                        item.title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item.subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF94A3B8),
                        size: 24,
                      ),
                      onTap: item.onTap,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Keluar dari aplikasi / logout
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const signIn()),
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  label: Text(
                    'Keluar dari Akun (Logout)',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 100), // bottom spacing for navigation bar
          ],
        ),
      ),
    );
  }
}

class _LainnyaMenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _LainnyaMenuItem(this.title, this.subtitle, this.icon, this.color, this.onTap);
}
