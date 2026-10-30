/// การ์ดแสดงค่าตัวชี้วัดพร้อมไอคอน
import 'package:flutter/material.dart';

/// แสดงชื่อ ค่า และไอคอนของตัวชี้วัดหนึ่งรายการ
class StatCard extends StatelessWidget {
  /// สร้างการ์ดจากชื่อ ค่า และไอคอนที่ต้องการแสดง
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  /// สร้างการ์ดตัวชี้วัด
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}