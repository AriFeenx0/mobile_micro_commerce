// จัดการสถานะการเข้าสู่ระบบและโปรไฟล์ที่ UI ใช้
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService() {
    _subscription = _authService.authStateChanges.listen(_handleAuthChange);
  }

  final AuthService _authService;
  late final StreamSubscription<User?> _subscription;

  UserModel? _profile;
  Object? _error;
  bool _isLoading = true;
  int _requestId = 0;

  UserModel? get profile => _profile;
  Object? get error => _error;
  bool get isLoading => _isLoading;
  bool get isSignedIn => _authService.currentFirebaseUser != null;

  Future<void> _handleAuthChange(User? user) async {
    final requestId = ++_requestId;
    if (user == null) {
      _profile = null;
      _error = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final profile = await _authService.getCurrentUserProfile();
      if (requestId != _requestId) return;
      _profile = profile;
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      if (requestId != _requestId) return;
      _error = error;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reload() async {
    await _handleAuthChange(_authService.currentFirebaseUser);
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String address,
  }) async {
    final updatedProfile = await _authService.updateCurrentUserProfile(
      name: name,
      phone: phone,
      address: address,
    );
    _profile = updatedProfile;
    _error = null;
    notifyListeners();
  }

  Future<void> signOut() => _authService.signOut();

  @override
  void dispose() {
    _requestId++;
    _subscription.cancel();
    super.dispose();
  }
}
