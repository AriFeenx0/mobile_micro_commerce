/// การ์ดสรุปหนังสือสำหรับแสดงในรายการ
import 'package:flutter/material.dart';

/// แสดงชื่อ ผู้แต่ง และราคาของหนังสือ พร้อม callback เมื่อแตะ
class BookCard extends StatelessWidget {
  /// สร้างการ์ดหนังสือและกำหนดการทำงานเมื่อแตะได้ตามต้องการ
  const BookCard({
    super.key,
    required this.title,
    required this.author,
    required this.price,
    this.onTap,
  });

  final String title;
  final String author;
  final String price;
  final VoidCallback? onTap;

  /// สร้างการ์ดสรุปข้อมูลหนังสือ
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(author),
        trailing: Text(price),
        onTap: onTap,
      ),
    );
  }
}