/// โมเดลโปรไฟล์ผู้ใช้ บทบาท และข้อมูลบัญชีรับเงิน
import 'package:cloud_firestore/cloud_firestore.dart';

/// บทบาทของผู้ใช้ในระบบ
enum UserRole { customer, owner }

/// แปลงข้อความบทบาทที่จัดเก็บเป็นค่า [UserRole]
UserRole _roleFromString(String value) {
  return value == 'owner' ? UserRole.owner : UserRole.customer;
}

/// แปลงบทบาทผู้ใช้เป็นข้อความสำหรับจัดเก็บ
String _roleToString(UserRole role) {
  return role == UserRole.owner ? 'owner' : 'customer';
}

/// เก็บข้อมูลโปรไฟล์และข้อมูลรับเงินของผู้ใช้
class UserModel {
  final String id; // = Firebase Auth UID, ใช้เป็น Document ID ด้วย
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String address;
  final String? photoUrl;
  final String bankName;
  final String bankAccountNumber;
  final String bankAccountName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// สร้างโมเดลผู้ใช้จากค่าที่กำหนด
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.address = '',
    this.photoUrl,
    this.bankName = '',
    this.bankAccountNumber = '',
    this.bankAccountName = '',
    this.createdAt,
    this.updatedAt,
  });

  /// ระบุว่ามีชื่อธนาคารและเลขบัญชีครบถ้วนหรือไม่
  bool get hasBankAccount =>
      bankName.trim().isNotEmpty && bankAccountNumber.trim().isNotEmpty;

  /// สร้างโมเดลผู้ใช้จากเอกสาร Firestore โดยใช้ [id] เป็น Document ID
  factory UserModel.fromJson(String id, Map<String, dynamic> json) {
    return UserModel(
      id: id,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: _roleFromString(json['role'] as String? ?? 'customer'),
      address: json['address'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      bankName: json['bankName'] as String? ?? '',
      bankAccountNumber: json['bankAccountNumber'] as String? ?? '',
      bankAccountName: json['bankAccountName'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// แปลงโมเดลเป็น Map สำหรับเขียนลง Firestore โดยไม่ซ้ำ Document ID ใน field
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': _roleToString(role),
      'address': address,
      'photoUrl': photoUrl,
      'bankName': bankName,
      'bankAccountNumber': bankAccountNumber,
      'bankAccountName': bankAccountName,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// สร้างสำเนาโดยแทนเฉพาะค่าที่ระบุ และอัปเดตเวลาแก้ไข
  UserModel copyWith({
    String? name,
    String? phone,
    String? address,
    String? photoUrl,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountName,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}