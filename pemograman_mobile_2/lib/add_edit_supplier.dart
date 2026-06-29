import 'package:flutter/material.dart';
import 'package:pemograman_mobile_2/app_theme.dart';
import 'package:pemograman_mobile_2/supplier_controller.dart';
import 'package:pemograman_mobile_2/widget/button.dart';
import 'package:pemograman_mobile_2/widget/textField.dart';
 
class AddEditSupplierScreen extends StatefulWidget {
  final Map<String, dynamic>? data;

  AddEditSupplierScreen({this.data});

  @override
  _AddEditSupplierScreenState createState() => _AddEditSupplierScreenState();
}

class _AddEditSupplierScreenState extends State<AddEditSupplierScreen> {
  final TextEditingController idSupController = TextEditingController();
  final TextEditingController namaController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();
  final TextEditingController nohpController = TextEditingController();

  final SupplierController supplierController = SupplierController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      idSupController.text = widget.data!['id_sup'].toString();
      namaController.text = widget.data!['nama'];
      alamatController.text = widget.data!['alamat'];
      nohpController.text = widget.data!['no_hp'];
    }
  }

  Future<void> saveData() async {
    setState(() {
      isLoading = true;
    });

    final data = {
      'id_sup': idSupController.text,
      'nama': namaController.text,
      'alamat': alamatController.text,
      'no_hp': nohpController.text,
    };

    try {
      if (widget.data == null) {
        await SupplierController.addSupplier(data);
      } else {
        await SupplierController.updateSupplier(idSupController.text, data);
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
        title: Text(widget.data == null ? 'Tambah Supplier' : 'Edit Supplier'),
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
                    controller: idSupController,
                    label: 'Id Supplier',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Id Supplier tidak boleh kosong';
                      }
                      return null;
                    },
                    readOnly: widget.data != null,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: namaController,
                    label: 'Nama Supplier',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama Supplier tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: alamatController,
                    label: 'Alamat Supplier',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Alamat Supplier tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: nohpController,
                    label: 'No HP Supplier',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nomor tidak boleh kosong';
                      }
                      return null;
                    },
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
