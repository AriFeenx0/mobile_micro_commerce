/// จัดการสถานะการเข้าสู่ระบบและโปรไฟล์ที่ UI ใช้
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  /// สร้างสถานะเริ่มต้นและติดตามการเปลี่ยนแปลงการเข้าสู่ระบบ
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

  /// โปรไฟล์ของผู้ใช้ที่เข้าสู่ระบบ
  UserModel? get profile => _profile;

  /// ข้อผิดพลาดล่าสุดระหว่างโหลดโปรไฟล์
  Object? get error => _error;

  /// สถานะการโหลดโปรไฟล์
  bool get isLoading => _isLoading;

  /// ระบุว่ามีผู้ใช้ Firebase เข้าสู่ระบบอยู่หรือไม่
  bool get isSignedIn => _authService.currentFirebaseUser != null;

  /// โหลดโปรไฟล์ใหม่เมื่อสถานะผู้ใช้เปลี่ยน โดยละเว้นคำขอเก่าที่เสร็จช้า
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

  /// โหลดสถานะโปรไฟล์จากผู้ใช้ Firebase ปัจจุบันอีกครั้ง
  Future<void> reload() async {
    await _handleAuthChange(_authService.currentFirebaseUser);
  }

  /// บันทึกข้อมูลติดต่อของโปรไฟล์ผู้ใช้ปัจจุบัน
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

  /// บันทึกบัญชีรับเงินและอัปเดตโปรไฟล์ในสถานะ
  Future<void> updateBankAccount({
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    _profile = await _authService.updateBankAccount(
      bankName: bankName,
      accountNumber: accountNumber,
      accountName: accountName,
    );
    _error = null;
    notifyListeners();
  }

  /// ออกจากระบบผ่านบริการยืนยันตัวตน
  Future<void> signOut() => _authService.signOut();

  /// ยกเลิกการติดตามและทำให้คำขอโหลดที่ค้างอยู่ใช้ผลไม่ได้
  @override
  void dispose() {
    _requestId++;
    _subscription.cancel();
    super.dispose();
  }
}
