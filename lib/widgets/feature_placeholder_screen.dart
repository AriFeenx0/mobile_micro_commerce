/// หน้าตัวอย่างสำหรับฟีเจอร์ที่ยังไม่พร้อมใช้งาน
import 'package:flutter/material.dart';

/// แสดงชื่อหน้าและข้อความแจ้งสถานะของฟีเจอร์
class FeaturePlaceholderScreen extends StatelessWidget {
  /// สร้างหน้าตัวอย่างด้วยชื่อ [title] และข้อความ [message]
  const FeaturePlaceholderScreen({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  /// สร้างหน้าพร้อมแถบชื่อและข้อความกลางหน้า
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(message)),
    );
  }
}