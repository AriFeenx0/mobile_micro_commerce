/// แสดงข้อมูลการชำระเงินและให้ลูกค้าส่งสลิปยืนยันคำสั่งซื้อ
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/utils/promptpay.dart';
import '../../../models/user_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../services/chat_service.dart';
import '../../../services/order_service.dart';

class SlipUploadScreen extends StatefulWidget {
  const SlipUploadScreen({
    super.key,
    required this.orderId,
    required this.amount,
    this.clearCartOnSuccess = false,
    this.usePromptPay = true,
  });

  final String orderId;
  final double amount;
  final bool clearCartOnSuccess;
  final bool usePromptPay;

  /// สร้างสถานะสำหรับเลือกสลิปและส่งคำสั่งซื้อ
  @override
  State<SlipUploadScreen> createState() => _SlipUploadScreenState();
}

class _SlipUploadScreenState extends State<SlipUploadScreen> {
  final _imagePicker = ImagePicker();
  final _orderService = OrderService();
  late final Future<UserModel?> _ownerFuture = ChatService().getOwner();
  XFile? _slipImage;
  Uint8List? _slipBytes;
  bool _isPicking = false;
  bool _isSubmitting = false;

  /// แสดงข้อมูลบัญชีหรือ QR พร้อมเพย์ ช่องแนบสลิป และปุ่มส่ง
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
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'กรุณาส่งสลิปภายใน 15 นาที หลังจากนั้นระบบจะคืนสต็อก',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFB05C00)),
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
                  child: FutureBuilder<UserModel?>(
                    future: _ownerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final owner = snapshot.data;
                      if (!widget.usePromptPay) {
                        if (owner == null || !owner.hasBankAccount) {
                          return const Text(
                            'ร้านยังไม่ได้ตั้งค่าบัญชีธนาคาร กรุณาติดต่อร้านค้า',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFFB05C00)),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              owner.bankName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('ชื่อบัญชี: ${owner.bankAccountName}'),
                            const SizedBox(height: 4),
                            SelectableText(
                              'เลขที่บัญชี: ${owner.bankAccountNumber}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        );
                      }
                      final phone = owner?.phone.trim() ?? '';
                      if (owner == null || phone.isEmpty) {
                        return const Text(
                          'ร้านยังไม่ได้ตั้งเบอร์ PromptPay กรุณาติดต่อร้านค้า',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFFB05C00)),
                        );
                      }
                      return Column(
                        children: [
                          const Text(
                            'สแกนจ่ายด้วย PromptPay',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            color: Colors.white,
                            child: QrImageView(
                              data: PromptPay.payload(
                                phone,
                                amount: widget.amount,
                              ),
                              size: 220,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(owner.name),
                          const SizedBox(height: 4),
                          Text(
                            'ยอด ${_formatPrice(widget.amount)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      );
                    },
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

  /// เลือกรูปสลิปจากแกลเลอรีและเตรียมข้อมูลสำหรับแสดงตัวอย่าง
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

  /// ส่งสลิป บันทึกสถานะคำสั่งซื้อ และกลับไปยังประวัติคำสั่งซื้อ
  Future<void> _submitOrder() async {
    final slipImage = _slipImage;
    if (slipImage == null || _isSubmitting) return;

    final cart = context.read<CartProvider>();

    setState(() => _isSubmitting = true);
    try {
      await _orderService.submitSlip(
        orderId: widget.orderId,
        slipImage: slipImage,
      );
      if (!mounted) return;
      if (widget.clearCartOnSuccess) cart.clearCurrentUserCart();
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

  /// แสดงข้อความแจ้งผลผ่าน SnackBar
  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// จัดรูปแบบยอดชำระเป็นเงินบาทโดยตัดทศนิยมที่เป็นศูนย์
  String _formatPrice(double price) {
    final amount = price % 1 == 0
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
    return '฿$amount';
  }

  /// แปลงข้อผิดพลาด Firebase เป็นข้อความภาษาไทยสำหรับผู้ใช้
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

  /// แสดงป้ายชื่อส่วนในหน้าชำระเงิน
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(color: Color(0xFF999999), fontSize: 15),
  );
}

class _DashedBorderPainter extends CustomPainter {
  /// วาดกรอบเส้นประรอบพื้นที่แนบสลิป
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

  /// ไม่วาดกรอบซ้ำเมื่อ painter เดิมยังใช้งานได้
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
