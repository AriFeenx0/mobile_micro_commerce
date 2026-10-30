/// โมเดลคูปอง ฟังก์ชันแปลงข้อมูล และการคำนวณส่วนลด
import 'package:cloud_firestore/cloud_firestore.dart';

/// ประเภทส่วนลดที่คูปองรองรับ
enum DiscountType { percent, fixed }

/// แปลงค่าประเภทส่วนลดจากข้อมูลที่จัดเก็บเป็น enum
DiscountType _typeFromString(String value) {
  return value == 'fixed' ? DiscountType.fixed : DiscountType.percent;
}

/// แปลงประเภทส่วนลดเป็นค่าข้อความสำหรับจัดเก็บ
String _typeToString(DiscountType type) {
  return type == DiscountType.fixed ? 'fixed' : 'percent';
}

/// เก็บเงื่อนไขการใช้คูปองและคำนวณส่วนลด
class CouponModel {
  final String id;
  final String code;
  final String ownerId;
  final DiscountType discountType;
  final double discountValue;
  final double minOrderAmount;
  final int usageLimit;
  final int usedCount;
  // จำนวนสิทธิ์ที่ถูกจองไว้โดยออเดอร์ที่ยังรอชำระ/รอตรวจสลิป (ยังไม่หมดเวลา)
  final int reservedCount;
  final DateTime? expiresAt;
  final bool isActive;
  final DateTime? createdAt;

  /// สร้างโมเดลคูปองจากค่าที่กำหนด
  CouponModel({
    required this.id,
    required this.code,
    required this.ownerId,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount = 0,
    this.usageLimit = 0, // 0 = ไม่จำกัด
    this.usedCount = 0,
    this.reservedCount = 0,
    this.expiresAt,
    this.isActive = true,
    this.createdAt,
  });

  static final _codePattern = RegExp(r'^[A-Z0-9_-]{3,20}$');

  /// โค้ดคือ Document ID จึงต้องเป็นตัวพิมพ์ใหญ่และไม่มีอักขระต้องห้าม
  /// ตัดช่องว่างและแปลงรหัสคูปองเป็นตัวพิมพ์ใหญ่
  static String normalizeCode(String raw) => raw.trim().toUpperCase();

  /// ตรวจว่ารหัสคูปองมีรูปแบบที่รองรับหรือไม่
  static bool isValidCode(String code) => _codePattern.hasMatch(code);

  /// นับรายการจองคูปองที่ยังมีผล ณ เวลา [now]
  static int activeReservationCount(Object? rawReservations, DateTime now) {
    if (rawReservations is! Map) return 0;
    return rawReservations.values.fold<int>(0, (total, value) {
      if (value is! Map) return total + 1;
      final expiresAt = value['expiresAt'];
      if (value['status'] == 'pendingPayment' &&
          expiresAt is Timestamp &&
          !expiresAt.toDate().isAfter(now)) {
        return total;
      }
      return total + 1;
    });
  }

  /// ระบุว่ายังเหลือโควตาการใช้คูปองหรือไม่
  bool get hasQuotaLeft =>
      usageLimit <= 0 || usedCount + reservedCount < usageLimit;

  /// ระบุว่าคูปองเปิดใช้งาน ยังไม่หมดอายุ และมีโควตาเหลือหรือไม่
  bool get isValidNow {
    if (!isActive) return false;
    if (expiresAt != null && !expiresAt!.isAfter(DateTime.now())) return false;
    return hasQuotaLeft;
  }

  /// คืนเหตุผลที่ใช้คูปองไม่ได้ หรือ `null` หากผ่านเงื่อนไขพื้นฐาน
  String? invalidReason(double orderAmount, {String? shopOwnerId}) {
    if (shopOwnerId != null && ownerId != shopOwnerId) {
      return 'คูปองนี้ใช้กับร้านนี้ไม่ได้';
    }
    if (!isActive) return 'คูปองนี้ถูกปิดใช้งานแล้ว';
    if (expiresAt != null && !expiresAt!.isAfter(DateTime.now())) {
      return 'คูปองหมดอายุแล้ว';
    }
    if (!hasQuotaLeft) return 'คูปองนี้ถูกใช้ครบจำนวนแล้ว';
    if (orderAmount < minOrderAmount) {
      return 'ยอดซื้อต้องถึงขั้นต่ำ ${minOrderAmount.toStringAsFixed(0)} บาท';
    }
    return null;
  }

  /// คำนวณส่วนลดจากยอดสินค้าโดยไม่ให้เกินยอดซื้อ และปัดสองตำแหน่ง
  double discountFor(double orderAmount) {
    final raw = discountType == DiscountType.percent
        ? orderAmount * (discountValue / 100)
        : discountValue;
    final capped = raw > orderAmount ? orderAmount : raw;
    return (capped * 100).round() / 100;
  }

  /// คำนวณส่วนลดหลังตรวจเงื่อนไข และคืนศูนย์เมื่อคูปองใช้ไม่ได้
  double calculateDiscount(double orderAmount) {
    if (invalidReason(orderAmount) != null) return 0;
    return discountFor(orderAmount);
  }

  /// สร้างโมเดลคูปองจากข้อมูล Firestore และนับการจองที่ยังมีผล
  factory CouponModel.fromJson(String id, Map<String, dynamic> json) {
    return CouponModel(
      id: id,
      code: json['code'] as String? ?? id,
      ownerId: json['ownerId'] as String? ?? '',
      discountType: _typeFromString(json['discountType'] as String? ?? 'percent'),
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0,
      minOrderAmount: (json['minOrderAmount'] as num?)?.toDouble() ?? 0,
      usageLimit: (json['usageLimit'] as num?)?.toInt() ?? 0,
      usedCount: (json['usedCount'] as num?)?.toInt() ?? 0,
      reservedCount: activeReservationCount(
        json['reservations'],
        DateTime.now(),
      ),
      expiresAt: (json['expiresAt'] as Timestamp?)?.toDate(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// แปลงคูปองเป็น Map สำหรับบันทึกลง Firestore
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