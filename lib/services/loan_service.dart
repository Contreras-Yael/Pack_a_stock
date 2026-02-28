import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/loan_model.dart';
import 'storage_service.dart';

class LoanService {
  final StorageService _storage = StorageService();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.getToken();
    return {
      ...ApiConfig.headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Loan>> getMyLoans() async {
    try {
      final headers = await _authHeaders();
      final url = Uri.parse('${ApiConfig.baseUrl}/loans/loans/my_loans/');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> list =
            decoded is List ? decoded : decoded['results'] ?? [];
        return list.map((json) => Loan.fromJson(json)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> requestExtension({
    required int loanId,
    required DateTime newReturnDate,
    String? reason,
  }) async {
    try {
      final headers = await _authHeaders();
      final url = Uri.parse('${ApiConfig.baseUrl}/loans/loan-extensions/');
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'loan': loanId,
          'new_return_date': newReturnDate.toIso8601String().split('T')[0],
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        }),
      );

      if (response.statusCode == 201) {
        return {'success': true};
      }
      final decoded = jsonDecode(response.body);
      return {
        'success': false,
        'message': decoded['detail'] ?? decoded['error'] ?? 'Error al solicitar extensión',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  Future<List<LoanExtension>> getMyExtensions({int? loanId}) async {
    try {
      final headers = await _authHeaders();
      var urlStr = '${ApiConfig.baseUrl}/loans/loan-extensions/';
      if (loanId != null) urlStr += '?loan=$loanId';
      final url = Uri.parse(urlStr);
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> list =
            decoded is List ? decoded : decoded['results'] ?? [];
        return list.map((json) => LoanExtension.fromJson(json)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
