import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  // Instancia única (Singleton) para no abrir múltiples conexiones
  final _storage = const FlutterSecureStorage();

  // Guardar token
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  // Leer token
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // Borrar token (Cerrar Sesión)
  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }
}