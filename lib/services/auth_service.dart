// จัดการการเข้าสู่ระบบและโปรไฟล์ผู้ใช้ผ่าน Firebase
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _auth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  static const String usersCollection = 'users';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(usersCollection);

  User? get currentFirebaseUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

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

  Future<UserModel?> getCurrentUserProfile() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    return await getUserProfile(firebaseUser.uid) ??
        _userModelFromFirebaseUser(firebaseUser);
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final document = await _users.doc(uid).get();
    final data = document.data();
    if (!document.exists || data == null) return null;

    return UserModel.fromJson(document.id, data);
  }

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

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() => _auth.signOut();

  UserModel _userModelFromFirebaseUser(User firebaseUser) => UserModel(
    id: firebaseUser.uid,
    name: firebaseUser.displayName ?? '',
    email: firebaseUser.email ?? '',
    phone: firebaseUser.phoneNumber ?? '',
    role: UserRole.customer,
    photoUrl: firebaseUser.photoURL,
  );
}
