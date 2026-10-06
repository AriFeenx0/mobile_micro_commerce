// สร้างคำสั่งซื้อและจัดการสถานะกับสต็อกผ่าน Firestore
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../models/order_model.dart';
import 'storage_service.dart';

class OrderService {
  OrderService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    StorageService? storageService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storageService = storageService ?? StorageService();

  static const String ordersCollection = 'orders';
  static const String booksCollection = 'books';
  static const String usersCollection = 'users';
  static const String volumesCollection = 'volumes';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final StorageService _storageService;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection(ordersCollection);

  Future<OrderModel> createOrder({
    required String ownerId,
    required List<OrderItem> items,
    required String shippingAddress,
    required double shippingFee,
    required XFile slipImage,
  }) async {
    final customer = _auth.currentUser;
    if (customer == null) throw StateError('กรุณาเข้าสู่ระบบก่อนสั่งสินค้า');
    if (ownerId.isEmpty) throw ArgumentError('ไม่พบเจ้าของร้านของสินค้า');
    if (items.isEmpty) throw ArgumentError('ไม่พบสินค้าในคำสั่งซื้อ');
    if (items.any((item) => item.qty < 1 || item.price < 0)) {
      throw ArgumentError('ข้อมูลสินค้าในคำสั่งซื้อไม่ถูกต้อง');
    }

    final orderReference = _orders.doc();
    final slipImageUrl = await _storageService.uploadOrderSlip(
      customerId: customer.uid,
      orderId: orderReference.id,
      image: slipImage,
    );
    final subtotal = items.fold<double>(
      0,
      (subtotal, item) => subtotal + item.price * item.qty,
    );
    final order = OrderModel(
      id: orderReference.id,
      customerId: customer.uid,
      ownerId: ownerId,
      items: items,
      subtotal: subtotal,
      shippingFee: shippingFee,
      totalAmount: subtotal + shippingFee,
      shippingAddress: shippingAddress.trim(),
      paymentMethod: 'โอนธนาคาร',
      slipImageUrl: slipImageUrl,
      status: OrderStatus.pendingSlipReview,
      createdAt: DateTime.now(),
    );

    await orderReference.set(order.toJson());
    return order;
  }

