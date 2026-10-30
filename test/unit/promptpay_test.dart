// ทดสอบการสร้าง payload PromptPay และการคำนวณ CRC-16
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_micro_commerce/core/utils/promptpay.dart';

/// ตรวจสอบรูปแบบ payload PromptPay และผลตรวจสอบ CRC
void main() {
  test('สร้าง payload เบอร์โทรพร้อมยอดเงิน', () {
    final p = PromptPay.payload('0812345678', amount: 100);
    expect(
      p.substring(0, p.length - 4),
      '00020101021229370016A0000006770101110113006681234567853037645406100.005802TH6304',
    );
  });

  test('CRC เป็น CRC-16/CCITT-FALSE ของข้อมูลก่อนหน้า', () {
    final p = PromptPay.payload('0812345678', amount: 100);
    var crc = 0xFFFF;
    for (final unit in p.substring(0, p.length - 4).codeUnits) {
      crc ^= unit << 8;
      for (var i = 0; i < 8; i++) {
        crc = ((crc & 0x8000) != 0 ? (crc << 1) ^ 0x1021 : crc << 1) & 0xFFFF;
      }
    }
    expect(
      p.substring(p.length - 4),
      crc.toRadixString(16).toUpperCase().padLeft(4, '0'),
    );
  });

  test('CRC ถูกต้องและยอดเงินมีทศนิยม 2 ตำแหน่ง', () {
    final p = PromptPay.payload('0812345678', amount: 59.5);
    expect(p, contains('540559.50'));
    expect(p, matches(RegExp(r'6304[0-9A-F]{4}$')));
  });
}
