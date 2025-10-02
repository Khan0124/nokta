import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'security_service.dart';

class ApiService {
  static final String _baseUrl = kDebugMode 
      ? 'http://localhost:3000' 
      : 'https://api.nokta-pos.com';
  
  static late Dio _dio;
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  static String? _authToken;
  static String? _tenantId;
  
  static void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Add interceptors
    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(SecurityInterceptor());
    
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }

  // Modern API methods using Dio
  static Future<Response> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      return await _dio.get(endpoint, queryParameters: queryParams);
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Response> post(String endpoint, {dynamic data}) async {
    try {
      return await _dio.post(endpoint, data: data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Response> put(String endpoint, {dynamic data}) async {
    try {
      return await _dio.put(endpoint, data: data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Response> delete(String endpoint) async {
    try {
      return await _dio.delete(endpoint);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Authentication methods
  static Future<void> setAuthToken(String token) async {
    _authToken = token;
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<void> setTenantId(String tenantId) async {
    _tenantId = tenantId;
    await _storage.write(key: 'tenant_id', value: tenantId);
  }

  static Future<void> loadStoredCredentials() async {
    _authToken = await _storage.read(key: 'auth_token');
    _tenantId = await _storage.read(key: 'tenant_id');
  }

  static Future<void> clearAuth() async {
    _authToken = null;
    _tenantId = null;
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'tenant_id');
  }

  static ApiException _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ApiException('Connection timeout', 408);
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode ?? 500;
          final message = error.response?.data?['message'] ?? 'Server error';
          return ApiException(message, statusCode);
        case DioExceptionType.cancel:
          return ApiException('Request cancelled', 0);
        default:
          return ApiException('Network error', 500);
      }
    }
    return ApiException('Unknown error', 500);
  }
}

// Custom interceptors for security and authentication
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (ApiService._authToken != null) {
      options.headers['Authorization'] = 'Bearer ${ApiService._authToken}';
    }
    if (ApiService._tenantId != null) {
      options.headers['X-Tenant-ID'] = ApiService._tenantId;
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Handle unauthorized - redirect to login
      ApiService.clearAuth();
    }
    handler.next(err);
  }
}

class SecurityInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add security headers
    options.headers['X-Requested-With'] = 'XMLHttpRequest';
    options.headers['X-Client-Version'] = '1.0.0';
    
    // Validate and sanitize data
    if (options.data is Map<String, dynamic>) {
      options.data = _sanitizeRequestData(options.data);
    }
    
    handler.next(options);
  }

  Map<String, dynamic> _sanitizeRequestData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    for (final entry in data.entries) {
      if (entry.value is String) {
        sanitized[entry.key] = SecurityService.sanitizeInput(entry.value);
      } else {
        sanitized[entry.key] = entry.value;
      }
    }
    return sanitized;
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}