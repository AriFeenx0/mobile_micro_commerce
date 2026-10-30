import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_micro_commerce/core/utils/promptpay.dart';
import 'package:mobile_micro_commerce/models/book_model.dart';
import 'package:mobile_micro_commerce/models/book_volume_model.dart';
import 'package:mobile_micro_commerce/models/coupon_model.dart';

void main() {
  group('Test Case: BookModel', () {
    // ตรวจสอบว่าข้อมูลหลักของหนังสือถูกอ่านจาก JSON และผูกกับ ID ที่ระบุ
    test('แปลงข้อมูลหนังสือจาก JSON ได้ถูกต้อง', () {
      final book = BookModel.fromJson('book_1', {
        'title': 'Flutter เบื้องต้น',
        'author': 'สมชาย',
        'publisher': 'สำนักพิมพ์ตัวอย่าง',
        'coverType': 'ปกแข็ง',
        'language': 'ไทย',
        'category': ['เทคโนโลยี'],
        'ownerId': 'owner_1',
      });

      expect(book.id, 'book_1');
      expect(book.title, 'Flutter เบื้องต้น');
      expect(book.author, 'สมชาย');
      expect(book.category, ['เทคโนโลยี']);
    });

    // ตรวจสอบว่าฟิลด์ที่ไม่มีข้อมูลได้รับค่าเริ่มต้นตามที่โมเดลกำหนด
    test('ใช้ค่าเริ่มต้นเมื่อข้อมูลหนังสือบางฟิลด์ไม่มี', () {
      final book = BookModel.fromJson('book_2', {});

      expect(book.title, isEmpty);
      expect(book.coverType, 'ปกอ่อน');
      expect(book.language, 'ไทย');
      expect(book.volumeCount, 1);
      expect(book.category, isEmpty);
    });
  });

  group('Test Case: BookVolumeModel', () {
    // ตรวจสอบว่าสต็อกที่ไม่มีการจองพร้อมขายได้ครบตามจำนวน
    test('คำนวณจำนวนสต็อกที่พร้อมขายเมื่อไม่มีรายการจอง', () {
      final volume = BookVolumeModel(
        id: 'volume_1',
        bookId: 'book_1',
        volumeNumber: 1,
        price: 120,
        stock: 5,
        condition: 'ใหม่',
      );

      expect(volume.availableStock, 5);
      expect(volume.isAvailable, isTrue);
    });

    // ตรวจสอบว่ารายการจองที่ยังมีผลถูกหักออกจากสต็อกพร้อมขาย
    test('หักจำนวนจองที่ยังมีผลออกจากสต็อก', () {
      final volume = BookVolumeModel(
        id: 'volume_1',
        bookId: 'book_1',
        volumeNumber: 1,
        price: 120,
        stock: 5,
        condition: 'ใหม่',
        reservations: {
          'order_1': {'quantity': 2, 'status': 'pendingSlipReview'},
        },
      );

      expect(volume.reservedQuantity, 2);
      expect(volume.availableStock, 3);
    });

    // ตรวจสอบว่าล็อกสต็อกที่ยังไม่หมดเวลาทำให้สินค้าไม่พร้อมขาย
    test('ไม่พร้อมขายเมื่อสต็อกถูกล็อกอยู่', () {
      final volume = BookVolumeModel(
        id: 'volume_1',
        bookId: 'book_1',
        volumeNumber: 1,
        price: 120,
        stock: 5,
        condition: 'ใหม่',
        lockedUntil: DateTime.now().add(const Duration(minutes: 5)),
      );

      expect(volume.availableStock, 0);
      expect(volume.isAvailable, isFalse);
    });
  });

  group('Test Case: CouponModel', () {
    CouponModel coupon({
      DiscountType type = DiscountType.percent,
      double value = 10,
      double minOrderAmount = 0,
      String ownerId = 'owner_1',
    }) => CouponModel(
      id: 'SAVE10',
      code: 'SAVE10',
      ownerId: ownerId,
      discountType: type,
      discountValue: value,
      minOrderAmount: minOrderAmount,
    );

    // ตรวจสอบการตัดช่องว่าง แปลงเป็นตัวพิมพ์ใหญ่ และตรวจรูปแบบรหัสคูปอง
    test('ปรับรูปแบบและตรวจสอบรหัสคูปอง', () {
      expect(CouponModel.normalizeCode(' save10 '), 'SAVE10');
      expect(CouponModel.isValidCode('SAVE10'), isTrue);
      expect(CouponModel.isValidCode('SAVE 10'), isFalse);
    });

    // ตรวจสอบการคำนวณส่วนลดแบบเปอร์เซ็นต์จากยอดซื้อ
    test('คำนวณส่วนลดแบบเปอร์เซ็นต์', () {
      expect(coupon(value: 10).discountFor(250), 25);
    });

    // ตรวจสอบว่าส่วนลดแบบจำนวนเงินไม่มากกว่ายอดซื้อ
    test('จำกัดส่วนลดแบบจำนวนเงินไม่ให้เกินยอดซื้อ', () {
      expect(coupon(type: DiscountType.fixed, value: 100).discountFor(60), 60);
    });

    // ตรวจสอบว่าคูปองถูกปฏิเสธเมื่อใช้ผิดร้านหรือยอดซื้อไม่ถึงขั้นต่ำ
    test('ปฏิเสธคูปองเมื่อร้านไม่ตรงหรือยอดไม่ถึงขั้นต่ำ', () {
      expect(
        coupon(ownerId: 'owner_1').invalidReason(100, shopOwnerId: 'owner_2'),
        isNotNull,
      );
      expect(coupon(minOrderAmount: 300).invalidReason(100), isNotNull);
    });
  });

  // ตรวจสอบรูปแบบยอดเงินสองตำแหน่งทศนิยมและ CRC ท้าย PromptPay payload
  test('สร้าง PromptPay payload พร้อมยอดเงินสองตำแหน่งทศนิยม', () {
    final payload = PromptPay.payload('0812345678', amount: 59.5);

    expect(payload, contains('540559.50'));
    expect(payload, matches(RegExp(r'6304[0-9A-F]{4}$')));
  });
}
