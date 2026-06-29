import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pemograman_mobile_2/config.dart';

class KasbonController {
  static final String baseUrl = AppConfig.baseUrl;

  // Mendapatkan daftar pelanggan kasbon
  Future<List<Map<String, dynamic>>> fetchPelanggan() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/pelanggan'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Gagal memuat data pelanggan');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Menambah pelanggan kasbon baru
  static Future<Map<String, dynamic>> addPelanggan(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pelanggan'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Gagal menambahkan pelanggan');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Mendapatkan riwayat transaksi utang/cicilan berdasarkan id pelanggan
  Future<List<Map<String, dynamic>>> fetchRiwayatUtang(int idPelanggan) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/kasbon/$idPelanggan'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Gagal memuat riwayat utang');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Menambah transaksi kasbon (utang baru atau cicilan/pembayaran)
  static Future<Map<String, dynamic>> addTransaksiKasbon(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/kasbon'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Gagal menambahkan transaksi kasbon');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
