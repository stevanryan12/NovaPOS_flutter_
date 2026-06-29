import 'package:flutter/material.dart';
import 'package:pemograman_mobile_2/app_theme.dart';
import 'package:pemograman_mobile_2/shift_controller.dart';
import 'package:pemograman_mobile_2/penjualan_screen.dart';

class ShiftScreen extends StatefulWidget {
  @override
  _ShiftScreenState createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  final ShiftController _controller = ShiftController();
  Map<String, dynamic>? _activeShift;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkShift();
  }

  Future<void> _checkShift() async {
    setState(() => _isLoading = true);
    try {
      final shift = await _controller.checkActiveShift();
      setState(() {
        _activeShift = shift;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _bukaShift() {
    final _formKey = GlobalKey<FormState>();
    final _namaController = TextEditingController();
    final _modalController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Buka Kasir (Mulai Shift)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _namaController,
                  decoration: AppTheme.formInputDecoration(label: 'Nama Kasir'),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _modalController,
                  keyboardType: TextInputType.number,
                  decoration: AppTheme.formInputDecoration(label: 'Modal Awal Laci (Rp)'),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: AppTheme.primaryButton,
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  try {
                    await _controller.openShift(_namaController.text, double.tryParse(_modalController.text) ?? 0);
                    _checkShift();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shift Berhasil Dibuka!')));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Mulai Shift'),
            ),
          ],
        );
      },
    );
  }

  void _tutupShift() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Tutup Kasir', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        content: const Text('Apakah Anda yakin ingin menutup shift kasir ini dan melihat rekap pendapatan?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(context);
              try {
                final res = await _controller.closeShift(_activeShift!['id']);
                _checkShift();
                _showTutupShiftResult(res);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Tutup Shift'),
          ),
        ],
      ),
    );
  }

  void _showTutupShiftResult(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Rekap Penjualan Shift', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modal Awal Laci: Rp ${_activeShift!['modal_awal']}', style: const TextStyle(color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text('Total Penjualan Shift: Rp ${data['total_penjualan']}', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
            const Divider(),
            Text('Total Uang di Laci Sekarang: Rp ${data['total_uang_di_laci']}', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: AppTheme.primaryButton,
            onPressed: () => Navigator.pop(context),
            child: const Text('Oke'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Manajemen Shift Kasir', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold)))
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _activeShift == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.storefront_rounded, size: 80, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('Kasir Sedang Tutup', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          const SizedBox(height: 8),
                          const Text('Buka shift untuk mulai mencatat penjualan.', style: TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            style: AppTheme.primaryButton.copyWith(padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 32, vertical: 16))),
                            icon: const Icon(Icons.lock_open_rounded),
                            label: const Text('Buka Kasir Sekarang', style: TextStyle(fontSize: 16)),
                            onPressed: _bukaShift,
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.gold),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 60, color: AppTheme.success),
                                const SizedBox(height: 16),
                                const Text('Kasir Sedang Buka', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                const SizedBox(height: 16),
                                Text('Kasir Aktif: ${_activeShift!['nama_kasir']}', style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                                Text('Waktu Buka: ${_activeShift!['waktu_buka']}', style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            style: AppTheme.primaryButton.copyWith(padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 32, vertical: 16))),
                            icon: const Icon(Icons.point_of_sale_rounded),
                            label: const Text('Buka Layar Penjualan', style: TextStyle(fontSize: 16)),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => PenjualanScreen()));
                            },
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.error,
                              side: const BorderSide(color: AppTheme.error),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.lock_rounded),
                            label: const Text('Tutup Kasir & Rekap', style: TextStyle(fontSize: 16)),
                            onPressed: _tutupShift,
                          ),
                        ],
                      ),
              ),
            ),
    );
  }
}
