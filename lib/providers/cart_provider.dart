import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/book_model.dart';
import '../models/book_volume_model.dart';

class CartItem {
  const CartItem({
    required this.book,
    required this.volume,
    required this.quantity,
  });

  final BookModel book;
  final BookVolumeModel volume;
  final int quantity;

  double get subtotal => volume.price * quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(book: book, volume: volume, quantity: quantity ?? this.quantity);
}

class CartProvider extends ChangeNotifier {
  CartProvider({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance {
    _authSubscription = _auth.authStateChanges().listen(
      (_) => notifyListeners(),
    );
  }

  final FirebaseAuth _auth;
  late final StreamSubscription<User?> _authSubscription;
  final Map<String, List<CartItem>> _itemsByUser = {};

  String get _userKey => _auth.currentUser?.uid ?? '__guest__';
  List<CartItem> get _items => _itemsByUser.putIfAbsent(_userKey, () => []);

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (count, item) => count + item.quantity);
  double get total => _items.fold(0, (sum, item) => sum + item.subtotal);

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  bool addItem({
    required BookModel book,
    required BookVolumeModel volume,
    required int quantity,
  }) {
    if (!volume.isAvailable || quantity < 1 || quantity > volume.stock) {
      return false;
    }

    final index = _items.indexWhere(
      (item) => item.book.id == book.id && item.volume.id == volume.id,
    );
    if (index == -1) {
      _items.add(CartItem(book: book, volume: volume, quantity: quantity));
    } else {
      final updatedQuantity = _items[index].quantity + quantity;
      if (updatedQuantity > volume.stock) return false;
      _items[index] = _items[index].copyWith(quantity: updatedQuantity);
    }

    notifyListeners();
    return true;
  }

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
      _items[index] = _items[index].copyWith(
        quantity: quantity.clamp(1, item.volume.stock),
      );
    }
    notifyListeners();
  }

  void removeItem(CartItem item) {
    _items.removeWhere(
      (current) =>
          current.book.id == item.book.id &&
          current.volume.id == item.volume.id,
    );
    notifyListeners();
  }

  void clearCurrentUserCart() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }
}
