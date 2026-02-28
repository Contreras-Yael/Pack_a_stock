import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import 'storage_service.dart';

class OrderService {
  final StorageService _storage = StorageService();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.getToken();
    return {
      ...ApiConfig.headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Submit a new loan request to the backend.
  /// Returns {success: bool, order: Order?, message: String?}
  Future<Map<String, dynamic>> submitRequest({
    required List<CartItem> items,
    required DateTime pickupDate,
    DateTime? returnDate,
    String? purpose,
  }) async {
    final headers = await _authHeaders();
    final url = Uri.parse('${ApiConfig.baseUrl}/loans/loan-requests/');

    final body = {
      'desired_pickup_date': pickupDate.toIso8601String().split('T').first,
      if (returnDate != null)
        'desired_return_date':
            returnDate.toIso8601String().split('T').first,
      if (purpose != null && purpose.isNotEmpty) 'purpose': purpose,
      'items': items
          .map((item) => {
                'material_id': item.materialId,
                'quantity_requested': item.quantity,
              })
          .toList(),
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'order': Order.fromJson(data)};
      } else {
        String message = 'Error al enviar solicitud';
        if (data['items'] != null) {
          message = data['items'].toString();
        } else if (data['detail'] != null) {
          message = data['detail'];
        } else if (data is Map) {
          message = data.values
              .expand((v) => v is List ? v : [v])
              .first
              .toString();
        }
        return {'success': false, 'message': message};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión. Verifica tu red.'
      };
    }
  }

  /// Get the current user's loan requests (all statuses).
  Future<List<Order>> getMyRequests() async {
    final headers = await _authHeaders();
    final url =
        Uri.parse('${ApiConfig.baseUrl}/loans/loan-requests/?ordering=-requested_date');

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> list =
            decoded is List ? decoded : decoded['results'] ?? [];
        return list.map((j) => Order.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Returns counts: {active_loans, pending_requests, completed_loans}
  Future<Map<String, int>> getMySummary() async {
    final requests = await getMyRequests();
    int active = 0, pending = 0, completed = 0;
    for (final r in requests) {
      switch (r.status) {
        case 'active':
          active++;
          break;
        case 'pending':
          pending++;
          break;
        case 'completed':
        case 'returned':
          completed++;
          break;
      }
    }
    return {
      'active_loans': active,
      'pending_requests': pending,
      'completed_loans': completed,
    };
  }
}
