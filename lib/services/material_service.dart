import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/material_model.dart';
import 'storage_service.dart';

class MaterialService {
  final StorageService _storage = StorageService();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.getToken();
    return {
      ...ApiConfig.headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<MaterialItem>> getMaterials() async {
    final headers = await _authHeaders();
    final url = Uri.parse('${ApiConfig.baseUrl}/materials/materials/');

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // DRF list returns array or paginated {results: [...]}
        final List<dynamic> list =
            decoded is List ? decoded : decoded['results'] ?? [];
        return list.map((json) => MaterialItem.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<MaterialItem?> getByQr(String qrCode) async {
    final headers = await _authHeaders();
    final url = Uri.parse(
        '${ApiConfig.baseUrl}/materials/materials/search_by_qr/?qr_code=${Uri.encodeComponent(qrCode)}');

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MaterialItem.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<MaterialItem?> getById(int id) async {
    final headers = await _authHeaders();
    final url = Uri.parse('${ApiConfig.baseUrl}/materials/materials/$id/');

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MaterialItem.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
