/// บริการแชทระหว่างลูกค้ากับเจ้าของร้านผ่าน Firestore
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class ChatService {
  /// ตั้งค่า Firestore โดยรองรับการส่ง instance เข้ามาทดสอบ
  ChatService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String roomsCollection = 'chat_rooms';
  static const String messagesCollection = 'messages';

  final FirebaseFirestore _firestore;

  /// อ้างอิงคอลเลกชันห้องสนทนา
  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection(roomsCollection);

  /// ค้นหาเจ้าของร้านหนึ่งบัญชี หรือคืน null เมื่อไม่พบ
  Future<UserModel?> getOwner() async {
    final snapshot = await _firestore
        .collection(AuthService.usersCollection)
        .where('role', isEqualTo: 'owner')
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return UserModel.fromJson(doc.id, doc.data());
  }

  /// ติดตามรายชื่อลูกค้าและเรียงตามชื่อ
  Stream<List<UserModel>> watchCustomers() {
    return _firestore
        .collection(AuthService.usersCollection)
        .where('role', isEqualTo: 'customer')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromJson(doc.id, doc.data()))
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name)),
        );
  }

  /// ติดตามห้องสนทนาที่มีผู้ใช้เป็นผู้เข้าร่วม
  Stream<List<ChatRoomModel>> watchRoomsForUser(String userId) {
    return _rooms
        .where('participants', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatRoomModel.fromJson(doc.id, doc.data()))
              .toList(),
        );
  }

  /// ติดตามข้อความในห้องตามลำดับเวลาที่สร้าง
  Stream<List<ChatMessageModel>> watchMessages(String roomId) {
    return _rooms
        .doc(roomId)
        .collection(messagesCollection)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessageModel.fromJson(doc.id, doc.data()))
              .toList(),
        );
  }

  /// บันทึกข้อความหรือรูปภาพ พร้อมอัปเดตข้อความล่าสุดและจำนวนที่ยังไม่อ่าน
  Future<void> sendMessage({
    required String customerId,
    required String ownerId,
    required String senderId,
    required String text,
    String? imageUrl,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty && (imageUrl == null || imageUrl.isEmpty)) {
      throw ArgumentError('ข้อความต้องมีข้อความหรือรูปภาพ');
    }

    final roomId = ChatRoomModel.buildRoomId(customerId, ownerId);
    final receiverId = senderId == customerId ? ownerId : customerId;
    final roomRef = _rooms.doc(roomId);
    final batch = _firestore.batch();
    batch.set(roomRef, {
      'participants': [customerId, ownerId],
      'lastMessage': trimmedText.isNotEmpty ? trimmedText : 'ส่งรูปภาพ',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount': {receiverId: FieldValue.increment(1)},
    }, SetOptions(merge: true));
    batch.set(roomRef.collection(messagesCollection).doc(), {
      'senderId': senderId,
      'text': trimmedText.isNotEmpty ? trimmedText : null,
      'imageUrl': imageUrl,
      'readBy': [senderId],
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// ตั้งจำนวนข้อความที่ยังไม่อ่านของผู้ใช้ในห้องเป็นศูนย์
  Future<void> markRead({
    required String customerId,
    required String ownerId,
    required String userId,
  }) {
    return _rooms.doc(ChatRoomModel.buildRoomId(customerId, ownerId)).set({
      'unreadCount': {userId: 0},
    }, SetOptions(merge: true));
  }
}
