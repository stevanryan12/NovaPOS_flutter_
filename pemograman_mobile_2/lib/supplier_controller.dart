import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pemograman_mobile_2/config.dart';

class SupplierController {
  static final String baseUrl = AppConfig.baseUrl;

  Future<List<Map<String, dynamic>>> fetchSupplier() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/supplier'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load Supplier');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> deleteSupplier(String idSup) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/supplier/$idSup'),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to delete Supplier');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<void> addSupplier(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/supplier'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode != 201) {
        throw Exception('Failed to add Supplier');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<void> updateSupplier(
    String IdSup,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/supplier/$IdSup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update Supplier');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
