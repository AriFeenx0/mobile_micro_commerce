/// ชิปข้อความสำหรับแสดงหมวดหมู่หรือป้ายกำกับ
import 'package:flutter/material.dart';

/// แสดงป้ายข้อความในรูปแบบชิป
class TagChip extends StatelessWidget {
  /// สร้างชิปจาก [label]
  const TagChip({super.key, required this.label});

  final String label;

  /// สร้างชิปที่มีข้อความตามป้ายกำกับ
  @override
  Widget build(BuildContext context) => Chip(label: Text(label));
}