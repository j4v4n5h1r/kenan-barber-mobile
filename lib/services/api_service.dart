import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/service_model.dart';
import '../models/transaction_model.dart';

class ApiService {
  static const String baseUrl = 'http://159.223.236.229/api';

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Auth endpoints
  Future<Map<String, dynamic>> login(String email, String password) async {
    final username = email.contains('@') ? email.split('@')[0] : email;

    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _getHeaders(includeAuth: false),
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      // Parse error message from response
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['detail'] ?? 'Giriş uğursuz oldu';
        throw Exception(errorMessage);
      } catch (e) {
        if (e.toString().contains('Exception:')) {
          rethrow;
        }
        throw Exception('Giriş uğursuz oldu');
      }
    }
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    String role = 'user',
  }) async {
    // Generate username from email (backend requires it)
    final username = email.contains('@') ? email.split('@')[0] : email;

    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _getHeaders(includeAuth: false),
      body: jsonEncode({
        'username': username,
        'full_name': fullName,
        'email': email,
        'phone_number': phoneNumber,
        'password': password,
        'role': role,
      }),
    );

    print('Register response status: ${response.statusCode}');
    print('Register response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        print('JSON parse error: $e');
        throw Exception('Invalid JSON response: ${response.body}');
      }
    } else {
      print('Registration failed with status ${response.statusCode}');
      throw Exception('Registration failed: ${response.body}');
    }
  }

  // User endpoints
  Future<User> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get user: ${response.body}');
    }
  }

  Future<List<Transaction>> getUserTransactions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions/my-history'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Transaction.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get transactions: ${response.body}');
    }
  }

  // Seller endpoints
  Future<List<Service>> getSellerServices() async {
    final response = await http.get(
      Uri.parse('$baseUrl/services/my-services'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Service.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get services: ${response.body}');
    }
  }

  Future<Service> createService({
    required String name,
    required double price,
    required double cashbackPercentage,
    String? serviceType,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/services/'),
      headers: _getHeaders(),
      body: jsonEncode({
        'name': name,
        'price': price,
        'service_type': serviceType ?? 'barber',
        'description': name,
      }),
    );

    if (response.statusCode == 201) {
      return Service.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create service: ${response.body}');
    }
  }

  Future<void> deleteService(int serviceId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/services/$serviceId'),
      headers: _getHeaders(),
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete service: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> processCashback({
    required String customerQrCode,
    required int serviceId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sellers/me/cashback'),
      headers: _getHeaders(),
      body: jsonEncode({
        'customer_qr_code': customerQrCode,
        'service_id': serviceId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to process cashback: ${response.body}');
    }
  }

  Future<List<Transaction>> getSellerTransactions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions/my-history'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Transaction.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get seller transactions: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getSellerStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/sellers/me/stats'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get seller stats: ${response.body}');
    }
  }

  // Admin endpoints
  Future<List<User>> getAllUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get users: ${response.body}');
    }
  }

  Future<void> updateUserRole(int userId, String newRole) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId/role'),
      headers: _getHeaders(),
      body: jsonEncode({'role': newRole}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update user role: ${response.body}');
    }
  }

  Future<List<Transaction>> getAllTransactions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions/admin/all'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Transaction.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get all transactions: ${response.body}');
    }
  }

  // Settings endpoints
  Future<String> getCashbackPercentage() async {
    final response = await http.get(
      Uri.parse('$baseUrl/settings/cashback-percentage'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['value'];
    } else {
      throw Exception('Failed to get cashback percentage: ${response.body}');
    }
  }

  Future<void> updateCashbackPercentage(String percentage) async {
    final response = await http.put(
      Uri.parse('$baseUrl/settings/cashback-percentage'),
      headers: _getHeaders(),
      body: jsonEncode({'value': percentage}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update cashback percentage: ${response.body}');
    }
  }
}
