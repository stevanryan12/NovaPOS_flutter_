import 'package:flutter/material.dart';
import 'package:pemograman_mobile_2/app_theme.dart';
import 'package:pemograman_mobile_2/kasbon_controller.dart';

class KasbonScreen extends StatefulWidget {
  @override
  _KasbonScreenState createState() => _KasbonScreenState();
}

class _KasbonScreenState extends State<KasbonScreen> {
  final KasbonController _kasbonController = KasbonController();
  List<Map<String, dynamic>> _pelangganList = [];
  List<Map<String, dynamic>> _filteredPelangganList = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPelanggan();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPelanggan() async {
    setState(() => _isLoading = true);
    try {
      final list = await _kasbonController.fetchPelanggan();
      setState(() {
        _pelangganList = list;
        _filteredPelangganList = list;
        _isLoading = false;
      });
      if (_searchController.text.isNotEmpty) {
        _filterPelanggan(_searchController.text);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Gagal memuat data: $e');
    }
  }

  void _filterPelanggan(String query) {
    setState(() {
      _filteredPelangganList = _pelangganList.where((item) {
        final nama = item['nama']?.toString().toLowerCase() ?? '';
        final telp = item['telepon']?.toString().toLowerCase() ?? '';
        return nama.contains(query.toLowerCase()) || telp.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.surfaceLight,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _dialogAddPelanggan() {
    final nameCtrl = TextEditingController();
    final telpCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          side: const BorderSide(color: AppTheme.surfaceBorder),
        ),
        title: const Text(
          'Tambah Pelanggan Baru',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: AppTheme.formInputDecoration(label: 'Nama Pelanggan'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: telpCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: AppTheme.formInputDecoration(label: 'No Telepon'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: AppTheme.primaryButton.copyWith(
              padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            ),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) {
                _showSnackBar('Nama tidak boleh kosong');
                return;
              }
              try {
                await KasbonController.addPelanggan({
                  'nama': nameCtrl.text.trim(),
                  'telepon': telpCtrl.text.trim(),
                });
                Navigator.pop(ctx);
                _showSnackBar('Pelanggan berhasil ditambahkan');
                _loadPelanggan();
              } catch (e) {
                _showSnackBar('Gagal: $e');
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDetailPelanggan(Map<String, dynamic> pelanggan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: AppTheme.surfaceBorder, width: 1.5),
              ),
              child: _PelangganDetailWidget(
                pelanggan: pelanggan,
                controller: _kasbonController,
                scrollController: scrollController,
                onTransactionAdded: () {
                  _loadPelanggan();
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Sistem Kasbon'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.gold, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterPelanggan,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                    decoration: AppTheme.searchInputDecoration(hint: 'Cari pelanggan...'),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _dialogAddPelanggan,
                  borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.gold,
                      borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                      boxShadow: AppTheme.glowShadow,
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded, size: 22, color: AppTheme.background),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppTheme.gold),
                    ),
                  )
                : _filteredPelangganList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline_rounded, color: AppTheme.textMuted, size: 48),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum ada pelanggan kasbon',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredPelangganList.length,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemBuilder: (ctx, idx) {
                          final p = _filteredPelangganList[idx];
                          final utang = p['total_utang'] ?? 0;
                          final isLunas = utang <= 0;
                          final String initial = p['nama'] != null && p['nama'].toString().isNotEmpty
                              ? p['nama'].toString().substring(0, 1).toUpperCase()
                              : 'P';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: AppTheme.cardDecoration,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.goldMuted, AppTheme.goldSubtle],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.goldMuted, width: 1),
                                ),
                                child: Center(
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      color: AppTheme.gold,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                p['nama'] ?? '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  p['telepon'] ?? 'Tidak ada nomor telepon',
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Rp $utang',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isLunas ? AppTheme.success : AppTheme.error,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  AppTheme.badge(
                                    text: isLunas ? 'Lunas' : 'Belum Lunas',
                                    color: isLunas ? AppTheme.success : AppTheme.error,
                                  ),
                                ],
                              ),
                              onTap: () => _showDetailPelanggan(p),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _PelangganDetailWidget extends StatefulWidget {
  final Map<String, dynamic> pelanggan;
  final KasbonController controller;
  final ScrollController scrollController;
  final VoidCallback onTransactionAdded;

  const _PelangganDetailWidget({
    required this.pelanggan,
    required this.controller,
    required this.scrollController,
    required this.onTransactionAdded,
  });

  @override
  __PelangganDetailWidgetState createState() => __PelangganDetailWidgetState();
}

class __PelangganDetailWidgetState extends State<_PelangganDetailWidget> {
  List<Map<String, dynamic>> _riwayat = [];
  bool _isLoading = true;
  late int _totalUtang;

