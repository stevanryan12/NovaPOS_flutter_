import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pemograman_mobile_2/local_db_helper.dart';
import 'package:pemograman_mobile_2/config.dart';

class SyncController {
  static final String baseUrl = AppConfig.baseUrl;
  final LocalDbHelper _dbHelper = LocalDbHelper();

  // Melakukan backup / sinkronisasi data lokal SQLite ke Cloud Server
  Future<Map<String, dynamic>> synchronizeDataToCloud() async {
    if (kIsWeb) {
      return {
        'status': 'success',
        'message': 'Sinkronisasi berhasil (Platform Web terhubung langsung ke database cloud).',
        'synced_at': DateTime.now().toIso8601String()
      };
    }
    try {
      // 1. Ambil data barang dari SQLite lokal
      final List<Map<String, dynamic>> localBarang = await _dbHelper.fetchBarangLocal();

      // 2. Ambil data pelanggan dari SQLite lokal
      final List<Map<String, dynamic>> localPelanggan = await _dbHelper.fetchPelangganLocal();

      // 3. Susun data payload backup
      final Map<String, dynamic> payload = {
        'device_id': 'mobile_pos_device_01',
        'timestamp': DateTime.now().toIso8601String(),
        'tables': {
          'barang': localBarang,
          'pelanggan': localPelanggan,
        }
      };

      // 4. Kirim ke REST API Server (Cloud Sync)
      final response = await http.post(
        Uri.parse('$baseUrl/backup/sync'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body) as Map<String, dynamic>;
        // Bersihkan antrean sinkronisasi jika sinkronisasi sukses penuh
        await _dbHelper.clearSyncQueue();
        return {
          'status': 'success',
          'message': result['message'] ?? 'Sinkronisasi cloud berhasil.',
          'synced_at': result['synced_at']
        };
      } else {
        throw Exception('Server gagal memproses sinkronisasi: Status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal melakukan sinkronisasi data ke cloud: $e');
    }
  }

  // Helper untuk memasukkan data barang ke database offline sebelum disinkronkan
  Future<void> cacheProductOffline(Map<String, dynamic> item) async {
    if (kIsWeb) return;
    await _dbHelper.insertBarangLocal(item);
  }

  // Helper untuk memasukkan data pelanggan ke database offline sebelum disinkronkan
  Future<void> cachePelangganOffline(Map<String, dynamic> customer) async {
    if (kIsWeb) return;
    await _dbHelper.insertPelangganLocal(customer);
  }
}
