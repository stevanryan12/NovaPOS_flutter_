import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pemograman_mobile_2/config.dart';

class AnalitikController {
  static final String baseUrl = AppConfig.baseUrl;

  // Mengambil data analitik omzet dan laba/rugi harian
  Future<List<Map<String, dynamic>>> fetchAnalitikLabaRugi() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/analitik/laba-rugi'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Gagal memuat data analitik laba/rugi');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
