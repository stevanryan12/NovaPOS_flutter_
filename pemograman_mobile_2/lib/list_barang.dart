import 'package:flutter/material.dart';
import 'package:pemograman_mobile_2/app_theme.dart';
import 'package:pemograman_mobile_2/barang_controller.dart';

class ListBarangScreen extends StatefulWidget {
  @override
  _ListBarangScreenState createState() => _ListBarangScreenState();
}

class _ListBarangScreenState extends State<ListBarangScreen> {
  List<Map<String, dynamic>> barang = [];
  List<Map<String, dynamic>> filteredBarang = [];
  final BarangController barangController = BarangController();
  final TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBarang();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchBarang() async {
    try {
      final data = await barangController.fetchBarang();
      setState(() {
        barang = data;
        filteredBarang = data;
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

  void filterSearch(String query) {
    setState(() {
      filteredBarang = barang.where((item) {
        final nama = item['nama']?.toString().toLowerCase() ?? '';
        final barcode = item['no_barcode']?.toString().toLowerCase() ?? '';
        return nama.contains(query.toLowerCase()) || barcode.contains(query.toLowerCase());
      }).toList();
    });
  }

  void adjustStock(Map<String, dynamic> item, int amount, String mode) async {
    int currentStok = item['stok'] as int? ?? 0;
    int newStok = currentStok;

    if (mode == 'IN') {
      newStok = currentStok + amount;
    } else if (mode == 'OUT') {
      newStok = currentStok - amount;
      if (newStok < 0) newStok = 0;
    } else if (mode == 'OPNAME') {
      newStok = amount;
      if (newStok < 0) newStok = 0;
    }

    final data = {
      'no_barcode': item['no_barcode'],
      'nama': item['nama'],
      'harga': item['harga'],
      'stok': newStok,
      'kategori': item['kategori'] ?? 'Umum',
    };

    try {
      await BarangController.updateBarang(item['no_barcode'].toString(), data);
      fetchBarang();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stok ${item['nama']} berhasil diperbarui menjadi $newStok'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      showError('Gagal memperbarui stok: $e');
    }
  }

  void showAdjustDialog(Map<String, dynamic> item, String mode) {
    final TextEditingController inputController = TextEditingController();
    String title = '';
    String label = '';
    
    if (mode == 'IN') {
      title = 'Tambah Stok (Masuk)';
      label = 'Jumlah barang masuk';
    } else if (mode == 'OUT') {
      title = 'Kurang Stok (Keluar)';
      label = 'Jumlah barang keluar';
    } else if (mode == 'OPNAME') {
      title = 'Stok Opname';
      label = 'Setel jumlah stok baru';
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            title, 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Barang: ${item['nama']}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 10),
              TextField(
                controller: inputController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: AppTheme.formInputDecoration(label: label),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final text = inputController.text.trim();
                if (text.isNotEmpty) {
                  final amount = int.tryParse(text);
                  if (amount != null && amount >= 0) {
                    Navigator.pop(context);
                    adjustStock(item, amount, mode);
                  }
                }
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppTheme.error));
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
      body: Column(
        children: [
          // ── Header (Sleek Dark - Compact) ──
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 2,
              left: 10,
              right: 16,
              bottom: 8,
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
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 2),
                const Text(
                  'Inventori Stok',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: TextField(
              controller: searchController,
              onChanged: filterSearch,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: AppTheme.searchInputDecoration(hint: 'Cari barang untuk diubah stok...'),
            ),
          ),

          // ── List of Items ──
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold),
                    ),
                  )
                : filteredBarang.isEmpty
                    ? Center(
                        child: Text(
                          barang.isEmpty ? 'Belum ada data barang' : 'Data barang tidak ditemukan',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppTheme.gold,
                        backgroundColor: AppTheme.surface,
                        onRefresh: fetchBarang,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          itemCount: filteredBarang.length,
                          itemBuilder: (context, index) {
                            final item = filteredBarang[index];
                            final stok = item['stok'] ?? 0;
                            final name = item['nama'] ?? '';
                            final price = item['harga'] ?? 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey[100]!),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.01),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Product Info Row
                                  Row(
                                    children: [
                                      // Icon Box
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9), // Slate 100
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.inventory_2_rounded,
                                          color: Color(0xFF64748B), // Slate 500
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Name + Price
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name.toString().toLowerCase(),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Harga Jual Rp ${_formatMoney(price)}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Stock indicator badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFECFDF5),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Column(
                                          children: [
                                            const Text(
                                              'Stok',
                                              style: TextStyle(
                                                fontSize: 7,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF059669),
                                              ),
                                            ),
                                            Text(
                                              '$stok',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF059669),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Action buttons Row
                                  Row(
                                    children: [
                                      // Masuk (+)
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFF16A34A), // Green 600
                                            side: const BorderSide(color: Color(0xFF86EFAC), width: 0.8), // Green 300
                                            padding: const EdgeInsets.symmetric(vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          ),
                                          icon: const Icon(Icons.add_rounded, size: 12),
                                          label: const Text('Masuk (+)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                          onPressed: () => showAdjustDialog(item, 'IN'),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      // Keluar (-)
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFFDC2626), // Red 600
                                            side: const BorderSide(color: Color(0xFFFCA5A5), width: 0.8), // Red 300
                                            padding: const EdgeInsets.symmetric(vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          ),
                                          icon: const Icon(Icons.remove_rounded, size: 12),
                                          label: const Text('Keluar (-)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                          onPressed: () => showAdjustDialog(item, 'OUT'),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      // Opname
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFF4B5563),
                                            side: const BorderSide(color: Color(0xFFD1D5DB), width: 0.8),
                                            padding: const EdgeInsets.symmetric(vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          ),
                                          icon: const Icon(Icons.edit_note_rounded, size: 12),
                                          label: const Text('Opname', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                          onPressed: () => showAdjustDialog(item, 'OPNAME'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
