// โมเดลรายการและสถานะคำสั่งซื้อสำหรับ Firestore
import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pendingPayment, // รอชำระเงิน
  pendingSlipReview, // รอตรวจสอบสลิป
  paid, // ชำระเงินแล้ว
  shipped, // จัดส่งแล้ว
  cancelled, // ยกเลิก
}

OrderStatus _statusFromString(String value) {
  switch (value) {
    case 'รอตรวจสอบสลิป':
      return OrderStatus.pendingSlipReview;
    case 'ชำระเงินแล้ว':
      return OrderStatus.paid;
    case 'จัดส่งแล้ว':
      return OrderStatus.shipped;
    case 'ยกเลิก':
      return OrderStatus.cancelled;
    case 'รอชำระเงิน':
    default:
      return OrderStatus.pendingPayment;
  }
}

String orderStatusToString(OrderStatus status) {
  switch (status) {
    case OrderStatus.pendingSlipReview:
      return 'รอตรวจสอบสลิป';
    case OrderStatus.paid:
      return 'ชำระเงินแล้ว';
    case OrderStatus.shipped:
      return 'จัดส่งแล้ว';
    case OrderStatus.cancelled:
      return 'ยกเลิก';
    case OrderStatus.pendingPayment:
      return 'รอชำระเงิน';
  }
}

class OrderItem {
  final String bookId;
  final String volumeId;
  final String title; // denormalized เผื่อหนังสือถูกลบภายหลัง
  final int volumeNumber;
  final double price;
  final int qty;

  OrderItem({
    required this.bookId,
    required this.volumeId,
    required this.title,
    required this.volumeNumber,
    required this.price,
    required this.qty,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      bookId: json['bookId'] as String? ?? '',
      volumeId: json['volumeId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      volumeNumber: (json['volumeNumber'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      qty: (json['qty'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'volumeId': volumeId,
      'title': title,
      'volumeNumber': volumeNumber,
      'price': price,
      'qty': qty,
    };
  }
}

class OrderModel {
  final String id;
  final String customerId;
  final String ownerId;
  final List<OrderItem> items;
  final double subtotal;
  final double shippingFee;
  final String? couponCode;
  final double discountAmount;
  final double totalAmount;
  final String shippingAddress;
  final String paymentMethod; // "โอนธนาคาร" | "พร้อมเพย์"
  final String? slipImageUrl;
  final OrderStatus status;
  final String? cancelReason;
  final String? trackingNumber;
  final DateTime? lockExpiresAt; // ตรงกับ Payment Flow: ล็อกสต๊อก 15 นาที
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.ownerId,
    required this.items,
    required this.subtotal,
    this.shippingFee = 0,
    this.couponCode,
    this.discountAmount = 0,
    required this.totalAmount,
    required this.shippingAddress,
    required this.paymentMethod,
    this.slipImageUrl,
    this.status = OrderStatus.pendingPayment,
    this.cancelReason,
    this.trackingNumber,
    this.lockExpiresAt,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderModel.fromJson(String id, Map<String, dynamic> json) {
    return OrderModel(
      id: id,
      customerId: json['customerId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      items: (json['items'] as List? ?? [])
          .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      shippingFee: (json['shippingFee'] as num?)?.toDouble() ?? 0,
      couponCode: json['couponCode'] as String?,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      shippingAddress: json['shippingAddress'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? 'พร้อมเพย์',
      slipImageUrl: json['slipImageUrl'] as String?,
      status: _statusFromString(json['status'] as String? ?? 'รอชำระเงิน'),
      cancelReason: json['cancelReason'] as String?,
      trackingNumber: json['trackingNumber'] as String?,
      lockExpiresAt: (json['lockExpiresAt'] as Timestamp?)?.toDate(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'ownerId': ownerId,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'couponCode': couponCode,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
      'slipImageUrl': slipImageUrl,
      'status': orderStatusToString(status),
      'cancelReason': cancelReason,
      'trackingNumber': trackingNumber,
      'lockExpiresAt': lockExpiresAt != null ? Timestamp.fromDate(lockExpiresAt!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}