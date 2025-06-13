import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.0.102:8000/api';

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

  Future<Map<String, dynamic>> getExpenseType() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/expense-type'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load expense types');
      }
    } catch (e) {
      throw Exception('Failed to load expense types: $e');
    }
  }

  Future<Map<String, dynamic>> addExpenseType(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/expense-type'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to add expense type');
      }
    } catch (e) {
      throw Exception('Failed to add expense type: $e');
    }
  }

  Future<Map<String, dynamic>> deleteExpenseType(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/expense-type/$id/delete'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to delete expense type');
      }
    } catch (e) {
      throw Exception('Failed to delete expense type: $e');
    }
  }

  Future<Map<String, dynamic>> updateExpenseType(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/expense-type/$id/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update expense type');
      }
    } catch (e) {
      throw Exception('Failed to update expense type: $e');
    }
  }

  Future<Map<String, dynamic>> updateSaldo(int amount, String action) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update-saldo'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'amount': amount, 'action': action}),
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

  Future<void> setPin(String pin, String pinConfirmation) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/set-pin'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"pin": pin, "pin_confirmation": pinConfirmation}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Gagal mengatur PIN');
    }
  }

  Future<bool> validatePin(String pin) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/validate-pin'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'pin': pin}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['valid'] == true;
    }
    return false;
  }

  Future<Map<String, dynamic>> addTarget(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/target/add'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal menambah target');
    }
  }

  Future<Map<String, dynamic>> addTargetProgress({
    required String targetId,
    required String progress,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/target/progress'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"target_id": targetId, "progress": progress}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal menambah progress target');
    }
  }

  Future<void> deleteTarget(String id) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/target/$id/delete'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Gagal menghapus target');
    }
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final response = await http.get(Uri.parse('$baseUrl/history'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['history'] ?? []);
    } else {
      throw Exception('Gagal mengambil riwayat pengeluaran');
    }
  }

  Future<Map<String, double>> getPieChartData() async {
    final data = await ApiService().getExpenseType();
    final List types = data['expenseTypes'] ?? [];
    Map<String, double> chartData = {};
    for (var type in types) {
      chartData[type['name']] = (type['total_spent'] ?? 0).toDouble();
    }
    print(chartData);
    return chartData;
  }

  Future<void> scanQrisPayment({
    required String amount,
    required String pin,
    required String expenseTypeId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/scan-qris'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "amount": amount,
        "pin": pin,
        "expense_type_id": expenseTypeId,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Pembayaran QRIS gagal');
    }
  }
}
