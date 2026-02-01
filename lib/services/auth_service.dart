import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _storage.read(key: 'auth_token');
      if (token != null) {
        _apiService.setToken(token);
        await _loadCurrentUser();
      }
    } catch (e) {
      _error = 'Failed to initialize: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    // Don't notify here to avoid rebuilding login screen

    try {
      final response = await _apiService.login(email, password);
      final token = response['access_token'];

      await _storage.write(key: 'auth_token', value: token);
      _apiService.setToken(token);

      await _loadCurrentUser();

      _isLoading = false;
      notifyListeners(); // Only notify on success (navigates away)
      return true;
    } catch (e) {
      // Clean up error message
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      // Don't notify on error - let login screen handle it
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    String role = 'user',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.register(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        role: role,
      );
      final token = response['access_token'];

      await _storage.write(key: 'auth_token', value: token);
      _apiService.setToken(token);

      // Try to load current user, but don't fail registration if it doesn't work
      try {
        await _loadCurrentUser();
      } catch (e) {
        print('Warning: Could not load user after registration: $e');
        // Set user data from registration response instead
        if (response['user'] != null) {
          _currentUser = User.fromJson(response['user']);
          _isAuthenticated = true;
        }
      }

      // Clear any errors - registration was successful
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: Registration failed: ', '').replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    _apiService.clearToken();
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> _loadCurrentUser() async {
    try {
      _currentUser = await _apiService.getCurrentUser();
      _isAuthenticated = true;
    } catch (e) {
      _error = 'Failed to load user: ${e.toString()}';
      _isAuthenticated = false;
      await logout();
    }
  }

  Future<void> refreshUser() async {
    if (_isAuthenticated) {
      await _loadCurrentUser();
      notifyListeners();
    }
  }
}
