// packages/core/lib/services/auth_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import 'dart:convert';

class AuthService {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  
  AuthService(this._dio, this._storage);
  
  Future<AuthResult> login({
    required String username,
    required String password,
    required String tenantId,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      }, options: Options(headers: {
        'X-Tenant-ID': tenantId,
      }));
      
      final token = response.data['token'];
      final user = User.fromMap(response.data['user']);
      
      // Store credentials securely
      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(key: 'tenant_id', value: tenantId);
      
      // Configure dio for future requests
      _dio.options.headers['Authorization'] = 'Bearer $token';
      _dio.options.headers['X-Tenant-ID'] = tenantId;
      
      return AuthResult.success(user: user, token: token);
    } on DioException catch (e) {
      return AuthResult.failure(
        message: e.response?.data['message'] ?? 'Login failed',
      );
    }
  }
  
  Future<bool> isTokenValid() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return false;
    
    // Simple JWT expiration check - decode base64 payload and check exp
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(resp);
      
      final exp = payloadMap['exp'];
      if (exp == null) return false;
      
      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isBefore(expiry);
    } catch (e) {
      return false;
    }
  }
  
  Future<void> logout() async {
    await _storage.deleteAll();
    _dio.options.headers.remove('Authorization');
    _dio.options.headers.remove('X-Tenant-ID');
  }
  
  Future<User?> getCurrentUser() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) return null;
      
      final response = await _dio.get('/auth/profile');
      return User.fromMap(response.data);
    } catch (e) {
      return null;
    }
  }
}

// AuthResult is imported from user.dart

// Provider setup
final dioProvider = Provider((ref) => Dio());

final authServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return AuthService(dio, const FlutterSecureStorage());
});