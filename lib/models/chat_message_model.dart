/// โมเดลห้องแชทและข้อความ พร้อมการแปลงข้อมูล Firestore
import 'package:cloud_firestore/cloud_firestore.dart';

/// เก็บข้อมูลผู้ร่วมสนทนาและสถานะล่าสุดของห้องแชท
class ChatRoomModel {
  final String id; // แนะนำ: '${customerId}_${ownerId}' กันห้องซ้ำ
  final List<String> participants;
  final String? bookId;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCount; // key = userId
  final DateTime? createdAt;

  /// สร้างโมเดลห้องแชทจากค่าที่กำหนด
  ChatRoomModel({
    required this.id,
    required this.participants,
    this.bookId,
    this.lastMessage = '',
    this.lastMessageAt,
    this.unreadCount = const {},
    this.createdAt,
  });

  /// สร้างรหัสห้องแชทจากรหัสลูกค้าและเจ้าของร้าน
  static String buildRoomId(String customerId, String ownerId) {
    return '${customerId}_$ownerId';
  }

  /// สร้างโมเดลห้องแชทจากข้อมูล Firestore
  factory ChatRoomModel.fromJson(String id, Map<String, dynamic> json) {
    return ChatRoomModel(
      id: id,
      participants: List<String>.from(json['participants'] as List? ?? []),
      bookId: json['bookId'] as String?,
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageAt: (json['lastMessageAt'] as Timestamp?)?.toDate(),
      unreadCount: Map<String, int>.from(json['unreadCount'] as Map? ?? {}),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// แปลงข้อมูลห้องแชทเป็น Map สำหรับบันทึกลง Firestore
  Map<String, dynamic> toJson() {
    return {
      'participants': participants,
      'bookId': bookId,
      'lastMessage': lastMessage,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount': unreadCount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}

/// เก็บเนื้อหา ผู้ส่ง และสถานะการอ่านของข้อความในห้องแชท
class ChatMessageModel {
  final String id;
  final String senderId;
  final String? text;
  final String? imageUrl;
  final List<String> readBy;
  final DateTime? createdAt;

  /// สร้างโมเดลข้อความจากค่าที่กำหนด
  ChatMessageModel({
    required this.id,
    required this.senderId,
    this.text,
    this.imageUrl,
    this.readBy = const [],
    this.createdAt,
  });

  /// สร้างโมเดลข้อความจากข้อมูล Firestore
  factory ChatMessageModel.fromJson(String id, Map<String, dynamic> json) {
    return ChatMessageModel(
      id: id,
      senderId: json['senderId'] as String? ?? '',
      text: json['text'] as String?,
      imageUrl: json['imageUrl'] as String?,
      readBy: List<String>.from(json['readBy'] as List? ?? []),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// แปลงข้อความเป็น Map สำหรับบันทึกลง Firestore
  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'readBy': readBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}