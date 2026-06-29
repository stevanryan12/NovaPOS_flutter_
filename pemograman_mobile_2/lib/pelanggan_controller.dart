import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pemograman_mobile_2/config.dart';

class PelangganController {
  static final String baseUrl = AppConfig.baseUrl;

  Future<List<Map<String, dynamic>>> fetchPelanggan() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/pelanggan'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => {
          'id': item['id'],
          'nama': item['nama'] ?? 'Tanpa Nama',
          'no_hp': item['no_hp'] ?? item['telepon'] ?? '',
          'poin': item['poin'] ?? 0,
          'total_utang': item['total_utang'] ?? 0,
        }).toList();
      } else {
        throw Exception('Failed to load pelanggan');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> addPelanggan(String nama, String noHp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pelanggan'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'nama': nama, 'no_hp': noHp, 'telepon': noHp}),
      );
      if (response.statusCode != 201) {
        throw Exception('Failed to add pelanggan');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> updatePelanggan(int id, String nama, String noHp) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/pelanggan/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'nama': nama, 'no_hp': noHp, 'telepon': noHp}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update pelanggan');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> deletePelanggan(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/pelanggan/$id'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete pelanggan');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> deductPoints(int id, int pointsDeducted) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/pelanggan/$id/potong-poin'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'poin_dipotong': pointsDeducted}),
      );
      if (response.statusCode != 200) {
        throw Exception('Gagal memotong poin pelanggan');
      }
    } catch (e) {
      throw Exception('Error memotong poin: $e');
    }
  }
}