  @override
  void initState() {
    super.initState();
    _totalUtang = widget.pelanggan['total_utang'] ?? 0;
    _fetchRiwayat();
  }

  Future<void> _fetchRiwayat() async {
    setState(() => _isLoading = true);
    try {
      final data = await widget.controller.fetchRiwayatUtang(widget.pelanggan['id']);
      setState(() {
        _riwayat = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _dialogTambahTransaksi(String tipe) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          side: const BorderSide(color: AppTheme.surfaceBorder),
        ),
        title: Text(
          tipe == 'utang' ? 'Tambah Utang Baru' : 'Bayar Cicilan',
          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: AppTheme.formInputDecoration(label: 'Jumlah (Rp)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: AppTheme.formInputDecoration(label: 'Keterangan / Catatan'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: AppTheme.primaryButton.copyWith(
              backgroundColor: MaterialStateProperty.all(tipe == 'utang' ? AppTheme.error : AppTheme.success),
              foregroundColor: MaterialStateProperty.all(AppTheme.background),
              padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            ),
            onPressed: () async {
              final amount = int.tryParse(amountCtrl.text.trim()) ?? 0;
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Jumlah harus lebih dari 0', style: TextStyle(color: AppTheme.textPrimary)),
                    backgroundColor: AppTheme.error,
                  ),
                );
                return;
              }
              try {
                final response = await KasbonController.addTransaksiKasbon({
                  'id_pelanggan': widget.pelanggan['id'],
                  'tipe': tipe,
                  'jumlah': amount,
                  'keterangan': noteCtrl.text.trim(),
                });
                Navigator.pop(ctx);
                setState(() {
                  if (response['pelanggan'] != null) {
                    _totalUtang = response['pelanggan']['total_utang'] ?? 0;
                  } else {
                    _totalUtang = tipe == 'utang' ? _totalUtang + amount : _totalUtang - amount;
                  }
                });
                widget.onTransactionAdded();
                _fetchRiwayat();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal: $e', style: const TextStyle(color: AppTheme.textPrimary)),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
            },
            child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLunas = _totalUtang <= 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.surfaceBorder,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.pelanggan['nama'] ?? '',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Telp: ${widget.pelanggan['telepon'] ?? '-'}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rp $_totalUtang',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isLunas ? AppTheme.success : AppTheme.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AppTheme.badge(
                    text: isLunas ? 'Lunas' : 'Belum Lunas',
                    color: isLunas ? AppTheme.success : AppTheme.error,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _dialogTambahTransaksi('utang'),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.errorBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.error.withOpacity(0.3), width: 1),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline_rounded, size: 18, color: AppTheme.error),
                        SizedBox(width: 8),
                        Text(
                          'Utang Baru',
                          style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _dialogTambahTransaksi('cicilan'),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.successBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.success.withOpacity(0.3), width: 1),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payment_rounded, size: 18, color: AppTheme.success),
                        SizedBox(width: 8),
                        Text(
                          'Bayar Cicilan',
                          style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          AppTheme.sectionTitle('Riwayat Transaksi Kasbon'),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppTheme.gold)))
                : _riwayat.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded, color: AppTheme.textMuted, size: 36),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada riwayat transaksi kasbon',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: widget.scrollController,
                        itemCount: _riwayat.length,
                        itemBuilder: (ctx, idx) {
                          final tx = _riwayat[idx];
                          final isUtang = tx['tipe'] == 'utang';
                          final dateStr = tx['tanggal']?.toString().substring(0, 10) ?? '';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: AppTheme.cardDecoration,
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isUtang ? AppTheme.errorBg : AppTheme.successBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isUtang ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                  color: isUtang ? AppTheme.error : AppTheme.success,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                isUtang ? 'Utang Baru' : 'Bayar Cicilan',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 14),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (tx['keterangan'] != null && tx['keterangan'].toString().trim().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 2),
                                        child: Text(
                                          'Catatan: ${tx['keterangan']}',
                                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                        ),
                                      ),
                                    Text(dateStr, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                                  ],
                                ),
                              ),
                              trailing: Text(
                                '${isUtang ? "+" : "-"} Rp ${tx['jumlah']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isUtang ? AppTheme.error : AppTheme.success,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
