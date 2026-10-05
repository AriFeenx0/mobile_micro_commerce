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
}
