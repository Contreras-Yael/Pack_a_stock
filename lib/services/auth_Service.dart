import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class AuthService {
  final StorageService _storage = StorageService();
  
  Future<User?> login(String email, String password) async {
    
    final url = Uri.parse('${ApiConfig.baseUrl}/token/');

    try {
      print("📡 Intentando conectar a: $url"); // Log para depurar

      final response = await http.post(
        url,
        // Asegúrate de que ApiConfig tenga el getter 'headers' que te pasé antes
        headers: ApiConfig.headers, 
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print("Respuesta Server: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // ⚠️ CORRECCIÓN 2: Lógica directa para Django SimpleJWT
        // Tu backend devuelve 'access' y 'refresh'
        final String? accessToken = data['access'] ?? data['token'];
        
        if (accessToken != null) {
           await _storage.saveToken(accessToken);
           // Si tienes refresh token, guárdalo también si quieres
           // await _storage.saveRefreshToken(data['refresh']);
        }

        // ⚠️ CORRECCIÓN 3: El usuario suele venir anidado en 'user'
        // Según tus logs anteriores: { "access": "...", "user": { ... } }
        if (data['user'] != null) {
          return User.fromJson(data['user']);
        } else {
          // Fallback por si acaso viene en la raíz
          return User.fromJson(data);
        }

      } else {
        print('❌ Error Login: ${response.statusCode} - ${response.body}');
        return null;
      }
      
    } catch (e) {
      print('❌ Error Auth (Excepción): $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.deleteToken();
  }
}