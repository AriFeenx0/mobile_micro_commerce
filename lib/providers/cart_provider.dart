/// จัดการรายการสินค้าในตะกร้าแยกตามผู้ใช้
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/book_model.dart';
import '../models/book_volume_model.dart';

class CartItem {
  /// สร้างรายการตะกร้าจากหนังสือ เล่ม และจำนวน
  const CartItem({
    required this.book,
    required this.volume,
    required this.quantity,
  });

  final BookModel book;
  final BookVolumeModel volume;
  final int quantity;

  /// ราคารวมของรายการตามจำนวนที่เลือก
  double get subtotal => volume.price * quantity;

  /// คัดลอกรายการโดยเลือกเปลี่ยนจำนวนได้
  CartItem copyWith({int? quantity}) =>
      CartItem(book: book, volume: volume, quantity: quantity ?? this.quantity);
}

class CartProvider extends ChangeNotifier {
  /// เริ่มติดตามการเข้าสู่ระบบเพื่อแจ้ง UI เมื่อผู้ใช้เปลี่ยน
  CartProvider({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance {
    _authSubscription = _auth.authStateChanges().listen(
      (_) => notifyListeners(),
    );
  }

  final FirebaseAuth _auth;
  late final StreamSubscription<User?> _authSubscription;
  final Map<String, List<CartItem>> _itemsByUser = {};

  /// คีย์ตะกร้าของผู้ใช้ปัจจุบัน หรือคีย์ผู้เยี่ยมชม
  String get _userKey => _auth.currentUser?.uid ?? '__guest__';

  /// รายการภายในตะกร้าของผู้ใช้ปัจจุบัน
  List<CartItem> get _items => _itemsByUser.putIfAbsent(_userKey, () => []);

  /// รายการตะกร้าแบบอ่านอย่างเดียว
  List<CartItem> get items => List.unmodifiable(_items);

  /// จำนวนชิ้นทั้งหมดในตะกร้า
  int get itemCount => _items.fold(0, (count, item) => count + item.quantity);

  /// มูลค่ารวมของสินค้าในตะกร้า
  double get total => _items.fold(0, (sum, item) => sum + item.subtotal);

  /// ยกเลิกการติดตามสถานะการเข้าสู่ระบบ
  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  /// เพิ่มสินค้าเมื่อเล่มพร้อมขายและจำนวนไม่เกินสต็อก
  bool addItem({
    required BookModel book,
    required BookVolumeModel volume,
    required int quantity,
  }) {
    if (!volume.isAvailable ||
        quantity < 1 ||
        quantity > volume.availableStock) {
      return false;
    }

    final index = _items.indexWhere(
      (item) => item.book.id == book.id && item.volume.id == volume.id,
    );
    if (index == -1) {
      _items.add(CartItem(book: book, volume: volume, quantity: quantity));
    } else {
      final updatedQuantity = _items[index].quantity + quantity;
      if (updatedQuantity > volume.availableStock) return false;
      _items[index] = _items[index].copyWith(quantity: updatedQuantity);
    }

    notifyListeners();
    return true;
  }

  /// จำกัดจำนวนตามสต็อก หรือนำรายการออกเมื่อจำนวนต่ำกว่าหนึ่ง
  void setQuantity(CartItem item, int quantity) {
    final index = _items.indexWhere(
      (current) =>
          current.book.id == item.book.id &&
          current.volume.id == item.volume.id,
    );
    if (index == -1) return;
    if (quantity < 1) {
      _items.removeAt(index);
    } else {
      if (item.volume.availableStock < 1) return;
      _items[index] = _items[index].copyWith(
        quantity: quantity.clamp(1, item.volume.availableStock),
      );
    }
    notifyListeners();
  }

  /// นำหนังสือและเล่มที่ระบุออกจากตะกร้า
  void removeItem(CartItem item) {
    _items.removeWhere(
      (current) =>
          current.book.id == item.book.id &&
          current.volume.id == item.volume.id,
    );
    notifyListeners();
  }

  /// ล้างตะกร้าของผู้ใช้ปัจจุบัน
  void clearCurrentUserCart() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }
}
