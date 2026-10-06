import 'package:flutter/material.dart';

import '../models/order_model.dart';

class OrderListContent extends StatefulWidget {
  const OrderListContent({
    super.key,
    required this.orders,
    this.ownerView = false,
    this.onConfirmPayment,
    this.onRejectPayment,
  });

  final List<OrderModel> orders;
  final bool ownerView;
  final Future<void> Function(OrderModel order)? onConfirmPayment;
  final Future<void> Function(OrderModel order)? onRejectPayment;

  @override
  State<OrderListContent> createState() => _OrderListContentState();
}

class _OrderListContentState extends State<OrderListContent> {
  OrderStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final orders = widget.orders.where((order) {
      return _selectedStatus == null || order.status == _selectedStatus;
    }).toList();

    return Column(
      children: [
        if (widget.ownerView) _buildFilters(),
        Expanded(
          child: orders.isEmpty
              ? Center(
                  child: Text(
                    widget.orders.isEmpty
                        ? 'ยังไม่มีคำสั่งซื้อ'
                        : 'ไม่มีออเดอร์ในสถานะนี้',
                    style: const TextStyle(color: Color(0xFF777777)),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) => _OrderCard(
                    order: orders[index],
                    ownerView: widget.ownerView,
                    onConfirmPayment: widget.onConfirmPayment,
                    onRejectPayment: widget.onRejectPayment,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final pendingCount = widget.orders
        .where((order) => order.status == OrderStatus.pendingSlipReview)
        .length;
    final filters = <(String, OrderStatus?)>[
      ('ทั้งหมด', null),
      ('รอตรวจสอบ($pendingCount)', OrderStatus.pendingSlipReview),
      ('ชำระแล้ว', OrderStatus.paid),
      ('จัดส่ง', OrderStatus.shipped),
    ];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (label, status) = filters[index];
          final selected = _selectedStatus == status;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => setState(() => _selectedStatus = status),
            showCheckmark: false,
            labelStyle: TextStyle(
              color: selected ? Colors.white : const Color(0xFF666666),
              fontSize: 14,
            ),
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFF333333),
            side: BorderSide(
              color: selected
                  ? const Color(0xFF333333)
                  : const Color(0xFFCCCCCC),
              width: 1.5,
            ),
            shape: const StadiumBorder(),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  const _OrderCard({
    required this.order,
    required this.ownerView,
    this.onConfirmPayment,
    this.onRejectPayment,
  });

  final OrderModel order;
  final bool ownerView;
  final Future<void> Function(OrderModel order)? onConfirmPayment;
  final Future<void> Function(OrderModel order)? onRejectPayment;

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _isProcessing = false;

  Color _statusBorderColor(OrderStatus status) => switch (status) {
    OrderStatus.pendingPayment ||
    OrderStatus.pendingSlipReview => const Color(0xFFE9BE58),
    OrderStatus.paid => const Color(0xFF8FC995),
    OrderStatus.shipped => const Color(0xFF8AB4CF),
    OrderStatus.cancelled => const Color(0xFFDDDDDD),
  };

  String _shortId(String id) {
    final normalized = id.toUpperCase();
    return normalized.length <= 4
        ? normalized
        : normalized.substring(normalized.length - 4);
  }

  String _formatPrice(double price) {
    final amount = price % 1 == 0
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
    return '฿$amount';
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isReviewing = order.status == OrderStatus.pendingSlipReview;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: order.status == OrderStatus.cancelled
            ? const Color(0xFFFAFAFA)
            : Colors.white,
        border: Border.all(
          color: _statusBorderColor(order.status),
          width: isReviewing ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.ownerView ? 'ลูกค้า ${_shortId(order.customerId)}' : 'คำสั่งซื้อ'}  •  #ORD-${_shortId(order.id)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                '${item.title} เล่ม ${item.volumeNumber} ×${item.qty}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF666666), fontSize: 14),
              ),
            ),
          Row(
            children: [
              const Text('ยอดชำระ', style: TextStyle(color: Color(0xFF666666))),
              const SizedBox(width: 6),
              Text(
                _formatPrice(order.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              const Text('•', style: TextStyle(color: Color(0xFF888888))),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.paymentMethod,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF666666)),
                ),
              ),
            ],
          ),
          if (widget.ownerView) ...[
            const SizedBox(height: 8),
            Text(
              'จัดส่ง: ${order.shippingAddress}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF777777), fontSize: 12),
            ),
          ],
          if (widget.ownerView && isReviewing) ...[
            const SizedBox(height: 12),
            if (order.slipImageUrl?.isNotEmpty == true)
              InkWell(
                onTap: () => _showSlip(order.slipImageUrl!),
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        order.slipImageUrl!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const _SlipPlaceholder(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ดูสลิปเต็มขนาด',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'แตะเพื่อขยายรูปสลิป',
                            style: TextStyle(color: Color(0xFF888888)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              const Row(
                children: [
                  _SlipPlaceholder(),
                  SizedBox(width: 12),
                  Text('ไม่มีรูปสลิปแนบ'),
                ],
              ),
          ],
          if (widget.ownerView && isReviewing) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : _rejectPayment,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF555555),
                      side: const BorderSide(color: Color(0xFF999999)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: const Text('ปฏิเสธ'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 5,
                  child: FilledButton(
                    onPressed: _isProcessing ? null : _confirmPayment,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF333333),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('ยืนยันการชำระ'),
                  ),
                ),
              ],
            ),
          ] else if (widget.ownerView && order.status == OrderStatus.paid)
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: null,
                child: const Text('ชำระแล้ว'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmPayment() async {
    final callback = widget.onConfirmPayment;
    if (callback == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ยืนยันการชำระเงิน'),
        content: Text(
          'ยืนยันว่าได้รับยอด ${_formatPrice(widget.order.totalAmount)} แล้วหรือไม่?\nการยืนยันจะตัดสต๊อกหนังสือทันที',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('กลับไปตรวจสอบ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ยืนยันและตัดสต๊อก'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runAction(callback, successMessage: 'ยืนยันชำระเงินและตัดสต๊อกแล้ว');
  }

  Future<void> _rejectPayment() async {
    final callback = widget.onRejectPayment;
    if (callback == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ปฏิเสธสลิป?'),
        content: const Text('คำสั่งซื้อจะถูกยกเลิกและไม่มีการตัดสต๊อก'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('กลับไปตรวจสอบ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ปฏิเสธสลิป'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runAction(callback, successMessage: 'ปฏิเสธสลิปแล้ว');
  }

  Future<void> _runAction(
    Future<void> Function(OrderModel order) action, {
    required String successMessage,
  }) async {
    setState(() => _isProcessing = true);
    try {
      await action(widget.order);
      if (mounted) _showMessage(successMessage);
    } catch (error) {
      if (mounted) _showMessage(_actionErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showSlip(String imageUrl) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('เปิดรูปสลิปไม่ได้'),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton.filledTonal(
                tooltip: 'ปิด',
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _actionErrorMessage(Object error) => error is StateError
      ? error.message.toString()
      : 'ดำเนินการไม่สำเร็จ: $error';
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, background) = switch (status) {
      OrderStatus.pendingPayment => (
        'รอชำระ',
        const Color(0xFFE5A900),
        const Color(0xFFFFF7E4),
      ),
      OrderStatus.pendingSlipReview => (
        'รอตรวจสอบ',
        const Color(0xFFE5A900),
        const Color(0xFFFFF7E4),
      ),
      OrderStatus.paid => (
        'ชำระแล้ว',
        const Color(0xFF5AA86A),
        const Color(0xFFEEF7EF),
      ),
      OrderStatus.shipped => (
        'จัดส่งแล้ว',
        const Color(0xFF5790B5),
        const Color(0xFFEEF5F9),
      ),
      OrderStatus.cancelled => (
        'ยกเลิก',
        const Color(0xFF999999),
        const Color(0xFFF4F4F4),
      ),
    };
    return Container(
      constraints: const BoxConstraints(minWidth: 84),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
}

class _SlipPlaceholder extends StatelessWidget {
  const _SlipPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        border: Border.all(color: const Color(0xFFCCCCCC), width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text('สลิป', style: TextStyle(color: Color(0xFF999999))),
    );
  }
}
