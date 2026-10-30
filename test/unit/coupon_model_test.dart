// ทดสอบการสร้างคูปอง การตรวจสอบเงื่อนไข และการคำนวณส่วนลด
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_micro_commerce/models/coupon_model.dart';

/// สร้างคูปองตัวอย่างโดยกำหนดเฉพาะค่าที่ต้องการทดสอบ
CouponModel _coupon({
  DiscountType type = DiscountType.percent,
  double value = 10,
  double min = 0,
  int limit = 0,
  int used = 0,
  int reserved = 0,
  DateTime? expiresAt,
  bool active = true,
}) => CouponModel(
  id: 'BOOK50',
  code: 'BOOK50',
  ownerId: 'owner1',
  discountType: type,
  discountValue: value,
  minOrderAmount: min,
  usageLimit: limit,
  usedCount: used,
  reservedCount: reserved,
  expiresAt: expiresAt,
  isActive: active,
);

/// จัดกลุ่มการทดสอบกฎและการคำนวณของคูปอง
void main() {
  test('normalizeCode / isValidCode', () {
    expect(CouponModel.normalizeCode(' book50 '), 'BOOK50');
    expect(CouponModel.isValidCode('BOOK50'), isTrue);
    expect(CouponModel.isValidCode('ab'), isFalse);
    expect(CouponModel.isValidCode('BOOK 50'), isFalse);
  });

  test('discountFor percent, fixed and cap at subtotal', () {
    expect(_coupon(value: 10).discountFor(250), 25);
    expect(_coupon(type: DiscountType.fixed, value: 50).discountFor(200), 50);
    expect(_coupon(type: DiscountType.fixed, value: 50).discountFor(30), 30);
  });

  test('invalidReason checks every rule', () {
    expect(_coupon().invalidReason(100, shopOwnerId: 'owner1'), isNull);
    expect(_coupon().invalidReason(100, shopOwnerId: 'other'), isNotNull);
    expect(_coupon(active: false).invalidReason(100), isNotNull);
    expect(_coupon(min: 300).invalidReason(100), isNotNull);
    expect(
      _coupon(
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      ).invalidReason(100),
      isNotNull,
    );
  });

  test('quota counts used and reserved', () {
    expect(_coupon(limit: 3, used: 1, reserved: 1).hasQuotaLeft, isTrue);
    expect(_coupon(limit: 3, used: 2, reserved: 1).hasQuotaLeft, isFalse);
    expect(_coupon(limit: 0, used: 99).hasQuotaLeft, isTrue);
  });

  test('activeReservationCount skips expired pendingPayment only', () {
    final now = DateTime(2026, 1, 1, 12);
    final reservations = {
      'a': {
        'status': 'pendingPayment',
        'expiresAt': Timestamp.fromDate(
          now.subtract(const Duration(minutes: 1)),
        ),
      },
      'b': {
        'status': 'pendingPayment',
        'expiresAt': Timestamp.fromDate(now.add(const Duration(minutes: 5))),
      },
      'c': {'status': 'pendingSlipReview', 'expiresAt': null},
    };
    expect(CouponModel.activeReservationCount(reservations, now), 2);
    expect(CouponModel.activeReservationCount(null, now), 0);
  });
}
