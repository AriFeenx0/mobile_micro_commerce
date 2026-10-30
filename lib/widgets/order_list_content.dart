/// แสดงรายการคำสั่งซื้อและปุ่มจัดการตามบทบาท
import 'package:flutter/material.dart';

import '../models/order_model.dart';
import '../screens/customer/checkout/slip_upload_screen.dart';

/// แสดงรายการออเดอร์พร้อมตัวกรองและการจัดการชำระเงินตามบทบาท
class OrderListContent extends StatefulWidget {
  /// รับรายการออเดอร์ รูปแบบการแสดงผล และ callback สำหรับจัดการการชำระเงิน
  const OrderListContent({
    super.key,
    required this.orders,
    this.ownerView = false,
    this.onConfirmPayment,
    this.onRejectPayment,
  });

  // รายการออเดอร์ที่ต้องแสดง และกำหนดว่าเป็นมุมมองเจ้าของร้านหรือไม่
  final List<OrderModel> orders;
  final bool ownerView;

  // callback ที่หน้าจอภายนอกใช้ยืนยันหรือปฏิเสธสลิปของออเดอร์
  final Future<void> Function(OrderModel order)? onConfirmPayment;
  final Future<void> Function(OrderModel order)? onRejectPayment;

  /// สร้าง state สำหรับจำตัวกรองสถานะที่ผู้ใช้เลือก
  @override
  State<OrderListContent> createState() => _OrderListContentState();
}

/// เก็บตัวกรองที่เลือกและสร้างรายการออเดอร์
class _OrderListContentState extends State<OrderListContent> {
  // null หมายถึงแสดงทุกสถานะ
  OrderStatus? _selectedStatus;

