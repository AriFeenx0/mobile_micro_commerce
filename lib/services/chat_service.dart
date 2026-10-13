// บริการแชทระหว่างลูกค้ากับเจ้าของร้านผ่าน Firestore
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class ChatService {
  ChatService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String roomsCollection = 'chat_rooms';
  static const String messagesCollection = 'messages';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection(roomsCollection);

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

  Future<void> sendMessage({
    required String customerId,
    required String ownerId,
    required String senderId,
    required String text,
  }) async {
    final roomId = ChatRoomModel.buildRoomId(customerId, ownerId);
    final receiverId = senderId == customerId ? ownerId : customerId;
    final roomRef = _rooms.doc(roomId);
    final batch = _firestore.batch();
    batch.set(roomRef, {
      'participants': [customerId, ownerId],
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount': {receiverId: FieldValue.increment(1)},
    }, SetOptions(merge: true));
    batch.set(roomRef.collection(messagesCollection).doc(), {
      'senderId': senderId,
      'text': text,
      'imageUrl': null,
      'readBy': [senderId],
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

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

