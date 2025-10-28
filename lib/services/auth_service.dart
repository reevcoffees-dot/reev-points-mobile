import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';
import '../utils/app_constants.dart';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  String? _token;
  
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  
  final ApiService _apiService = ApiService();
  
  AuthService() {
    _loadAuthData();
  }
  
  // Load saved authentication data
  Future<void> _loadAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(AppConstants.tokenKey);
      final userData = prefs.getString(AppConstants.userKey);
      
      if (_token != null && userData != null) {
        _user = json.decode(userData);
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading auth data: $e');
    }
  }
  
  // Save authentication data
  Future<void> _saveAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) {
        await prefs.setString(AppConstants.tokenKey, _token!);
      }
      if (_user != null) {
        await prefs.setString(AppConstants.userKey, json.encode(_user!));
      }
    } catch (e) {
      print('Error saving auth data: $e');
    }
  }
  
  // Login
  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiService.post(
        AppConstants.loginEndpoint,
        data: {
          'email': email,
          'password': password,
        },
      );
      
      if (response['success'] == true) {
        _token = response['token'];
        _user = response['user'];
        _isAuthenticated = true;
        
        print('Login successful - User ID: ${_user?['id']}');
        print('User data: $_user');
        
        await _saveAuthData();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }
  
  // Register
  Future<Map<String, dynamic>?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required bool consentGiven,
  }) async {
    try {
      final response = await _apiService.post(
        AppConstants.registerEndpoint,
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'consent_given': consentGiven,
        },
      );
      
      if (response['success'] == true) {
        return response;
      }
      return null;
    } catch (e) {
      print('Register error: $e');
      return null;
    }
  }

  // Verify Email
  Future<bool> verifyEmail({
    required int userId,
    required String verificationCode,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/verify-email',
        data: {
          'user_id': userId,
          'verification_code': verificationCode,
        },
      );
      
      if (response['success'] == true) {
        _token = response['token'];
        _user = response['user'];
        _isAuthenticated = true;
        
        await _saveAuthData();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Verify email error: $e');
      return false;
    }
  }

  // Resend Verification Code
  Future<bool> resendVerificationCode(int userId) async {
    try {
      final response = await _apiService.post(
        '/api/resend-verification',
        data: {
          'user_id': userId,
        },
      );
      
      return response['success'] == true;
    } catch (e) {
      print('Resend verification error: $e');
      return false;
    }
  }
  
  // Logout
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.tokenKey);
      await prefs.remove(AppConstants.userKey);
      
      _token = null;
      _user = null;
      _isAuthenticated = false;
      
      notifyListeners();
    } catch (e) {
      print('Logout error: $e');
    }
  }
  
  // Update user data
  void updateUser(Map<String, dynamic> userData) {
    _user = userData;
    _saveAuthData();
    notifyListeners();
  }
  
  // Request Password Reset
  Future<bool> requestPasswordReset(String email) async {
    try {
      print('Password reset email sending: $email');
      
      // Sanitize email to handle Turkish characters safely
      String sanitizedEmail = email;
      
      // Replace Turkish characters one by one with explicit Unicode handling
      sanitizedEmail = sanitizedEmail.replaceAll('\u0131', 'i'); // ı
      sanitizedEmail = sanitizedEmail.replaceAll('\u0130', 'I'); // İ
      sanitizedEmail = sanitizedEmail.replaceAll('\u011F', 'g'); // ğ
      sanitizedEmail = sanitizedEmail.replaceAll('\u011E', 'G'); // Ğ
      sanitizedEmail = sanitizedEmail.replaceAll('\u00FC', 'u'); // ü
      sanitizedEmail = sanitizedEmail.replaceAll('\u00DC', 'U'); // Ü
      sanitizedEmail = sanitizedEmail.replaceAll('\u015F', 's'); // ş
      sanitizedEmail = sanitizedEmail.replaceAll('\u015E', 'S'); // Ş
      sanitizedEmail = sanitizedEmail.replaceAll('\u00F6', 'o'); // ö
      sanitizedEmail = sanitizedEmail.replaceAll('\u00D6', 'O'); // Ö
      sanitizedEmail = sanitizedEmail.replaceAll('\u00E7', 'c'); // ç
      sanitizedEmail = sanitizedEmail.replaceAll('\u00C7', 'C'); // Ç
      
      print('Sanitized email: $sanitizedEmail');
      
      final response = await _apiService.post(
        '/api/request-password-reset',
        data: {
          'email': sanitizedEmail,
        },
      );
      
      return response['success'] == true;
    } catch (e) {
      print('Password reset email error: $e');
      return false;
    }
  }

  // Reset Password with Code
  Future<bool> resetPassword({
    required String email,
    required String resetCode,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/reset-password',
        data: {
          'email': email,
          'reset_code': resetCode,
          'new_password': newPassword,
        },
      );
      
      return response['success'] == true;
    } catch (e) {
      print('Reset password error: $e');
      return false;
    }
  }

  // Get authorization headers
  Map<String, String> getAuthHeaders() {
    if (_token != null) {
      return {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json; charset=utf-8',
      };
    }
    return {'Content-Type': 'application/json; charset=utf-8'};
  }
}
