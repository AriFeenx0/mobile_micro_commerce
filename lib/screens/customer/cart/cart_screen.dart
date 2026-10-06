// แสดงและปรับรายการสินค้าในตะกร้าก่อนสั่งซื้อ
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_routes.dart';
import '../../../providers/cart_provider.dart';
import '../../../widgets/navigation/customer_bottom_nav.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('ตะกร้าสินค้า'),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
          ),
          body: cart.items.isEmpty
              ? _EmptyCart(onBrowse: () => _navigate(context, 0))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: cart.items.length,
                        separatorBuilder: (_, _) => const Divider(height: 24),
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return _CartItemRow(
                            item: item,
                            onRemove: () => cart.removeItem(item),
                            onQuantityChanged: (quantity) =>
                                cart.setQuantity(item, quantity),
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'ยอดรวม',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  _formatPrice(cart.total),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: FilledButton(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.customerCheckout,
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF333333),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('ดำเนินการต่อ'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
          bottomNavigationBar: CustomerBottomNav(
            selectedIndex: 1,
            onDestinationSelected: (index) => _navigate(context, index),
          ),
        );
      },
    );
  }

  void _navigate(BuildContext context, int index) {
    final route = switch (index) {
      0 => AppRoutes.customerBooks,
      2 => AppRoutes.chats,
      3 => AppRoutes.profile,
      _ => null,
    };
    if (route != null) Navigator.pushReplacementNamed(context, route);
  }

  String _formatPrice(double price) {
    final amount = price % 1 == 0
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
    return '฿$amount';
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({
    required this.item,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  final CartItem item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 76,
            height: 100,
            child: item.book.images.isEmpty
                ? const ColoredBox(color: Color(0xFFE5E5E5))
                : Image.network(
                    item.book.images.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const ColoredBox(color: Color(0xFFE5E5E5)),
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'นำออกจากตะกร้า',
                    onPressed: onRemove,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              Text(
                'เล่ม ${item.volume.volumeNumber} · ${item.volume.condition}',
                style: const TextStyle(color: Color(0xFF777777), fontSize: 13),
              ),
              const SizedBox(height: 5),
              Text(
                _formatPrice(item.volume.price),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _CartQuantityButton(
                    icon: Icons.remove,
                    onPressed: item.quantity > 1
                        ? () => onQuantityChanged(item.quantity - 1)
                        : null,
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${item.quantity}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  _CartQuantityButton(
                    icon: Icons.add,
                    onPressed: item.quantity < item.volume.stock
                        ? () => onQuantityChanged(item.quantity + 1)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatPrice(double price) {
    final amount = price % 1 == 0
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
    return '฿$amount';
  }
}

class _CartQuantityButton extends StatelessWidget {
  const _CartQuantityButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        iconSize: 18,
        icon: Icon(icon),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 48,
            color: Color(0xFF777777),
          ),
          const SizedBox(height: 12),
          const Text('ยังไม่มีสินค้าในตะกร้า'),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onBrowse,
            child: const Text('เลือกหนังสือ'),
          ),
        ],
      ),
    );
  }
}
