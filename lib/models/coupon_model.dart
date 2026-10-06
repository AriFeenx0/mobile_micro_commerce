// โมเดลคูปองและการคำนวณส่วนลด
import 'package:cloud_firestore/cloud_firestore.dart';

enum DiscountType { percent, fixed }

DiscountType _typeFromString(String value) {
  return value == 'fixed' ? DiscountType.fixed : DiscountType.percent;
}

String _typeToString(DiscountType type) {
  return type == DiscountType.fixed ? 'fixed' : 'percent';
}

class CouponModel {
  final String id;
  final String code;
  final String ownerId;
  final DiscountType discountType;
  final double discountValue;
  final double minOrderAmount;
  final int usageLimit;
  final int usedCount;
  final DateTime? expiresAt;
  final bool isActive;
  final DateTime? createdAt;

  CouponModel({
    required this.id,
    required this.code,
    required this.ownerId,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount = 0,
    this.usageLimit = 0, // 0 = ไม่จำกัด
    this.usedCount = 0,
    this.expiresAt,
    this.isActive = true,
    this.createdAt,
  });

  bool get isValidNow {
    if (!isActive) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    if (usageLimit > 0 && usedCount >= usageLimit) return false;
    return true;
  }

  /// คำนวณส่วนลดจากยอดซื้อ คืนค่า 0 ถ้าใช้ไม่ได้หรือไม่ถึงขั้นต่ำ
  double calculateDiscount(double orderAmount) {
    if (!isValidNow || orderAmount < minOrderAmount) return 0;
    if (discountType == DiscountType.percent) {
      return orderAmount * (discountValue / 100);
    }
    return discountValue > orderAmount ? orderAmount : discountValue;
  }

  factory CouponModel.fromJson(String id, Map<String, dynamic> json) {
    return CouponModel(
      id: id,
      code: json['code'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      discountType: _typeFromString(json['discountType'] as String? ?? 'percent'),
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0,
      minOrderAmount: (json['minOrderAmount'] as num?)?.toDouble() ?? 0,
      usageLimit: (json['usageLimit'] as num?)?.toInt() ?? 0,
      usedCount: (json['usedCount'] as num?)?.toInt() ?? 0,
      expiresAt: (json['expiresAt'] as Timestamp?)?.toDate(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'ownerId': ownerId,
      'discountType': _typeToString(discountType),
      'discountValue': discountValue,
      'minOrderAmount': minOrderAmount,
      'usageLimit': usageLimit,
      'usedCount': usedCount,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isActive': isActive,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}