// สร้าง จัดการ และตรวจคูปองผ่าน Firestore โดยใช้โค้ดคูปองเป็น Document ID
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/coupon_model.dart';

class CouponService {
  CouponService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  static const String couponsCollection = 'coupons';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _coupons =>
      _firestore.collection(couponsCollection);

  /// ค้นหาด้วย Document ID ตรงๆ ไม่ต้อง query ด้วย field
  Future<CouponModel?> findByCode(String rawCode) async {
    final code = CouponModel.normalizeCode(rawCode);
    if (!CouponModel.isValidCode(code)) return null;
    final snapshot = await _coupons.doc(code).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return CouponModel.fromJson(snapshot.id, data);
  }

  /// ตรวจคูปองเพื่อแสดงตัวอย่างส่วนลดที่หน้า checkout
  /// การตรวจจริงและการจองสิทธิ์เกิดใน OrderService.reserveOrder
  Future<CouponModel> validateForCheckout({
    required String rawCode,
    required String shopOwnerId,
    required double subtotal,
  }) async {
    final coupon = await findByCode(rawCode);
    if (coupon == null) throw StateError('ไม่พบคูปองนี้');
    final reason = coupon.invalidReason(subtotal, shopOwnerId: shopOwnerId);
    if (reason != null) throw StateError(reason);
    return coupon;
  }

  Stream<List<CouponModel>> watchCouponsForOwner(String ownerId) {
    return _coupons.where('ownerId', isEqualTo: ownerId).snapshots().map((
      snapshot,
    ) {
      final coupons = snapshot.docs
          .map((doc) => CouponModel.fromJson(doc.id, doc.data()))
          .toList();
      coupons.sort(
        (a, b) =>
            (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()),
      );
      return coupons;
    });
  }

  Future<void> createCoupon({
    required String rawCode,
    required DiscountType discountType,
    required double discountValue,
    double minOrderAmount = 0,
    int usageLimit = 0,
    DateTime? expiresAt,
  }) async {
    final owner = await _requireShopOwner();
    final code = CouponModel.normalizeCode(rawCode);
    if (!CouponModel.isValidCode(code)) {
      throw ArgumentError(
        'โค้ดต้องมี 3-20 ตัว ใช้ได้เฉพาะ A-Z 0-9 _ -',
      );
    }
    if (discountValue <= 0 ||
        (discountType == DiscountType.percent && discountValue > 100)) {
      throw ArgumentError('มูลค่าส่วนลดไม่ถูกต้อง');
    }
    if (minOrderAmount < 0 || usageLimit < 0) {
      throw ArgumentError('ยอดขั้นต่ำหรือจำนวนครั้งที่ใช้ได้ไม่ถูกต้อง');
    }
    if (expiresAt != null && !expiresAt.isAfter(DateTime.now())) {
      throw ArgumentError('วันหมดอายุต้องเป็นเวลาในอนาคต');
    }

    final reference = _coupons.doc(code);
    final coupon = CouponModel(
      id: code,
      code: code,
      ownerId: owner.uid,
      discountType: discountType,
      discountValue: discountValue,
      minOrderAmount: minOrderAmount,
      usageLimit: usageLimit,
      expiresAt: expiresAt,
    );

    // Document ID ซ้ำไม่ได้อยู่แล้ว แต่ตรวจใน transaction เพื่อไม่ให้เขียนทับโค้ดเดิม
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) throw StateError('โค้ดนี้ถูกใช้แล้ว');
      transaction.set(reference, coupon.toJson());
    });
  }

  Future<void> setActive(String code, bool isActive) async {
    final owner = await _requireShopOwner();
    final reference = _coupons.doc(code);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (snapshot.data()?['ownerId'] != owner.uid) {
        throw StateError('ไม่สามารถแก้ไขคูปองของร้านอื่นได้');
      }
      transaction.update(reference, {
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<User> _requireShopOwner() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('กรุณาเข้าสู่ระบบก่อนจัดการคูปอง');
    final profile = await _firestore.collection('users').doc(user.uid).get();
    if (profile.data()?['role'] != 'owner') {
      throw StateError('บัญชีนี้ไม่มีสิทธิ์จัดการคูปอง');
    }
    return user;
  }
}
