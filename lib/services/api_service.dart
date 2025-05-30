import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api'; 

  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/dashboard'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load dashboard data');
      }
    } catch (e) {
      throw Exception('Failed to load dashboard data: $e');
    }
  }

  // Fungsi untuk update saldo
  Future<Map<String, dynamic>> updateSaldo(int amount, String action) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update-saldo'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'amount': amount,
          'action': action,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update saldo');
      }
    } catch (e) {
      throw Exception('Failed to update saldo: $e');
    }
  }
}