  /// สร้างรายการออเดอร์และตัวกรองที่เกี่ยวข้องกับมุมมองปัจจุบัน
  @override
  Widget build(BuildContext context) {
    // กรองออเดอร์ตามสถานะที่เลือก ก่อนนำไปแสดงในรายการ
    final orders = widget.orders.where((order) {
      return _selectedStatus == null || order.status == _selectedStatus;
    }).toList();

    // แสดงตัวกรองเฉพาะเจ้าของร้าน และแสดงข้อความเมื่อไม่มีออเดอร์ที่ตรงเงื่อนไข
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

  /// สร้างชิปตัวกรองสถานะ พร้อมจำนวนออเดอร์ที่รอตรวจสลิป
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
          // เปลี่ยนสถานะตัวกรองเมื่อผู้ใช้เลือกชิป
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

/// การ์ดออเดอร์พร้อมข้อมูลและปุ่มตามบทบาทผู้ใช้งาน
class _OrderCard extends StatefulWidget {
  /// รับออเดอร์ รูปแบบมุมมอง และ callback สำหรับการตรวจสอบการชำระเงิน
  const _OrderCard({
    required this.order,
    required this.ownerView,
    this.onConfirmPayment,
    this.onRejectPayment,
  });

  // ข้อมูลออเดอร์และการตั้งค่าการทำงานของการ์ด
  final OrderModel order;
  final bool ownerView;
  final Future<void> Function(OrderModel order)? onConfirmPayment;
  final Future<void> Function(OrderModel order)? onRejectPayment;

  /// สร้าง state ภายในเพื่อจัดการสถานะการทำงานของปุ่ม
  @override
  State<_OrderCard> createState() => _OrderCardState();
}

/// จัดการการกระทำในออเดอร์และสถานะการทำงานของปุ่ม
class _OrderCardState extends State<_OrderCard> {
  // ป้องกันการกดปุ่มยืนยันหรือปฏิเสธซ้ำระหว่างรอ callback
  bool _isProcessing = false;

  /// คืนค่าสีเส้นขอบของการ์ดตามสถานะออเดอร์
  Color _statusBorderColor(OrderStatus status) => switch (status) {
    OrderStatus.pendingPayment ||
    OrderStatus.pendingSlipReview => const Color(0xFFE9BE58),
    OrderStatus.paid => const Color(0xFF8FC995),
    OrderStatus.shipped => const Color(0xFF8AB4CF),
    OrderStatus.cancelled => const Color(0xFFDDDDDD),
  };

  /// คืนรหัสตัวพิมพ์ใหญ่ 4 ตัวท้าย หรือรหัสทั้งหมดเมื่อสั้นกว่านั้น
  String _shortId(String id) {
    final normalized = id.toUpperCase();
    return normalized.length <= 4
        ? normalized
        : normalized.substring(normalized.length - 4);
  }

  /// จัดรูปแบบราคาเป็นเงินบาท โดยไม่แสดงทศนิยมเมื่อเป็นจำนวนเต็ม
  String _formatPrice(double price) {
    final amount = price % 1 == 0
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
    return '฿$amount';
  }

  /// สร้างการ์ดออเดอร์และปุ่มที่สอดคล้องกับบทบาทและสถานะ
  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    // ตรวจว่าสลิปรอการตรวจสอบ และการจองสินค้าหมดเวลาแล้วหรือยัง
    final isReviewing = order.status == OrderStatus.pendingSlipReview;
    final reservationExpired =
        order.status == OrderStatus.pendingPayment &&
        order.lockExpiresAt != null &&
        !order.lockExpiresAt!.isAfter(DateTime.now());
    // เนื้อหาการ์ดประกอบด้วยหัวข้อ สถานะ รายการสินค้า ยอดชำระ และปุ่มตามเงื่อนไข
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
              _StatusBadge(
                status: order.status,
                reservationExpired: reservationExpired,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // แสดงชื่อสินค้า จำนวนเล่ม และจำนวนชิ้นในออเดอร์
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
            // แสดงยอดชำระและช่องทางชำระเงินในแถวเดียวกัน
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
          // แสดงที่อยู่จัดส่งในมุมมองเจ้าของร้านเท่านั้น
          if (widget.ownerView) ...[
            const SizedBox(height: 8),
            Text(
              'จัดส่ง: ${order.shippingAddress}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF777777), fontSize: 12),
            ),
          ],
          // เจ้าของร้านดูรูปสลิปขนาดย่อหรือข้อความเมื่อไม่มีรูปแนบ
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
          // แสดงปุ่มยืนยันและปฏิเสธเมื่อเจ้าของร้านกำลังตรวจสลิป
          if (widget.ownerView && isReviewing) ...[
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
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
                const SizedBox(height: 8),
                OutlinedButton(
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
              ],
            ),
            // ลูกค้าส่งสลิปได้เมื่อยังรอชำระและเวลาจองยังไม่หมด
          ] else if (!widget.ownerView &&
              order.status == OrderStatus.pendingPayment &&
              !reservationExpired) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => SlipUploadScreen(
                      orderId: order.id,
                      amount: order.totalAmount,
                    ),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF333333),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: const Text('ส่งสลิปชำระเงิน'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ขอคำยืนยันก่อนเรียก callback เพื่อบันทึกการชำระและตัดสต็อก
  Future<void> _confirmPayment() async {
    final callback = widget.onConfirmPayment;
    if (callback == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ยืนยันการชำระเงิน'),
        content: Text(
          'ยืนยันว่าได้รับยอด ${_formatPrice(widget.order.totalAmount)} แล้วหรือไม่?\nการยืนยันจะตัดสต็อกหนังสือทันที',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('กลับไปตรวจสอบ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ยืนยันและตัดสต็อก'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runAction(callback, successMessage: 'ยืนยันชำระเงินและตัดสต็อกแล้ว');
  }

  /// ขอคำยืนยันก่อนเรียก callback เพื่อปฏิเสธสลิป
  Future<void> _rejectPayment() async {
    final callback = widget.onRejectPayment;
    if (callback == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ปฏิเสธสลิป?'),
        content: const Text('คำสั่งซื้อจะถูกยกเลิกและไม่มีการตัดสต็อก'),
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

  /// เรียกการจัดการออเดอร์และแจ้งผลสำเร็จหรือข้อผิดพลาด
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

  /// เปิดรูปสลิปในหน้าต่างขยายที่ซูมและเลื่อนได้
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

  /// แสดงข้อความแจ้งผลการทำงานด้านล่างหน้าจอ
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// คืนข้อความจาก [StateError] หรือข้อความข้อผิดพลาดทั่วไป
  String _actionErrorMessage(Object error) => error is StateError
      ? error.message.toString()
      : 'ดำเนินการไม่สำเร็จ: $error';
}

/// ป้ายสถานะออเดอร์ หรือแจ้งเมื่อการจองหมดเวลา
class _StatusBadge extends StatelessWidget {
  /// สร้างป้ายสถานะออเดอร์ พร้อมตัวเลือกแสดงการจองหมดเวลา
  const _StatusBadge({required this.status, this.reservationExpired = false});

  // สถานะออเดอร์และ flag สำหรับกรณีการจองหมดเวลา
  final OrderStatus status;
  final bool reservationExpired;

  /// สร้างป้ายพร้อมข้อความและสีตามสถานะหรือเวลาจอง
  @override
  Widget build(BuildContext context) {
    // สถานะหมดเวลาจองมีรูปแบบเฉพาะ และแสดงแทนป้ายสถานะปกติ
    if (reservationExpired) {
      return Container(
        constraints: const BoxConstraints(minWidth: 84),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          border: Border.all(color: const Color(0xFF999999), width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'หมดเวลาจอง',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF777777), fontSize: 12),
        ),
      );
    }
    // กำหนดข้อความ สีตัวอักษร และสีพื้นหลังของแต่ละสถานะ
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

/// กล่องภาพสำรองเมื่อไม่มีรูปสลิปหรือโหลดภาพไม่สำเร็จ
class _SlipPlaceholder extends StatelessWidget {
  /// สร้างกล่องภาพสำรองสำหรับสลิป
  const _SlipPlaceholder();

  /// สร้างกล่องสำรองที่มีขนาดเท่าภาพสลิป
  @override
  Widget build(BuildContext context) {
    // กล่องขนาดเดียวกับภาพสลิป เพื่อรักษาการจัดวางของแถว
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
