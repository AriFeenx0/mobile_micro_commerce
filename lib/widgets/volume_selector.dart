/// วิดเจ็ตเลือกเล่มหนังสือจากรายการที่กำหนด
import 'package:flutter/material.dart';

/// แสดงรายการเล่มและแจ้งค่าที่ผู้ใช้เลือก
class VolumeSelector extends StatelessWidget {
  /// สร้างตัวเลือกเล่มจาก [volumes] พร้อมค่าเริ่มต้นและ callback เมื่อเปลี่ยนค่า
  const VolumeSelector({
    super.key,
    required this.volumes,
    required this.selectedVolume,
    required this.onChanged,
  });

  final List<String> volumes;
  final String? selectedVolume;
  final ValueChanged<String?> onChanged;

  /// สร้างเมนูแบบเลื่อนลงสำหรับเลือกเล่ม
  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selectedVolume,
      items: volumes
          .map((volume) => DropdownMenuItem(value: volume, child: Text(volume)))
          .toList(),
      onChanged: onChanged,
    );
  }
}