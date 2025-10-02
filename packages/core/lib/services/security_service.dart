// packages/core/lib/services/security_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecurityService {
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: const AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: const IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Hash password using bcrypt-like approach
  static String hashPassword(String password) {
    final salt = _generateSalt();
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return '${salt}\$${digest.toString()}';
  }

  // Verify password against hash
  static bool verifyPassword(String password, String hash) {
    try {
      final parts = hash.split('\$');
      if (parts.length != 2) return false;
      
      final salt = parts[0];
      final storedHash = parts[1];
      
      final bytes = utf8.encode(password + salt);
      final digest = sha256.convert(bytes);
      
      return digest.toString() == storedHash;
    } catch (e) {
      return false;
    }
  }

  // Generate random salt
  static String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(saltBytes);
  }

  // Encrypt sensitive data
  static String encryptData(String data, String key) {
    try {
      final keyBytes = utf8.encode(key.padRight(32, '0').substring(0, 32));
      final dataBytes = utf8.encode(data);
      
      // Simple XOR encryption (في بيئة الإنتاج استخدم AES)
      final encrypted = <int>[];
      for (int i = 0; i < dataBytes.length; i++) {
        encrypted.add(dataBytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      return base64.encode(encrypted);
    } catch (e) {
      throw Exception('Failed to encrypt data: $e');
    }
  }

  // Decrypt sensitive data
  static String decryptData(String encryptedData, String key) {
    try {
      final keyBytes = utf8.encode(key.padRight(32, '0').substring(0, 32));
      final encryptedBytes = base64.decode(encryptedData);
      
      final decrypted = <int>[];
      for (int i = 0; i < encryptedBytes.length; i++) {
        decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      return utf8.decode(decrypted);
    } catch (e) {
      throw Exception('Failed to decrypt data: $e');
    }
  }

  // Store sensitive data securely
  static Future<void> storeSecurely(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  // Read sensitive data securely
  static Future<String?> readSecurely(String key) async {
    return await _secureStorage.read(key: key);
  }

  // Delete sensitive data
  static Future<void> deleteSecurely(String key) async {
    await _secureStorage.delete(key: key);
  }

  // Clear all secure storage
  static Future<void> clearAllSecureData() async {
    await _secureStorage.deleteAll();
  }

  // Generate secure API key
  static String generateSecureKey(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  // Validate input to prevent injection attacks
  static bool validateInput(String input) {
    // Basic validation - extend as needed
    final dangerousPatterns = [
      r"<script",
      r"javascript:",
      r"onload=",
      r"onerror=",
      r"SELECT.*FROM",
      r"DROP.*TABLE",
      r"INSERT.*INTO",
      r"UPDATE.*SET",
      r"DELETE.*FROM",
    ];

    for (final pattern in dangerousPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(input)) {
        return false;
      }
    }
    return true;
  }

  // Sanitize input data
  static String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF@.-]'), '') // Keep only safe characters + Arabic
        .trim();
  }
}