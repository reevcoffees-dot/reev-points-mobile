import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_constants.dart';

class ApiService {
  final String baseUrl = AppConstants.baseUrl;
  
  // GET request
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? headers}) async {
    try {
      final defaultHeaders = {
        'Content-Type': 'application/json; charset=utf-8',
      };
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers ?? defaultHeaders,
      );
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // POST request
  Future<Map<String, dynamic>> post(String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    try {
      final defaultHeaders = {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
        'Accept-Charset': 'utf-8',
        'User-Agent': 'Flutter-App/1.0',
        'Accept-Encoding': 'identity', // Disable compression to avoid encoding issues
      };
      
      List<int>? bodyBytes;
      if (data != null) {
        try {
          // Create a safe copy of data with Turkish character handling
          final safeData = <String, dynamic>{};
          data.forEach((key, value) {
            if (value is String) {
              // Replace Turkish characters in all string values
              String cleanValue = value;
              cleanValue = cleanValue.replaceAll('\u0131', 'i'); // ı
              cleanValue = cleanValue.replaceAll('\u0130', 'I'); // İ
              cleanValue = cleanValue.replaceAll('\u011F', 'g'); // ğ
              cleanValue = cleanValue.replaceAll('\u011E', 'G'); // Ğ
              cleanValue = cleanValue.replaceAll('\u00FC', 'u'); // ü
              cleanValue = cleanValue.replaceAll('\u00DC', 'U'); // Ü
              cleanValue = cleanValue.replaceAll('\u015F', 's'); // ş
              cleanValue = cleanValue.replaceAll('\u015E', 'S'); // Ş
              cleanValue = cleanValue.replaceAll('\u00F6', 'o'); // ö
              cleanValue = cleanValue.replaceAll('\u00D6', 'O'); // Ö
              cleanValue = cleanValue.replaceAll('\u00E7', 'c'); // ç
              cleanValue = cleanValue.replaceAll('\u00C7', 'C'); // Ç
              safeData[key] = cleanValue;
            } else {
              safeData[key] = value;
            }
          });
          
          final jsonString = json.encode(safeData);
          bodyBytes = utf8.encode(jsonString);
          print('Request body encoded successfully');
        } catch (e) {
          print('JSON encoding error: $e');
          rethrow;
        }
      }
      
      final uri = Uri.parse('$baseUrl$endpoint');
      print('Making POST request to: $uri');
      
      final response = await http.post(
        uri,
        headers: headers ?? defaultHeaders,
        body: bodyBytes,
      );
      
      return _handleResponse(response);
    } catch (e) {
      print('POST request error: $e');
      throw Exception('Network error: $e');
    }
  }
  
  // PUT request
  Future<Map<String, dynamic>> put(String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    try {
      final defaultHeaders = {
        'Content-Type': 'application/json; charset=utf-8',
      };
      
      List<int>? requestBodyBytes;
      if (data != null) {
        // Handle Turkish characters by working directly with UTF-8 bytes
        final jsonString = json.encode(data);
        requestBodyBytes = utf8.encode(jsonString);
      }
      
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers ?? defaultHeaders,
        body: requestBodyBytes,
        encoding: utf8,
      );
      
      return _handleResponse(response);
    } catch (e) {
      print('PUT request error: $e');
      throw Exception('Network error: $e');
    }
  }
  
  // DELETE request
  Future<Map<String, dynamic>> delete(String endpoint, {Map<String, String>? headers}) async {
    try {
      final defaultHeaders = {
        'Content-Type': 'application/json; charset=utf-8',
      };
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers ?? defaultHeaders,
      );
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Product approval method
  Future<Map<String, dynamic>> approveProduct({
    required String productId,
    required String userId,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await post(
        AppConstants.approveProductEndpoint,
        data: {
          'product_id': productId,
          'user_id': userId,
        },
        headers: headers,
      );
      return response;
    } catch (e) {
      throw Exception('Product approval failed: $e');
    }
  }

  // Save customer QR code to database
  Future<Map<String, dynamic>> saveCustomerQr({
    required String userId,
    required String qrCode,
    required String qrType, // 'dashboard', 'campaign', 'product_request'
    String? campaignId,
    String? productId,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await post(
        AppConstants.saveCustomerQrEndpoint,
        data: {
          'user_id': userId,
          'qr_code': qrCode,
          'qr_type': qrType,
          'campaign_id': campaignId,
          'product_id': productId,
          'created_at': DateTime.now().toIso8601String(),
        },
        headers: headers,
      );
      return response;
    } catch (e) {
      throw Exception('Save customer QR failed: $e');
    }
  }

  // Get transaction history for user
  Future<Map<String, dynamic>> getTransactionHistory({
    required String userId,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await get(
        '${AppConstants.transactionHistoryEndpoint}?user_id=$userId',
        headers: headers,
      );
      return response;
    } catch (e) {
      throw Exception('Transaction history fetch failed: $e');
    }
  }

  // Get purchase history for user (for rating)
  Future<Map<String, dynamic>> getPurchaseHistory({
    required String userId,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await get(
        '${AppConstants.purchaseHistoryEndpoint}?user_id=$userId',
        headers: headers,
      );
      return response;
    } catch (e) {
      throw Exception('Purchase history fetch failed: $e');
    }
  }

  // Rate a product
  Future<Map<String, dynamic>> rateProduct({
    required String userId,
    required String productId,
    required int rating,
    String? comment,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await post(
        AppConstants.rateProductEndpoint,
        data: {
          'user_id': userId,
          'product_id': productId,
          'rating': rating,
          'comment': comment,
        },
        headers: headers,
      );
      return response;
    } catch (e) {
      throw Exception('Product rating failed: $e');
    }
  }

  // Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final dynamic decodedBody = json.decode(response.body);
      final Map<String, dynamic> data = decodedBody is Map<String, dynamic> 
          ? decodedBody 
          : <String, dynamic>{};
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        // Try both 'error' and 'message' fields for error messages
        final dynamic errorField = data['error'];
        final dynamic messageField = data['message'];
        String errorMessage = (errorField?.toString()) ?? 
                             (messageField?.toString()) ?? 
                             'API Error: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format');
      }
      rethrow;
    }
  }

  // Splash resmi çek
  Future<Map<String, dynamic>> getSplashImage() async {
    return await get(AppConstants.splashImageEndpoint);
  }

  // Şifre değiştirme
  Future<Map<String, dynamic>> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await post(
        AppConstants.changePasswordEndpoint,
        data: {
          'user_id': userId,
          'current_password': currentPassword,
          'new_password': newPassword,
        },
        headers: headers,
      );
      return response;
    } catch (e) {
      throw Exception('Şifre değiştirme başarısız: $e');
    }
  }
}
