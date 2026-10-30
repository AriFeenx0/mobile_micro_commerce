/// สร้างคำสั่งซื้อและจัดการสถานะกับสต็อกผ่าน Firestore
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../models/coupon_model.dart';
import '../models/order_model.dart';
import 'storage_service.dart';

class OrderService {
  /// ตั้งค่า Firebase และบริการอัปโหลดสลิป โดยรองรับ dependency สำหรับทดสอบ
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
  static const String couponsCollection = 'coupons';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final StorageService _storageService;

  /// อ้างอิงคอลเลกชันคำสั่งซื้อ
  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection(ordersCollection);

  static const reservationDuration = Duration(minutes: 15);

  /// ตรวจข้อมูลและจองสต็อกกับคูปองพร้อมสร้างคำสั่งซื้อใน transaction
  Future<OrderModel> reserveOrder({
    required String ownerId,
    required List<OrderItem> items,
    required String shippingAddress,
    required double shippingFee,
    String? couponCode,
  }) async {
    final customer = _auth.currentUser;
    if (customer == null) throw StateError('กรุณาเข้าสู่ระบบก่อนสั่งสินค้า');
    if (ownerId.isEmpty) throw ArgumentError('ไม่พบเจ้าของร้านของสินค้า');
    if (items.isEmpty) throw ArgumentError('ไม่พบสินค้าในคำสั่งซื้อ');
    if (shippingAddress.trim().isEmpty) {
      throw ArgumentError('กรุณากรอกที่อยู่จัดส่ง');
    }
    if (shippingFee < 0 ||
        items.any(
          (item) =>
              item.bookId.isEmpty ||
              item.volumeId.isEmpty ||
              item.qty < 1 ||
              item.price < 0,
        )) {
      throw ArgumentError('ข้อมูลสินค้าในคำสั่งซื้อไม่ถูกต้อง');
    }

    final orderReference = _orders.doc();
    final stockChanges = _stockChangesForItems(items);
    final normalizedCoupon = couponCode == null || couponCode.trim().isEmpty
        ? null
        : CouponModel.normalizeCode(couponCode);
    if (normalizedCoupon != null && !CouponModel.isValidCode(normalizedCoupon)) {
      throw StateError('รูปแบบโค้ดคูปองไม่ถูกต้อง');
    }
    final couponReference = normalizedCoupon == null
        ? null
        : _firestore.collection(couponsCollection).doc(normalizedCoupon);

    return _firestore.runTransaction((transaction) async {
      final createdAt = DateTime.now();
      final lockExpiresAt = createdAt.add(reservationDuration);
      final bookReferences = <String, DocumentReference<Map<String, dynamic>>>{};
      for (final item in items) {
        bookReferences[item.bookId] = _firestore
            .collection(booksCollection)
            .doc(item.bookId);
      }
      final bookSnapshots = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final entry in bookReferences.entries) {
        bookSnapshots[entry.key] = await transaction.get(entry.value);
      }
      for (final entry in bookSnapshots.entries) {
        if (!entry.value.exists ||
            entry.value.data()?['ownerId'] != ownerId) {
          throw StateError('พบหนังสือที่ไม่ได้เป็นของร้านนี้');
        }
      }

      final volumeSnapshots =
          <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final entry in stockChanges.entries) {
        volumeSnapshots[entry.key] = await transaction.get(
          entry.value.reference,
        );
      }

      final couponSnapshot = couponReference == null
          ? null
          : await transaction.get(couponReference);

      final reservationsByVolume = <String, Map<String, dynamic>>{};
      final expiredOrderIds = <String>{};
      for (final entry in stockChanges.entries) {
        final volumeData = volumeSnapshots[entry.key]?.data();
        if (volumeData == null) {
          throw StateError('ไม่พบเล่มหนังสือที่อยู่ในคำสั่งซื้อ');
        }
        final reservations = _reservationsFrom(volumeData['reservations']);
        reservations.removeWhere((orderId, value) {
          final expiresAt = value['expiresAt'];
          final expired =
              value['status'] == 'pendingPayment' &&
              expiresAt is Timestamp &&
              !expiresAt.toDate().isAfter(createdAt);
          if (expired &&
              value['customerId'] == customer.uid &&
              orderId.isNotEmpty &&
              !orderId.contains('/')) {
            expiredOrderIds.add(orderId);
          }
          return expired;
        });
        reservationsByVolume[entry.key] = reservations;
      }

      final expiredOrders =
          <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final orderId in expiredOrderIds) {
        expiredOrders[orderId] = await transaction.get(_orders.doc(orderId));
      }

