import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/material_model.dart'; // Tu modelo corregido
import 'storage_service.dart';

class MaterialService {
  final StorageService _storage = StorageService();

 Future<List<MaterialItem>> getMaterials() async {
    final token = await _storage.getToken();
    
    if (token == null) {
      print('No hay sesión iniciada');
      return [];
    }
    
    final url = Uri.parse('${ApiConfig.baseUrl}/materials/');
    
    try {
      final response = await http.get(
        url,
        headers: {
          ...ApiConfig.headers, // Copia los headers base
          'Authorization': 'Bearer $token', // O 'Token $token'
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = jsonDecode(response.body);
        return decodedData.map((json) => MaterialItem.fromJson(json)).toList();
      } else {
        print('Error Materiales: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error Materiales: $e');
      return [];
    }
  }

  // Método futuro para buscar por QR
  Future<MaterialItem?> getItemByQR(String qrCode, String token) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/items/by-qr/$qrCode/');
    return null; // Placeholder
  }
}