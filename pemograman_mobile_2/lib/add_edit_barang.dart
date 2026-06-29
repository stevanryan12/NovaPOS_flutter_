import 'package:flutter/material.dart';
import 'package:pemograman_mobile_2/app_theme.dart';
import 'package:pemograman_mobile_2/barang_controller.dart';
import 'package:pemograman_mobile_2/widget/button.dart';
import 'package:pemograman_mobile_2/widget/textField.dart';

class AddEditBarangScreen extends StatefulWidget {
  final Map<String, dynamic>? data;

  AddEditBarangScreen({this.data});

  @override
  _AddEditBarangScreenState createState() => _AddEditBarangScreenState();
}

class _AddEditBarangScreenState extends State<AddEditBarangScreen> {
  final TextEditingController noBarcodeController = TextEditingController();
  final TextEditingController namaController = TextEditingController();
  final TextEditingController hargaModalController = TextEditingController();
  final TextEditingController hargaController = TextEditingController();
  final TextEditingController stokController = TextEditingController();

  final BarangController barangController = BarangController();
  bool isLoading = false;
  
  List<String> categories = ['Umum'];
  String selectedCategory = 'Umum';

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      noBarcodeController.text = widget.data!['no_barcode'].toString();
      namaController.text = widget.data!['nama'];
      hargaModalController.text = (widget.data!['harga_modal'] ?? 0).toString();
      hargaController.text = widget.data!['harga'].toString();
      stokController.text = widget.data!['stok'].toString();
      selectedCategory = widget.data!['kategori']?.toString() ?? 'Umum';
    }
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      final list = await barangController.fetchCategories();
      setState(() {
        categories = list.toSet().toList();
        if (!categories.contains(selectedCategory)) {
          categories.add(selectedCategory);
        }
        if (!categories.contains('Umum')) {
          categories.insert(0, 'Umum');
        }
      });
    } catch (e) {
      print('Gagal memuat kategori: $e');
    }
  }

  void showAddCategoryDialog() {
    final TextEditingController newCatController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          side: const BorderSide(color: AppTheme.surfaceBorder),
        ),
        title: const Text(
          'Tambah Kategori Baru',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: newCatController,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: AppTheme.searchInputDecoration(hint: 'Nama kategori baru...'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {}); // refresh dropdown
            },
            child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: AppTheme.primaryButton.copyWith(
              padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
            ),
            onPressed: () {
              final newCat = newCatController.text.trim();
              if (newCat.isNotEmpty) {
                setState(() {
                  if (!categories.contains(newCat)) {
                    categories.add(newCat);
                  }
                  selectedCategory = newCat;
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  Future<void> saveData() async {
    setState(() {
      isLoading = true;
    });

    final data = {
      'no_barcode': noBarcodeController.text,
      'nama': namaController.text,
      'harga_modal': int.tryParse(hargaModalController.text) ?? 0,
      'harga': int.tryParse(hargaController.text) ?? 0,
      'stok': int.tryParse(stokController.text) ?? 0,
      'kategori': selectedCategory,
    };

    try {
      if (widget.data == null) {
        await BarangController.addBarang(data);
      } else {
        await BarangController.updateBarang(noBarcodeController.text, data);
      }
      Navigator.pop(context, true);
    } catch (e) {
      showError('Terjadi kesalahan: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          side: const BorderSide(color: AppTheme.surfaceBorder),
        ),
        title: const Text(
          'Error',
          style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: const TextStyle(color: AppTheme.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppTheme.gold)),
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
        title: Text(widget.data == null ? 'Tambah Barang' : 'Edit Barang'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.gold, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Container(
          decoration: AppTheme.cardDecoration,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                    controller: noBarcodeController,
                    label: 'No Barcode',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'No Barcode tidak boleh kosong';
                      }
                      return null;
                    },
                    readOnly: widget.data != null,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: namaController,
                    label: 'Nama Barang',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama Barang tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: hargaModalController,
                    label: 'Harga Modal (Beli)',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Harga modal tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: hargaController,
                    label: 'Harga Jual',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Harga tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: stokController,
                    label: 'Stok',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Stok tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: DropdownButtonFormField<String>(
                      value: selectedCategory,
                      dropdownColor: AppTheme.surfaceLight,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: AppTheme.formInputDecoration(label: 'Kategori'),
                      items: [
                        ...categories.map((cat) => DropdownMenuItem<String>(
                              value: cat,
                              child: Text(cat),
                            )),
                        const DropdownMenuItem<String>(
                          value: '__ADD_NEW__',
                          child: Text(
                            '+ Tambah Kategori Baru',
                            style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == '__ADD_NEW__') {
                          showAddCategoryDialog();
                        } else if (value != null) {
                          setState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold),
                          ),
                        )
                      : CustomButton(label: 'Simpan', onPressed: saveData),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