      final reservedOrder = <String, OrderItem>{};
      for (final entry in stockChanges.entries) {
        final volumeSnapshot = volumeSnapshots[entry.key]!;
        final volumeData = volumeSnapshot.data()!;
        final bookData = bookSnapshots[entry.value.bookId]!.data()!;
        final stock = (volumeData['stock'] as num?)?.toInt() ?? 0;
        final reservations = reservationsByVolume[entry.key]!;
        final reservedQuantity = _activeReservationQuantity(
          reservations,
          stock,
          createdAt,
        );
        if (stock - reservedQuantity < entry.value.quantity) {
          throw StateError('สต๊อกไม่เพียงพอ กรุณาปรับจำนวนสินค้าในตะกร้า');
        }
        if (reservations.length >= 100) {
          throw StateError('มีรายการจองสต็อกค้างมากเกินไป กรุณาติดต่อร้านค้า');
        }
        reservedOrder[entry.key] = OrderItem(
          bookId: entry.value.bookId,
          volumeId: entry.value.volumeId,
          title: bookData['title'] as String? ?? '',
          volumeNumber: (volumeData['volumeNumber'] as num?)?.toInt() ?? 1,
          price: (volumeData['price'] as num?)?.toDouble() ?? 0,
          qty: entry.value.quantity,
        );
      }
      final orderItems = reservedOrder.values.toList();
      final subtotal = orderItems.fold<double>(
        0,
        (total, item) => total + item.price * item.qty,
      );

      var discountAmount = 0.0;
      Map<String, dynamic>? couponReservations;
      if (couponSnapshot != null) {
        final couponData = couponSnapshot.data();
        if (!couponSnapshot.exists || couponData == null) {
          throw StateError('ไม่พบคูปองนี้');
        }
        final coupon = CouponModel.fromJson(couponSnapshot.id, couponData);
        final reason = coupon.invalidReason(subtotal, shopOwnerId: ownerId);
        if (reason != null) throw StateError(reason);

        couponReservations = _reservationsFrom(couponData['reservations'])
          ..removeWhere((_, value) {
            final expiresAt = value is Map ? value['expiresAt'] : null;
            return value is Map &&
                value['status'] == 'pendingPayment' &&
                expiresAt is Timestamp &&
                !expiresAt.toDate().isAfter(createdAt);
          });
        if (couponReservations.length >= 100) {
          throw StateError('มีรายการจองคูปองค้างมากเกินไป กรุณาลองใหม่ภายหลัง');
        }
        discountAmount = coupon.discountFor(subtotal);
      }
      final order = OrderModel(
        id: orderReference.id,
        customerId: customer.uid,
        ownerId: ownerId,
        items: orderItems,
        subtotal: subtotal,
        shippingFee: shippingFee,
        couponCode: couponSnapshot == null ? null : normalizedCoupon,
        discountAmount: discountAmount,
        totalAmount: subtotal + shippingFee - discountAmount,
        shippingAddress: shippingAddress.trim(),
        paymentMethod: 'โอนธนาคาร',
        status: OrderStatus.pendingPayment,
        lockExpiresAt: lockExpiresAt,
        createdAt: createdAt,
      );

