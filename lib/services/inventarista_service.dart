import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/material_model.dart';
import '../models/pending_request_model.dart';
import 'storage_service.dart';

class InventaristaService {
  final StorageService _storage = StorageService();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.getToken();
    return {
      ...ApiConfig.headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── Get categories ───────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/materials/categories/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data is List ? data : (data['results'] ?? data['data'] ?? []);
        return List<Map<String, dynamic>>.from(list);
      }
    } catch (_) {}
    return [];
  }

  // ─── Get locations ────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getLocations() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/materials/locations/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data is List ? data : (data['results'] ?? data['data'] ?? []);
        return List<Map<String, dynamic>>.from(list);
      }
    } catch (_) {}
    return [];
  }

  // ─── Create material (multipart with optional image) ─────────────────────
  Future<Map<String, dynamic>> createMaterial({
    required String name,
    required String description,
    required int categoryId,
    required int locationId,
    required int quantity,
    required bool isConsumable,
    File? image,
  }) async {
    try {
      final token = await _storage.getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/materials/materials/'),
      );
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['category'] = categoryId.toString();
      request.fields['location'] = locationId.toString();
      request.fields['quantity'] = quantity.toString();
      request.fields['is_consumable'] = isConsumable.toString();

      if (image != null) {
        request.files.add(await http.MultipartFile.fromPath('image', image.path));
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final body = json.decode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': body};
      }
      return {
        'success': false,
        'message': body['detail'] ?? body['message'] ?? 'Error al crear material'
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  // ─── Get pending loan requests ────────────────────────────────────────────
  Future<({List<PendingRequest> items, String? error})> getPendingRequests() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/loans/loan-requests/pending/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data is List ? data : (data['results'] ?? data['data'] ?? []);
        final items = (list as List)
            .map((e) => PendingRequest.fromJson(e as Map<String, dynamic>))
            .toList();
        return (items: items, error: null);
      }
      return (
        items: <PendingRequest>[],
        error: 'HTTP ${response.statusCode}: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}',
      );
    } catch (e) {
      return (items: <PendingRequest>[], error: 'Excepción: $e');
    }
  }

  // ─── Approve loan request ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> approveLoanRequest(int id, {String? notes}) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/loans/loan-requests/$id/approve/'),
        headers: headers,
        body: jsonEncode({'notes': notes ?? ''}),
      );
      final body = json.decode(response.body);
      if (response.statusCode == 200) return {'success': true};
      return {
        'success': false,
        'message': body['detail'] ?? body['message'] ?? 'Error al aprobar'
      };
    } catch (_) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  // ─── Reject loan request ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> rejectLoanRequest(int id, {String? reason}) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/loans/loan-requests/$id/reject/'),
        headers: headers,
        body: jsonEncode({'notes': reason ?? ''}),
      );
      final body = json.decode(response.body);
      if (response.statusCode == 200) return {'success': true};
      return {
        'success': false,
        'message': body['detail'] ?? body['message'] ?? 'Error al rechazar'
      };
    } catch (_) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  // ─── Get material by QR ───────────────────────────────────────────────────
  Future<MaterialItem?> getMaterialByQr(String qrCode) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/materials/materials/search_by_qr/?qr_code=${Uri.encodeComponent(qrCode)}'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final materialJson = data['data'] ?? data;
        return MaterialItem.fromJson(materialJson);
      }
    } catch (_) {}
    return null;
  }
}
