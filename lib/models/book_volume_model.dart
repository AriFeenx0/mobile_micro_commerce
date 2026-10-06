// โมเดลสต็อกและรายละเอียดของหนังสือแต่ละเล่ม
import 'package:cloud_firestore/cloud_firestore.dart';

class BookVolumeModel {
  final String id; // volumeId
  final String bookId; // อ้างอิงกลับไป books/{bookId} (เก็บไว้สะดวกตอน query แบบ collectionGroup)
  final int volumeNumber;
  final double price;
  final int stock;
  final String condition; // "ใหม่" | "มือสอง สภาพดี" | "มือสอง พอใช้"
  final bool isSingleCopy; // ติดอัตโนมัติเมื่อ stock เริ่มต้น = 1 (ตาม Flow 12)
  final DateTime? lockedUntil; // เวลาสิ้นสุดการล็อกสต๊อกชั่วคราว (15 นาที)
  final String? lockedByOrderId;
  final DateTime? updatedAt;

  BookVolumeModel({
    required this.id,
    required this.bookId,
    required this.volumeNumber,
    required this.price,
    required this.stock,
    required this.condition,
    this.isSingleCopy = false,
    this.lockedUntil,
    this.lockedByOrderId,
    this.updatedAt,
  });

  /// true เมื่อยังซื้อได้ (มีสต๊อก และไม่ได้ถูกล็อกไว้โดยออเดอร์อื่น หรือการล็อกหมดอายุแล้ว)
  bool get isAvailable {
    if (stock <= 0) return false;
    if (lockedUntil == null) return true;
    return DateTime.now().isAfter(lockedUntil!);
  }

  factory BookVolumeModel.fromJson(String id, String bookId, Map<String, dynamic> json) {
    return BookVolumeModel(
      id: id,
      bookId: bookId,
      volumeNumber: (json['volumeNumber'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      condition: json['condition'] as String? ?? 'ใหม่',
      isSingleCopy: json['isSingleCopy'] as bool? ?? false,
      lockedUntil: (json['lockedUntil'] as Timestamp?)?.toDate(),
      lockedByOrderId: json['lockedByOrderId'] as String?,
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'volumeNumber': volumeNumber,
      'price': price,
      'stock': stock,
      'condition': condition,
      // กติกา: ตั้งค่านี้ตอนสร้าง/แก้ไข volume เท่านั้น ไม่ใช่ตอน checkout
      'isSingleCopy': isSingleCopy,
      'lockedUntil': lockedUntil != null ? Timestamp.fromDate(lockedUntil!) : null,
      'lockedByOrderId': lockedByOrderId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}