import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class AuthService {
  final StorageService _storage = StorageService();

  // ─── Refresh token ────────────────────────────────────────────────────────
  Future<bool> refreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) return false;
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/token/refresh/'),
        headers: ApiConfig.headers,
        body: jsonEncode({'refresh': refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newAccess = data['access'] as String?;
        if (newAccess != null) {
          await _storage.saveToken(newAccess);
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  // ─── Helper: auth GET with auto-refresh on 401 ───────────────────────────
  Future<http.Response> _authGet(String path) async {
    final token = await _storage.getToken();
    final headers = {...ApiConfig.headers, if (token != null) 'Authorization': 'Bearer $token'};
    var response = await http.get(Uri.parse('${ApiConfig.baseUrl}$path'), headers: headers);
    if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) {
        final newToken = await _storage.getToken();
        final retryHeaders = {...ApiConfig.headers, if (newToken != null) 'Authorization': 'Bearer $newToken'};
        response = await http.get(Uri.parse('${ApiConfig.baseUrl}$path'), headers: retryHeaders);
      }
    }
    return response;
  }

  // ─── Login ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/login/');
    try {
      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final tokens = data['data']['tokens'];
        final userJson = data['data']['user'];
        await _storage.saveToken(tokens['access']);
        await _storage.saveRefreshToken(tokens['refresh']);
        return {'success': true, 'user': User.fromJson(userJson)};
      } else {
        final errors = data['errors'];
        String message = 'Credenciales incorrectas';
        if (errors != null && errors is Map) {
          final msgs = errors.values.expand((v) => v is List ? v : [v]).toList();
          if (msgs.isNotEmpty) message = msgs.first.toString();
        } else if (data['message'] != null) {
          message = data['message'];
        }
        return {'success': false, 'message': message};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión. Verifica tu red.'};
    }
  }

  // ─── Register Employee ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> registerEmployee({
    required String email,
    required String password,
    required String fullName,
    required String companyCode,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/register-employee/');
    try {
      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode({
          'email': email,
          'password': password,
          'full_name': fullName,
          'company_code': companyCode,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        final tokens = data['data']['tokens'];
        final userJson = data['data']['user'];
        await _storage.saveToken(tokens['access']);
        await _storage.saveRefreshToken(tokens['refresh']);
        return {'success': true, 'user': User.fromJson(userJson)};
      } else {
        String message = 'Error al registrarse';
        if (data['error'] != null) {
          message = data['error'];
        } else if (data['message'] != null) {
          message = data['message'];
        } else if (data['errors'] != null && data['errors'] is Map) {
          final msgs = (data['errors'] as Map)
              .values
              .expand((v) => v is List ? v : [v])
              .toList();
          if (msgs.isNotEmpty) message = msgs.first.toString();
        }
        return {'success': false, 'message': message};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión. Verifica tu red.'};
    }
  }

  // ─── Get Profile ──────────────────────────────────────────────────────────
  Future<User?> getProfile() async {
    try {
      final response = await _authGet('/auth/me/');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userJson = data['data'] ?? data;
        return User.fromJson(userJson);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ─── Update Profile ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> updateProfile({required String fullName}) async {
    final token = await _storage.getToken();
    if (token == null) return {'success': false, 'message': 'No autenticado'};
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/auth/me/update/'),
        headers: {...ApiConfig.headers, 'Authorization': 'Bearer $token'},
        body: jsonEncode({'full_name': fullName}),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'user': User.fromJson(data['data'])};
      }
      return {'success': false, 'message': data['message'] ?? 'Error al actualizar'};
    } catch (_) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  // ─── Change Password ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await _storage.getToken();
    if (token == null) return {'success': false, 'message': 'No autenticado'};
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/change-password/'),
        headers: {...ApiConfig.headers, 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true};
      }
      return {'success': false, 'message': data['error'] ?? data['message'] ?? 'Error al cambiar contraseña'};
    } catch (_) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    final refreshToken = await _storage.getRefreshToken();
    final token = await _storage.getToken();
    if (refreshToken != null) {
      try {
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/auth/logout/'),
          headers: {
            ...ApiConfig.headers,
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'refresh_token': refreshToken}),
        );
      } catch (_) {}
    }
    await _storage.deleteToken();
  }

  // ─── Is Logged In ─────────────────────────────────────────────────────────
  Future<bool> isLoggedIn() async {
    return await _storage.hasToken();
  }
}
