import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ApiService {
  static const String baseUrl = 'http://198.71.54.179:8000/api'; 

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<User?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/token/');

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        print('Error Servidor: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error de conexión: $e');
      return null;
    }
  }
  
  Future<List<dynamic>> getMateirials(String token) async {
    final url = Uri.parse('$baseUrl/materials/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // final List<dynamic> data = json.decode(response.body);
        return jsonDecode(response.body);
      } else {
        throw Exception('Fallo al cargar materiales: ${response.statusCode}');
      }
    } catch (e) {
      print('Error de conexión: $e');
      return [];
    }
  }
}