  Future<void> confirmPaymentAndDeductStock(String orderId) async {
    final owner = await _requireShopOwner();
    final orderReference = _orders.doc(orderId);

    await _firestore.runTransaction((transaction) async {
      final ownerProfileReference = _firestore
          .collection(usersCollection)
          .doc(owner.uid);
      final ownerProfile = await transaction.get(ownerProfileReference);
      if (ownerProfile.data()?['role'] != 'owner') {
        throw StateError('บัญชีนี้ไม่มีสิทธิ์จัดการคำสั่งซื้อ');
      }

      final orderSnapshot = await transaction.get(orderReference);
      final orderData = orderSnapshot.data();
      if (!orderSnapshot.exists || orderData == null) {
        throw StateError('ไม่พบคำสั่งซื้อ');
      }
      final order = OrderModel.fromJson(orderSnapshot.id, orderData);
      if (order.ownerId != owner.uid) {
        throw StateError('ไม่สามารถยืนยันคำสั่งซื้อของร้านอื่นได้');
      }
      if (order.status != OrderStatus.pendingSlipReview) {
        throw StateError('คำสั่งซื้อนี้ไม่ได้อยู่ในสถานะรอตรวจสอบสลิป');
      }
      if (order.items.isEmpty) throw StateError('คำสั่งซื้อไม่มีรายการสินค้า');

      final bookReferences =
          <String, DocumentReference<Map<String, dynamic>>>{};
      for (final item in order.items) {
        bookReferences[item.bookId] = _firestore
            .collection(booksCollection)
            .doc(item.bookId);
      }
      for (final entry in bookReferences.entries) {
        final bookSnapshot = await transaction.get(entry.value);
        if (!bookSnapshot.exists ||
            bookSnapshot.data()?['ownerId'] != owner.uid) {
          throw StateError('พบหนังสือที่ไม่ได้เป็นของร้านนี้');
        }
      }

      final stockChanges = _stockChangesForItems(order.items);

      final volumeSnapshots =
          <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final entry in stockChanges.entries) {
        volumeSnapshots[entry.key] = await transaction.get(
          entry.value.reference,
        );
      }
      for (final entry in stockChanges.entries) {
        final snapshot = volumeSnapshots[entry.key]!;
        final volumeData = snapshot.data();
        if (!snapshot.exists || volumeData == null) {
          throw StateError('ไม่พบเล่มหนังสือที่อยู่ในคำสั่งซื้อ');
        }
        final stock = (volumeData['stock'] as num?)?.toInt() ?? 0;
        if (stock < entry.value.quantity) {
          throw StateError('สต๊อกไม่เพียงพอสำหรับยืนยันการชำระเงิน');
        }
      }

      for (final entry in stockChanges.entries) {
        final volumeData = volumeSnapshots[entry.key]!.data()!;
        final stock = (volumeData['stock'] as num?)?.toInt() ?? 0;
        transaction.update(entry.value.reference, {
          'stock': stock - entry.value.quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      transaction.update(orderReference, {
        'status': orderStatusToString(OrderStatus.paid),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> rejectPayment(
    String orderId, {
    String reason = 'สลิปไม่ถูกต้อง',
  }) async {
    final owner = await _requireShopOwner();
    final orderReference = _orders.doc(orderId);

    await _firestore.runTransaction((transaction) async {
      final orderSnapshot = await transaction.get(orderReference);
      final orderData = orderSnapshot.data();
      if (!orderSnapshot.exists || orderData == null) {
        throw StateError('ไม่พบคำสั่งซื้อ');
      }
      final order = OrderModel.fromJson(orderSnapshot.id, orderData);
      if (order.ownerId != owner.uid) {
        throw StateError('ไม่สามารถแก้ไขคำสั่งซื้อของร้านอื่นได้');
      }
      if (order.status != OrderStatus.pendingSlipReview) {
        throw StateError('คำสั่งซื้อนี้ไม่ได้อยู่ในสถานะรอตรวจสอบสลิป');
      }

      transaction.update(orderReference, {
        'status': orderStatusToString(OrderStatus.cancelled),
        'cancelReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<List<OrderModel>> watchOrdersForOwner(String ownerId) {
    return _orders
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) => _sortOrders(snapshot.docs));
  }

  Stream<List<OrderModel>> watchOrdersForCustomer(String customerId) {
    return _orders
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) => _sortOrders(snapshot.docs));
  }

  List<OrderModel> _sortOrders(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final orders = documents
        .map((document) => OrderModel.fromJson(document.id, document.data()))
        .toList();
    orders.sort(
      (first, second) => (second.createdAt ?? DateTime(0)).compareTo(
        first.createdAt ?? DateTime(0),
      ),
    );
    return orders;
  }

  Future<User> _requireShopOwner() async {
    final owner = _auth.currentUser;
    if (owner == null) throw StateError('กรุณาเข้าสู่ระบบก่อนจัดการคำสั่งซื้อ');
    final profile = await _firestore
        .collection(usersCollection)
        .doc(owner.uid)
        .get();
    if (profile.data()?['role'] != 'owner') {
      throw StateError('บัญชีนี้ไม่มีสิทธิ์จัดการคำสั่งซื้อ');
    }
    return owner;
  }

  Map<String, _StockChange> _stockChangesForItems(List<OrderItem> items) {
    if (items.isEmpty) throw StateError('คำสั่งซื้อไม่มีรายการสินค้า');

    final stockChanges = <String, _StockChange>{};
    for (final item in items) {
      if (item.bookId.isEmpty || item.volumeId.isEmpty || item.qty < 1) {
        throw StateError('ข้อมูลหนังสือหรือจำนวนสินค้าในคำสั่งซื้อไม่ถูกต้อง');
      }
      final volumeReference = _firestore
          .collection(booksCollection)
          .doc(item.bookId)
          .collection(volumesCollection)
          .doc(item.volumeId);
      final existingChange = stockChanges[volumeReference.path];
      stockChanges[volumeReference.path] = _StockChange(
        reference: volumeReference,
        quantity: (existingChange?.quantity ?? 0) + item.qty,
      );
    }
    return stockChanges;
  }
}

class _StockChange {
  const _StockChange({required this.reference, required this.quantity});

  final DocumentReference<Map<String, dynamic>> reference;
  final int quantity;
}
