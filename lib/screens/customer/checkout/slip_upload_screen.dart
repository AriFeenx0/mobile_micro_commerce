// เลือกรูปสลิปและส่งคำสั่งซื้อเพื่อรอตรวจสอบ
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_routes.dart';
import '../../../models/order_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../services/order_service.dart';

class SlipUploadScreen extends StatefulWidget {
  const SlipUploadScreen({
    super.key,
    required this.amount,
    required this.shippingAddress,
    required this.shippingFee,
  });

  final double amount;
  final String shippingAddress;
  final double shippingFee;

  @override
  State<SlipUploadScreen> createState() => _SlipUploadScreenState();
}

class _SlipUploadScreenState extends State<SlipUploadScreen> {
  final _imagePicker = ImagePicker();
  final _orderService = OrderService();
  XFile? _slipImage;
  Uint8List? _slipBytes;
  bool _isPicking = false;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ชำระเงิน'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                const Center(
                  child: Text(
                    'แนบสลิปการโอนเงิน',
                    style: TextStyle(fontSize: 17, color: Color(0xFF777777)),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'ยอดที่ต้องชำระ',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF999999), fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatPrice(widget.amount),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 28),
                const _SectionLabel('แนบสลิปการโอนเงิน'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ธนาคารกสิกรไทย',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 6),
                      Text('ชื่อบัญชี: ร้านหนังสือตัวอย่าง'),
                      SizedBox(height: 4),
                      Text(
                        'เลขที่บัญชี: 123-4-56789-0',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  button: true,
                  label: 'เลือกรูปสลิป',
                  child: GestureDetector(
                    onTap: _isPicking ? null : _pickSlip,
                    child: CustomPaint(
                      painter: _DashedBorderPainter(),
                      child: SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: _isPicking
                            ? const Center(child: CircularProgressIndicator())
                            : _slipBytes == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.upload_outlined,
                                    size: 56,
                                    color: Color(0xFF999999),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'แตะเพื่อเลือกรูปสลิป',
                                    style: TextStyle(
                                      color: Color(0xFF888888),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  _slipBytes!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                if (_slipBytes != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _pickSlip,
                    icon: const Icon(Icons.refresh),
                    label: const Text('เลือกรูปใหม่'),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _slipImage == null || _isSubmitting
                      ? null
                      : _submitOrder,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF333333),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'ส่งสลิปเพื่อยืนยัน',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickSlip() async {
    setState(() => _isPicking = true);
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _slipImage = image;
        _slipBytes = bytes;
      });
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _submitOrder() async {
    final slipImage = _slipImage;
    if (slipImage == null || _isSubmitting) return;

    final cart = context.read<CartProvider>();
    final cartItems = cart.items;
    if (cartItems.isEmpty) {
      _showMessage('ไม่พบสินค้าในตะกร้า');
      return;
    }

    final ownerIds = cartItems.map((item) => item.book.ownerId).toSet();
    if (ownerIds.length != 1 || ownerIds.single.isEmpty) {
      _showMessage('คำสั่งซื้อนี้ต้องเป็นสินค้าจาก owner คนเดียว');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _orderService.createOrder(
        ownerId: ownerIds.single,
        items: cartItems
            .map(
              (item) => OrderItem(
                bookId: item.book.id,
                volumeId: item.volume.id,
                title: item.book.title,
                volumeNumber: item.volume.volumeNumber,
                price: item.volume.price,
                qty: item.quantity,
              ),
            )
            .toList(),
        shippingAddress: widget.shippingAddress,
        shippingFee: widget.shippingFee,
        slipImage: slipImage,
      );
      if (!mounted) return;
      cart.clearCurrentUserCart();
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.customerOrderHistory,
        (_) => false,
      );
    } catch (error) {
      if (mounted) {
        _showMessage(
          error is StateError
              ? error.message.toString()
              : error is FirebaseException
              ? _firebaseErrorMessage(error)
              : 'บันทึกคำสั่งซื้อไม่สำเร็จ กรุณาตรวจสอบการเชื่อมต่อ',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatPrice(double price) {
    final amount = price % 1 == 0
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
    return '฿$amount';
  }

  String _firebaseErrorMessage(FirebaseException error) {
    debugPrint(
      'Order submission Firebase error [${error.plugin}/${error.code}]: '
      '${error.message}',
    );
    return switch (error.code) {
      'permission-denied' =>
        'ไม่มีสิทธิ์บันทึกคำสั่งซื้อ ตรวจสอบ Firestore Rules และบัญชีที่เข้าสู่ระบบ',
      'unavailable' || 'network-request-failed' =>
        'เชื่อมต่อ Firebase ไม่ได้ กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่',
      _ =>
        'บันทึกคำสั่งซื้อไม่สำเร็จ (${error.code}): '
            '${error.message ?? 'ไม่ทราบสาเหตุ'}',
    };
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(color: Color(0xFF999999), fontSize: 15),
  );
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const radius = Radius.circular(14);
    const dashWidth = 8.0;
    const dashSpace = 6.0;
    const strokeWidth = 1.8;
    final paint = Paint()
      ..color = const Color(0xFFB8B8B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      radius,
    ).deflate(strokeWidth / 2);
    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
