import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async =>
      _storage.write(key: 'auth_token', value: token);

  Future<String?> getToken() async =>
      _storage.read(key: 'auth_token');

  Future<void> saveRefreshToken(String token) async =>
      _storage.write(key: 'refresh_token', value: token);

  Future<String?> getRefreshToken() async =>
      _storage.read(key: 'refresh_token');

  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
