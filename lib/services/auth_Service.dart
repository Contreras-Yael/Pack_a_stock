import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart'; // Asegúrate que el nombre del archivo sea correcto
import 'storage_service.dart';

class AuthService {
  final StorageService _storage = StorageService();
  
  Future<User?> login(String email, String password) async {
    // Cambiar según el endpoint correcto de tu backend
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/login/');

    try {
      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        // 1. Decodificar respuesta
        final data = json.decode(response.body);
        
        // 2. Guardar Token (AQUÍ es el lugar correcto)
        // Verifica con Postman si la llave es 'token', 'access' o 'key'
        if (data['token'] != null) {
          await _storage.saveToken(data['token']); 
        } else if (data['access'] != null) {
           // Django SimpleJWT suele usar 'access'
           await _storage.saveToken(data['access']);
        }

        // 3. Retornar Usuario
        return User.fromJson(data);

      } else {
        // Error del servidor
        print('Error Login: ${response.statusCode} - ${response.body}');
        return null;
      }
      
    } catch (e) {
      // Error de conexión / excepción
      print('Error Auth: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.deleteToken();
  }
}