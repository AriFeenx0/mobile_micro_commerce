// สร้าง payload QR PromptPay (EMVCo / Thai QR Payment) แบบกำหนดยอดเงิน
class PromptPay {
  const PromptPay._();

  // เบอร์โทร 10 หลัก, เลขบัตรประชาชน/นิติบุคคล 13 หลัก หรือ e-Wallet 15 หลัก
  static String payload(String id, {double? amount}) {
    final digits = id.replaceAll(RegExp(r'\D'), '');
    final String target;
    final String targetType;
    if (digits.length >= 15) {
      targetType = '03';
      target = digits;
    } else if (digits.length >= 13) {
      targetType = '02';
      target = digits;
    } else {
      targetType = '01';
      final local = digits.startsWith('0') ? digits.substring(1) : digits;
      target = '0066$local';
    }

    final merchant = _tlv('00', 'A000000677010111') + _tlv(targetType, target);
    final fields = StringBuffer()
      ..write(_tlv('00', '01'))
      ..write(_tlv('01', amount == null ? '11' : '12'))
      ..write(_tlv('29', merchant))
      ..write(_tlv('53', '764'))
      ..write(amount == null ? '' : _tlv('54', amount.toStringAsFixed(2)))
      ..write(_tlv('58', 'TH'))
      ..write('6304');
    final body = fields.toString();
    return body + _crc16(body);
  }

  static String _tlv(String tag, String value) =>
      '$tag${value.length.toString().padLeft(2, '0')}$value';

  // CRC-16/CCITT-FALSE
  static String _crc16(String data) {
    var crc = 0xFFFF;
    for (final unit in data.codeUnits) {
      crc ^= unit << 8;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 0x8000) != 0 ? (crc << 1) ^ 0x1021 : crc << 1;
        crc &= 0xFFFF;
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}
