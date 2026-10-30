/// โมเดลสต็อก ราคา และสถานะการจองของหนังสือแต่ละเล่ม
import 'package:cloud_firestore/cloud_firestore.dart';

/// เก็บข้อมูลของเล่มหนังสือและจำนวนสินค้าที่พร้อมขาย
class BookVolumeModel {
  final String id; // volumeId
  final String bookId; // อ้างอิงกลับไป books/{bookId} (เก็บไว้สะดวกตอน query แบบ collectionGroup)
  final int volumeNumber;
  final double price;
  final int stock;
  final String condition; // "ใหม่" | "มือสอง สภาพดี" | "มือสอง พอใช้"
  final bool isSingleCopy; // ติดอัตโนมัติเมื่อ stock เริ่มต้น = 1 (ตาม Flow 12)
  final Map<String, dynamic> reservations;
  final DateTime? lockedUntil;
  final String? lockedByOrderId;
  final DateTime? updatedAt;

  /// สร้างข้อมูลเล่มหนังสือจากค่าที่กำหนด
  BookVolumeModel({
    required this.id,
    required this.bookId,
    required this.volumeNumber,
    required this.price,
    required this.stock,
    required this.condition,
    this.isSingleCopy = false,
    this.reservations = const {},
    this.lockedUntil,
    this.lockedByOrderId,
    this.updatedAt,
  });

  /// รวมจำนวนที่จองไว้ โดยไม่นับรายการชำระเงินที่หมดเวลาแล้ว
  int get reservedQuantity {
    final now = DateTime.now();
    return reservations.values.fold<int>(0, (total, reservation) {
      if (reservation is! Map) return total;
      final quantity = (reservation['quantity'] as num?)?.toInt() ?? 0;
      if (quantity <= 0) return total;

      final status = reservation['status'] as String?;
      final expiresAt = reservation['expiresAt'];
      if (status == 'pendingPayment' && expiresAt is Timestamp) {
        if (!expiresAt.toDate().isAfter(now)) return total;
      }
      return total + quantity;
    });
  }

  /// คืนจำนวนสต็อกที่ยังซื้อได้หลังหักการจองและการล็อกเล่ม
  int get availableStock {
    if (lockedUntil != null && lockedUntil!.isAfter(DateTime.now())) return 0;
    if (stock <= 0) return 0;
    final available = stock - reservedQuantity;
    if (available <= 0) return 0;
    return available >= stock ? stock : available;
  }

  /// ระบุว่ายังมีสต็อกพร้อมขายหรือไม่
  bool get isAvailable => availableStock > 0;

  /// สร้างโมเดลจากข้อมูล Firestore พร้อมระบุรหัสหนังสือและรหัสเล่ม
  factory BookVolumeModel.fromJson(
    String id,
    String bookId,
    Map<String, dynamic> json,
  ) {
    final rawReservations = json['reservations'];
    return BookVolumeModel(
      id: id,
      bookId: bookId,
      volumeNumber: (json['volumeNumber'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      condition: json['condition'] as String? ?? 'ใหม่',
      isSingleCopy: json['isSingleCopy'] as bool? ?? false,
      reservations: rawReservations is Map
          ? Map<String, dynamic>.from(rawReservations)
          : const {},
      lockedUntil: (json['lockedUntil'] as Timestamp?)?.toDate(),
      lockedByOrderId: json['lockedByOrderId'] as String?,
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// แปลงโมเดลเป็น Map สำหรับบันทึกข้อมูลเล่มลง Firestore
  Map<String, dynamic> toJson() {
    return {
      'volumeNumber': volumeNumber,
      'price': price,
      'stock': stock,
      'condition': condition,
      // กติกา: ตั้งค่านี้ตอนสร้าง/แก้ไข volume เท่านั้น ไม่ใช่ตอน checkout
      'isSingleCopy': isSingleCopy,
      'reservations': reservations,
      'lockedUntil': lockedUntil != null ? Timestamp.fromDate(lockedUntil!) : null,
      'lockedByOrderId': lockedByOrderId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}