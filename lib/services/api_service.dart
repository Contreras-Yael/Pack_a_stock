import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api'; 

  Future<User?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/token/');

    try {
      final response = await http.post(
        url,
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        print('Error en login: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error de conexión: $e');
      return null;
    }
  }
  
  // Aquí agregaremos luego getMaterials(), createLoan(), etc.
}