import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { customer, owner }

UserRole _roleFromString(String value) {
  return value == 'owner' ? UserRole.owner : UserRole.customer;
}

String _roleToString(UserRole role) {
  return role == UserRole.owner ? 'owner' : 'customer';
}

class UserModel {
  final String id; // = Firebase Auth UID, ใช้เป็น Document ID ด้วย
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String address;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.address = '',
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// สร้าง UserModel จาก Firestore document
  /// ใช้แบบ: UserModel.fromJson(doc.id, doc.data()!)
  factory UserModel.fromJson(String id, Map<String, dynamic> json) {
    return UserModel(
      id: id,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: _roleFromString(json['role'] as String? ?? 'customer'),
      address: json['address'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// แปลงกลับเป็น Map สำหรับเขียนลง Firestore
  /// หมายเหตุ: ไม่ใส่ 'id' เพราะ id คือ Document ID อยู่แล้ว ไม่ต้องซ้ำใน field
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': _roleToString(role),
      'address': address,
      'photoUrl': photoUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? address,
    String? photoUrl,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}