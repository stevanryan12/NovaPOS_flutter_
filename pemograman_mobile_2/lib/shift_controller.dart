import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pemograman_mobile_2/config.dart';

class ShiftController {
  static final String baseUrl = AppConfig.baseUrl;

  Future<Map<String, dynamic>?> checkActiveShift() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/shift/status'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['active'] == true) {
          return data['data'];
        }
        return null;
      } else {
        throw Exception('Failed to load shift status');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> openShift(String namaKasir, double modalAwal) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shift/buka'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'nama_kasir': namaKasir, 'modal_awal': modalAwal}),
      );
      if (response.statusCode != 201) {
        throw Exception('Failed to open shift');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> closeShift(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shift/tutup/$id'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to close shift');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
