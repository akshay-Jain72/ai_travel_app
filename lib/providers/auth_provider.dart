import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _userId;
  String? _userName;
  bool _isLoading = false;

  // ✅ NEW: App start par hi storage se token load
  AuthProvider() {
    _loadFromStorage();
  }

  bool get isLoggedIn => _token != null;
  String? get token => _token;
  String? get userId => _userId;
  String? get userName => _userName;
  bool get isLoading => _isLoading;

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final response = await ApiService.post('auth/login', {
        'email': email,
        'password': password,
      });

      if (response['status'] == true) {
        _token = response['token'];
        _userId = response['user']['id'];
        _userName = response['user']['name'];

        // ✅ token + user info ko local storage me save
        await _saveToStorage();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _userName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString('token', _token!);
      if (_userId != null) {
        await prefs.setString('userId', _userId!);
      }
      if (_userName != null) {
        await prefs.setString('userName', _userName!);
      }
    }
  }

  // ✅ NEW: Storage se token/user load (app khulte hi chalega)
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      _userId = prefs.getString('userId');
      _userName = prefs.getString('userName');
      notifyListeners();
    } catch (e) {
      // optional: print error
      debugPrint('Error loading auth data: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