      for (final entry in reservationsByVolume.entries) {
        entry.value[orderReference.id] = {
          'customerId': customer.uid,
          'quantity': stockChanges[entry.key]!.quantity,
          'status': 'pendingPayment',
          'expiresAt': Timestamp.fromDate(lockExpiresAt),
        };
        transaction.update(stockChanges[entry.key]!.reference, {
          'reservations': entry.value,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      transaction.set(orderReference, order.toJson());
      if (couponReference != null && couponReservations != null) {
        couponReservations[orderReference.id] = {
          'customerId': customer.uid,
          'status': 'pendingPayment',
          'expiresAt': Timestamp.fromDate(lockExpiresAt),
        };
        transaction.update(couponReference, {
          'reservations': couponReservations,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      for (final entry in expiredOrders.entries) {
        final oldOrder = entry.value.data();
        final oldLockExpiresAt = oldOrder?['lockExpiresAt'];
        if (oldOrder?['status'] == orderStatusToString(
              OrderStatus.pendingPayment,
            ) &&
            oldLockExpiresAt is Timestamp &&
            !oldLockExpiresAt.toDate().isAfter(createdAt)) {
          transaction.update(_orders.doc(entry.key), {
            'status': orderStatusToString(OrderStatus.cancelled),
            'cancelReason': 'หมดเวลาจองสต็อก',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      return order;
    });
  }

  /// อัปโหลดสลิปและเปลี่ยนคำสั่งซื้อเป็นรอตรวจสอบ หรือยกเลิกเมื่อหมดเวลา
  Future<void> submitSlip({
    required String orderId,
    required XFile slipImage,
  }) async {
    final customer = _auth.currentUser;
    if (customer == null) throw StateError('กรุณาเข้าสู่ระบบก่อนส่งสลิป');
    final slipImageUrl = await _storageService.uploadOrderSlip(
      customerId: customer.uid,
      orderId: orderId,
      image: slipImage,
    );
    final orderReference = _orders.doc(orderId);
    final expired = await _firestore.runTransaction((transaction) async {
      final orderSnapshot = await transaction.get(orderReference);
      final orderData = orderSnapshot.data();
      if (!orderSnapshot.exists || orderData == null) {
        throw StateError('ไม่พบคำสั่งซื้อ');
      }
      final order = OrderModel.fromJson(orderSnapshot.id, orderData);
      if (order.customerId != customer.uid) {
        throw StateError('ไม่สามารถส่งสลิปของคำสั่งซื้อบัญชีอื่นได้');
      }
      if (order.status != OrderStatus.pendingPayment) {
        throw StateError('คำสั่งซื้อนี้ไม่ได้อยู่ในสถานะรอชำระเงิน');
      }

      final stockChanges = _stockChangesForItems(order.items);
      final volumeSnapshots =
          <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final entry in stockChanges.entries) {
        volumeSnapshots[entry.key] = await transaction.get(
          entry.value.reference,
        );
      }

      final isExpired =
          order.lockExpiresAt == null ||
          !order.lockExpiresAt!.isAfter(DateTime.now());
      final couponReference = _couponReferenceFor(order);
      final couponSnapshot = couponReference == null
          ? null
          : await transaction.get(couponReference);
      for (final entry in stockChanges.entries) {
        final volumeData = volumeSnapshots[entry.key]?.data();
        final reservations = _reservationsFrom(volumeData?['reservations']);
        final reservation = reservations[orderId];
        if (reservation == null ||
            reservation['customerId'] != customer.uid ||
            (reservation['quantity'] as num?)?.toInt() !=
                entry.value.quantity) {
          throw StateError('ไม่พบการจองสต็อกของคำสั่งซื้อนี้');
        }
        if (isExpired) {
          reservations.remove(orderId);
        } else {
          reservations[orderId] = {
            ...reservation,
            'status': 'pendingSlipReview',
            'expiresAt': null,
          };
        }
        transaction.update(entry.value.reference, {
          'reservations': reservations,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (couponReference != null) {
        final reservations = _reservationsFrom(
          couponSnapshot?.data()?['reservations'],
        );
        final reservation = reservations[orderId];
        if (reservation is! Map || reservation['customerId'] != customer.uid) {
          throw StateError('ไม่พบการจองคูปองของคำสั่งซื้อนี้');
        }
        if (isExpired) {
          reservations.remove(orderId);
        } else {
          reservations[orderId] = {
            ...reservation,
            'status': 'pendingSlipReview',
            'expiresAt': null,
          };
        }
        transaction.update(couponReference, {
          'reservations': reservations,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.update(orderReference, {
        'status': orderStatusToString(
          isExpired ? OrderStatus.cancelled : OrderStatus.pendingSlipReview,
        ),
        'slipImageUrl': isExpired ? null : slipImageUrl,
        if (isExpired) 'cancelReason': 'หมดเวลาจองสต็อก',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return isExpired;
    });
    if (expired) {
      throw StateError('หมดเวลาจองสต็อกแล้ว กรุณาสร้างคำสั่งซื้อใหม่');
    }
  }

  /// ยืนยันสลิปและหักสต็อกพร้อมบันทึกการใช้คูปองใน transaction
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
      final couponReference = _couponReferenceFor(order);
      final couponSnapshot = couponReference == null
          ? null
          : await transaction.get(couponReference);
      for (final entry in stockChanges.entries) {
        final snapshot = volumeSnapshots[entry.key]!;
        final volumeData = snapshot.data();
        if (!snapshot.exists || volumeData == null) {
          throw StateError('ไม่พบเล่มหนังสือที่อยู่ในคำสั่งซื้อ');
        }
        final reservation =
            _reservationsFrom(volumeData['reservations'])[orderId];
        if (reservation == null ||
            reservation['status'] != 'pendingSlipReview' ||
            (reservation['quantity'] as num?)?.toInt() !=
                entry.value.quantity) {
          throw StateError('ไม่พบการจองสต็อกของคำสั่งซื้อนี้');
        }
        final stock = (volumeData['stock'] as num?)?.toInt() ?? 0;
        if (stock < entry.value.quantity) {
          throw StateError('สต๊อกไม่เพียงพอสำหรับยืนยันการชำระเงิน');
        }
      }

      for (final entry in stockChanges.entries) {
        final volumeData = volumeSnapshots[entry.key]!.data()!;
        final stock = (volumeData['stock'] as num?)?.toInt() ?? 0;
        final reservations = _reservationsFrom(volumeData['reservations'])
          ..remove(orderId);
        transaction.update(entry.value.reference, {
          'stock': stock - entry.value.quantity,
          'reservations': reservations,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      if (couponReference != null) {
        final couponData = couponSnapshot?.data();
        if (couponData == null || couponData['ownerId'] != owner.uid) {
          throw StateError('ไม่พบคูปองของคำสั่งซื้อนี้');
        }
        final reservations = _reservationsFrom(couponData['reservations']);
        final reservation = reservations[orderId];
        if (reservation is! Map ||
            reservation['status'] != 'pendingSlipReview') {
          throw StateError('ไม่พบการจองคูปองของคำสั่งซื้อนี้');
        }
        reservations.remove(orderId);
        transaction.update(couponReference, {
          'usedCount': ((couponData['usedCount'] as num?)?.toInt() ?? 0) + 1,
          'reservations': reservations,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      transaction.update(orderReference, {
        'status': orderStatusToString(OrderStatus.paid),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// ปฏิเสธสลิป ยกเลิกคำสั่งซื้อ และคืนการจองที่เกี่ยวข้อง
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

      final stockChanges = _stockChangesForItems(order.items);
      final volumeSnapshots =
          <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final entry in stockChanges.entries) {
        volumeSnapshots[entry.key] = await transaction.get(
          entry.value.reference,
        );
      }
      final couponReference = _couponReferenceFor(order);
      final couponSnapshot = couponReference == null
          ? null
          : await transaction.get(couponReference);
      for (final entry in stockChanges.entries) {
        final volumeData = volumeSnapshots[entry.key]?.data();
        if (volumeData == null) {
          throw StateError('ไม่พบเล่มหนังสือที่อยู่ในคำสั่งซื้อ');
        }
        final reservations = _reservationsFrom(volumeData['reservations']);
        final reservation = reservations[orderId];
        if (reservation == null ||
            reservation['status'] != 'pendingSlipReview' ||
            (reservation['quantity'] as num?)?.toInt() !=
                entry.value.quantity) {
          throw StateError('ไม่พบการจองสต็อกของคำสั่งซื้อนี้');
        }
        reservations.remove(orderId);
        transaction.update(entry.value.reference, {
          'reservations': reservations,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      if (couponReference != null) {
        final couponData = couponSnapshot?.data();
        if (couponData == null || couponData['ownerId'] != owner.uid) {
          throw StateError('ไม่พบคูปองของคำสั่งซื้อนี้');
        }
        final reservations = _reservationsFrom(couponData['reservations']);
        final reservation = reservations[orderId];
        if (reservation is! Map ||
            reservation['status'] != 'pendingSlipReview') {
          throw StateError('ไม่พบการจองคูปองของคำสั่งซื้อนี้');
        }
        reservations.remove(orderId);
        transaction.update(couponReference, {
          'reservations': reservations,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      transaction.update(orderReference, {
        'status': orderStatusToString(OrderStatus.cancelled),
        'cancelReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// ติดตามคำสั่งซื้อของร้านและเรียงจากรายการใหม่ไปเก่า
  Stream<List<OrderModel>> watchOrdersForOwner(String ownerId) {
    return _orders
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) => _sortOrders(snapshot.docs));
  }

  /// ติดตามคำสั่งซื้อของลูกค้าและเรียงจากรายการใหม่ไปเก่า
  Stream<List<OrderModel>> watchOrdersForCustomer(String customerId) {
    return _orders
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) => _sortOrders(snapshot.docs));
  }

  /// แปลงเอกสารเป็นคำสั่งซื้อและเรียงตามวันที่สร้าง
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

  /// ตรวจสอบว่าผู้ใช้ปัจจุบันมีบทบาทเจ้าของร้าน
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

  /// คืนเอกสารคูปองของคำสั่งซื้อเมื่อมีการระบุโค้ด
  DocumentReference<Map<String, dynamic>>? _couponReferenceFor(
    OrderModel order,
  ) {
    final code = order.couponCode;
    if (code == null || code.isEmpty) return null;
    return _firestore.collection(couponsCollection).doc(code);
  }

  /// รวมจำนวนสินค้าตามเอกสารเล่มสำหรับตรวจและเปลี่ยนสต็อก
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
        bookId: item.bookId,
        volumeId: item.volumeId,
        quantity: (existingChange?.quantity ?? 0) + item.qty,
      );
    }
    return stockChanges;
  }

  /// แปลงข้อมูลการจองจาก Firestore เป็นแผนที่หรือแผนที่ว่าง
  Map<String, dynamic> _reservationsFrom(Object? rawReservations) {
    if (rawReservations is! Map) return {};
    return Map<String, dynamic>.from(rawReservations);
  }

  /// รวมจำนวนสต็อกที่ถูกจองและยังไม่หมดอายุ
  int _activeReservationQuantity(
    Map<String, dynamic> reservations,
    int stock,
    DateTime now,
  ) {
    return reservations.values.fold<int>(0, (total, value) {
      if (value is! Map) return stock;
      final quantity = (value['quantity'] as num?)?.toInt();
      if (quantity == null || quantity < 1) return stock;

      final expiresAt = value['expiresAt'];
      if (value['status'] == 'pendingPayment' && expiresAt is Timestamp) {
        if (!expiresAt.toDate().isAfter(now)) return total;
      }
      return total + quantity;
    });
  }
}

class _StockChange {
  /// เก็บเอกสารหนังสือเล่มและจำนวนรวมที่ต้องเปลี่ยนสต็อก
  const _StockChange({
    required this.reference,
    required this.bookId,
    required this.volumeId,
    required this.quantity,
  });

  final DocumentReference<Map<String, dynamic>> reference;
  final String bookId;
  final String volumeId;
  final int quantity;
}
