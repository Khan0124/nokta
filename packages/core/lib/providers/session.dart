import 'package:flutter/material.dart';
import 'package:nokta_pos/models/user.dart';

class Session with ChangeNotifier {
  User? _current;
  String? _token;
  String? _tenantId;

  User? get current => _current;
  String? get token => _token;
  bool get isManager => _current?.role == 'manager';
  bool get isLoggedIn => _current != null;

  Future<void> login(User user, String token, String tenantId) async {
    _current = user;
    _token = token;
    _tenantId = tenantId;
    notifyListeners();
  }

  Future<void> logout() async {
    _current = null;
    _token = null;
    _tenantId = null;
    notifyListeners();
  }
}