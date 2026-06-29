import 'package:flutter/material.dart';
import 'package:pemograman_mobile_2/app_theme.dart';
import 'package:pemograman_mobile_2/pelanggan_controller.dart';

class PelangganScreen extends StatefulWidget {
  @override
  _PelangganScreenState createState() => _PelangganScreenState();
}

class _PelangganScreenState extends State<PelangganScreen> {
  final PelangganController _controller = PelangganController();
  List<Map<String, dynamic>> _pelanggan = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _controller.fetchPelanggan();
      setState(() {
        _pelanggan = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showFormDialog({Map<String, dynamic>? data}) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _namaController = TextEditingController(text: data?['nama'] ?? '');
    final TextEditingController _noHpController = TextEditingController(text: data?['no_hp'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            data == null ? 'Tambah Pelanggan' : 'Edit Pelanggan',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _namaController,
                  decoration: AppTheme.formInputDecoration(label: 'Nama Pelanggan'),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noHpController,
                  keyboardType: TextInputType.phone,
                  decoration: AppTheme.formInputDecoration(label: 'No. HP / WhatsApp'),
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
                    if (data == null) {
                      await _controller.addPelanggan(_namaController.text, _noHpController.text);
                    } else {
                      await _controller.updatePelanggan(data['id'], _namaController.text, _noHpController.text);
                    }
                    _fetchData();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil disimpan!')));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _deletePelanggan(int id) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Hapus Pelanggan', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Yakin ingin menghapus data ini?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _controller.deletePelanggan(id);
                _fetchData();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil dihapus!')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Hapus'),
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
        title: const Text('Data Pelanggan', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.gold,
        onPressed: () => _showFormDialog(),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold)))
          : _pelanggan.isEmpty
              ? const Center(child: Text('Belum ada data pelanggan.', style: TextStyle(color: AppTheme.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pelanggan.length,
                  itemBuilder: (context, index) {
                    final item = _pelanggan[index];
                    return Card(
                      color: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.goldSubtle,
                          child: const Icon(Icons.person_rounded, color: AppTheme.gold),
                        ),
                        title: Text(item['nama'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('No HP: ${item['no_hp']?.toString() ?? '-'}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text('Poin: ${item['poin']}', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: AppTheme.info),
                              onPressed: () => _showFormDialog(data: item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_rounded, color: AppTheme.error),
                              onPressed: () => _deletePelanggan(item['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
