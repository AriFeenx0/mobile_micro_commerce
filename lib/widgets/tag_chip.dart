// ชิปข้อความสำหรับแสดงหมวดหมู่หรือป้ายกำกับ
import 'package:flutter/material.dart';

class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Chip(label: Text(label));
}