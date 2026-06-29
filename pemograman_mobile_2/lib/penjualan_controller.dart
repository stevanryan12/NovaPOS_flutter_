import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pemograman_mobile_2/config.dart';

class PenjualanController {
  static final String baseUrl = AppConfig.baseUrl;

  Future<Map<String, dynamic>?> fetchProductByBarcode(String barcode) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/barang/$barcode'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['data'] != null) {
          // Mengembalikan data barang
          return responseData['data'] as Map<String, dynamic>;
        } else {
          // Jika 'data' tidak ditemukan, return null
          return null;
        }
      } else {
        return null; // Barang tidak ditemukan
      }
    } catch (e) {
      throw Exception('Error fetching product: $e');
    }
  }

  static Future<void> saveTransaction(
    String noNota,
    List<Map<String, dynamic>> items, {
    double diskon = 0.0,
    double pajak = 0.0,
    int? idPelanggan,
  }) async {
    try {
      for (var item in items) {
        // Mengirim data ke API
        final response = await http.post(
          Uri.parse('$baseUrl/penjualan'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'no_nota': noNota,
            'no_barcode': item['no_barcode'],
            'jumlah': item['jumlah'],
            'diskon': diskon,
            'pajak': pajak,
            'id_pelanggan': idPelanggan,
          }),
        );

        if (response.statusCode != 201) {
          throw Exception(
            'Gagal menyimpan transaksi untuk item ${item['nama']}',
          );
        }
      }

      print("Transaksi dengan No Nota $noNota berhasil disimpan ke server!");
    } catch (e) {
      throw Exception("Gagal menyimpan transaksi: $e");
    }
  }

  Future<List<Map<String, dynamic>>> fetchHistory() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/penjualan'));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to load transaction history');
      }
    } catch (e) {
      throw Exception('Error fetching transaction history: $e');
    }
  }
}
