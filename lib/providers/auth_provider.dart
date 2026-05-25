import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import 'dart:convert';
class AuthProvider with ChangeNotifier {
  final storage = const FlutterSecureStorage();

  String? _token;
  Map<String, dynamic>? _user;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;

  bool get isAuthenticated => _token != null;

  // ================= LOGIN =================
  Future<bool> login(String identifier, String password) async {
    final data = await ApiService.login(identifier, password);

    if (data["token"] != null) {
      _token = data["token"];
      _user = data["user"];

      await storage.write(key: "token", value: _token);
      await storage.write(key: "user", value: jsonEncode(_user));

      notifyListeners();
      return true;
    }

    return false;
  }

  // ================= REGISTER =================
  Future<bool> register({
    required String name,
    String? email,
    String? phone,
    required String password,
    String? address,
  }) async {
    final data = await ApiService.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      address: address,
    );

    if (data["token"] != null) {
      _token = data["token"];
      _user = data["user"];

      await storage.write(key: "token", value: _token);
      await storage.write(key: "user", value: jsonEncode(_user));

      notifyListeners();
      return true;
    }

    return false;
  }

  // ================= LOAD AU DEMARRAGE =================
  Future<void> loadUser() async {
    _token = await storage.read(key: "token");

    final userData = await storage.read(key: "user");
    if (userData != null) {
      _user = jsonDecode(userData);
    }

    notifyListeners();
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    try {
      await ApiService.logout(_token); // 🔥 appel backend
    } catch (_) {}

    _token = null;
    _user = null;

    await storage.delete(key: "token");
    await storage.delete(key: "user");

    notifyListeners();
  }
}