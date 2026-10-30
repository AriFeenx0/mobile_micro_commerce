/// จัดการการเข้าสู่ระบบและโปรไฟล์ผู้ใช้ผ่าน Firebase
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class AuthService {
  /// ตั้งค่าแหล่ง Firebase โดยรองรับการส่ง dependency เข้ามาทดสอบ
  AuthService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _auth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  static const String usersCollection = 'users';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// คอลเลกชัน Firestore ที่เก็บโปรไฟล์ผู้ใช้
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(usersCollection);

  /// ผู้ใช้ Firebase ที่กำลังเข้าสู่ระบบ
  User? get currentFirebaseUser => _auth.currentUser;

  /// สตรีมการเปลี่ยนแปลงสถานะการเข้าสู่ระบบ
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// สร้างบัญชี Firebase และบันทึกโปรไฟล์ลูกค้าใน Firestore
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String phone = '',
    String address = '',
    String? photoUrl,
  }) async {
    final normalizedEmail = email.trim();
    final normalizedName = name.trim();
    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw StateError('Firebase did not return the newly created user.');
    }

    await firebaseUser.updateDisplayName(normalizedName);

    final user = UserModel(
      id: firebaseUser.uid,
      name: normalizedName,
      email: firebaseUser.email ?? normalizedEmail,
      phone: phone.trim(),
      role: UserRole.customer,
      address: address.trim(),
      photoUrl: photoUrl ?? firebaseUser.photoURL,
      createdAt: DateTime.now(),
    );

    await _users.doc(firebaseUser.uid).set(user.toJson());
    return user;
  }

  /// เข้าสู่ระบบและคืนโปรไฟล์ Firestore หรือข้อมูลพื้นฐานจาก Firebase
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw StateError('Firebase did not return the signed-in user.');
    }

    return await getUserProfile(firebaseUser.uid) ??
        _userModelFromFirebaseUser(firebaseUser);
  }

  /// อ่านโปรไฟล์ของผู้ใช้ที่กำลังเข้าสู่ระบบ
  Future<UserModel?> getCurrentUserProfile() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    return await getUserProfile(firebaseUser.uid) ??
        _userModelFromFirebaseUser(firebaseUser);
  }

  /// อ่านโปรไฟล์จาก Firestore ด้วยรหัสผู้ใช้
  Future<UserModel?> getUserProfile(String uid) async {
    final document = await _users.doc(uid).get();
    final data = document.data();
    if (!document.exists || data == null) return null;

    return UserModel.fromJson(document.id, data);
  }

  /// บันทึกชื่อ เบอร์โทร และที่อยู่ของผู้ใช้ปัจจุบัน
  Future<UserModel> updateCurrentUserProfile({
    required String name,
    required String phone,
    required String address,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw StateError('กรุณาเข้าสู่ระบบก่อนแก้ไขโปรไฟล์');
    }

    final currentProfile =
        await getUserProfile(firebaseUser.uid) ??
        _userModelFromFirebaseUser(firebaseUser);
    final updatedProfile = currentProfile.copyWith(
      name: name.trim(),
      phone: phone.trim(),
      address: address.trim(),
    );

    await firebaseUser.updateDisplayName(updatedProfile.name);
    await _users
        .doc(firebaseUser.uid)
        .set(updatedProfile.toJson(), SetOptions(merge: true));
    return updatedProfile;
  }

  /// อัปเดตบัญชีรับเงินของเจ้าของร้านที่เข้าสู่ระบบ
  Future<UserModel> updateBankAccount({
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw StateError('กรุณาเข้าสู่ระบบก่อนแก้ไขบัญชีรับเงิน');
    }
    final currentProfile = await getUserProfile(firebaseUser.uid);
    if (currentProfile == null || currentProfile.role != UserRole.owner) {
      throw StateError('เฉพาะเจ้าของร้านเท่านั้นที่แก้ไขบัญชีรับเงินได้');
    }

    final updatedProfile = currentProfile.copyWith(
      bankName: bankName.trim(),
      bankAccountNumber: accountNumber.trim(),
      bankAccountName: accountName.trim(),
    );
    await _users.doc(firebaseUser.uid).set(
      updatedProfile.toJson(),
      SetOptions(merge: true),
    );
    return updatedProfile;
  }

  /// ส่งอีเมลสำหรับตั้งรหัสผ่านใหม่
  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  /// ออกจากระบบ Firebase
  Future<void> signOut() => _auth.signOut();

  /// สร้างโปรไฟล์ลูกค้าพื้นฐานจากข้อมูล Firebase Auth
  UserModel _userModelFromFirebaseUser(User firebaseUser) => UserModel(
    id: firebaseUser.uid,
    name: firebaseUser.displayName ?? '',
    email: firebaseUser.email ?? '',
    phone: firebaseUser.phoneNumber ?? '',
    role: UserRole.customer,
    photoUrl: firebaseUser.photoURL,
  );
}
