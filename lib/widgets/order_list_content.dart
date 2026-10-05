import 'package:flutter/material.dart';

import '../models/order_model.dart';

class OrderListContent extends StatelessWidget {
  const OrderListContent({
    super.key,
    required this.orders,
    this.ownerView = false,
  });

  final List<OrderModel> orders;
  final bool ownerView;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(child: Text('ยังไม่มีคำสั่งซื้อ'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) =>
          _OrderTile(order: orders[index], ownerView: ownerView),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.ownerView});

  final OrderModel order;
  final bool ownerView;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDDDDDD)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order ${order.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                orderStatusToString(order.status),
                style: const TextStyle(color: Color(0xFF777777), fontSize: 12),
              ),
            ],
          ),
          const Divider(height: 20),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.title} · เล่ม ${item.volumeNumber} × ${item.qty}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(_formatPrice(item.price * item.qty)),
                ],
              ),
            ),
          if (ownerView) ...[
            const SizedBox(height: 8),
            Text(
              'ลูกค้า: ${order.customerId}',
              style: const TextStyle(color: Color(0xFF777777), fontSize: 12),
            ),
            Text(
              'จัดส่ง: ${order.shippingAddress}',
              style: const TextStyle(color: Color(0xFF777777), fontSize: 12),
            ),
          ],
          if (order.slipImageUrl?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                order.slipImageUrl!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ],
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  order.paymentMethod,
                  style: const TextStyle(color: Color(0xFF777777)),
                ),
              ),
              Text(
                _formatPrice(order.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    final amount = price % 1 == 0
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
    return '฿$amount';
  }
}
