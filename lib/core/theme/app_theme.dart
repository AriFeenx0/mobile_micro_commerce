/// กำหนดธีมหลักที่ใช้ร่วมกันภายในแอป
import 'package:flutter/material.dart';

abstract final class AppTheme {
  /// คืนค่าธีมสว่างพร้อมชุดสีหลักของแอป
  static ThemeData get light => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF236B5A)),
        useMaterial3: true,
      );
}