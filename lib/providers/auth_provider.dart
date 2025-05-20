import 'dart:developer';
import 'package:flutter/material.dart';
import '../repositories/frappe_repository.dart';
import '../services/dio_service.dart';
import '../services/logger_service.dart';

class AuthProvider with ChangeNotifier {
  static final AuthProvider _instance = AuthProvider._internal();

  factory AuthProvider() => _instance;

  AuthProvider._internal();

  final FrappeRepository _frappeRepository = FrappeRepository(
    DioService.instance.client,
  );

  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  Future<bool> login(String email, String password) async {
    try {
      final success = await _frappeRepository.login(email, password);
      if (success) {
        _isLoggedIn = true;
        // Notify listeners about the state change
        notifyListeners();
        return true;
      }
    } catch (e) {
      logger.error('Login failed: ${e.toString()}', error: e);
      return false;
    }
    return false;
  }

  Future<void> logout() async {
    logger.info('Logging out');
    await _frappeRepository.logout();
    _isLoggedIn = false;
    notifyListeners();
  }
}
