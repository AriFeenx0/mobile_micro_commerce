import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import 'slip_upload_screen.dart';

enum _PaymentMethod { promptPay, bankTransfer }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const double _shippingFee = 20;
  final _addressController = TextEditingController();
  String? _addressProfileId;
  _PaymentMethod _paymentMethod = _PaymentMethod.promptPay;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = Provider.of<AuthProvider>(context).profile;
    if (profile != null && profile.id != _addressProfileId) {
      _addressController.text = profile.address;
      _addressProfileId = profile.id;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final total = cart.total + _shippingFee;
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('เตรียมชำระเงิน'),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
          ),
          body: cart.items.isEmpty
              ? const Center(child: Text('ไม่มีสินค้าในตะกร้า'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionLabel('ที่อยู่จัดส่ง'),
                            const SizedBox(height: 8),
                            _OutlinedPanel(
                              child: TextField(
                                controller: _addressController,
                                minLines: 2,
                                maxLines: 3,
                                textInputAction: TextInputAction.newline,
                                decoration: const InputDecoration(
                                  hintText:
                                      'กรอกชื่อผู้รับ เบอร์โทร และที่อยู่จัดส่ง',
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const _SectionLabel('สรุปคำสั่งซื้อ'),
                            const SizedBox(height: 8),
                            for (final item in cart.items)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.book.title} เล่ม ${item.volume.volumeNumber} x ${item.quantity}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(_formatPrice(item.subtotal)),
                                  ],
                                ),
                              ),
                            Row(
                              children: [
                                const Expanded(child: Text('ค่าส่ง')),
                                Text(_formatPrice(_shippingFee)),
                              ],
                            ),
                            const SizedBox(height: 28),
                            const _SectionLabel('ใช้คูปอง'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  height: 48,
                                  child: FilledButton(
                                    onPressed: () {},
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF333333),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('ใช้'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            const _SectionLabel('ช่องทางการชำระเงิน'),
                            const SizedBox(height: 8),
                            _PaymentMethodOption(
                              title: 'QR พร้อมเพย์',
                              icon: Icons.qr_code_2,
                              selected:
                                  _paymentMethod == _PaymentMethod.promptPay,
                              onTap: () => setState(
                                () => _paymentMethod = _PaymentMethod.promptPay,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _PaymentMethodOption(
                              title: 'โอนผ่านธนาคาร',
                              icon: Icons.account_balance_outlined,
                              selected:
                                  _paymentMethod == _PaymentMethod.bankTransfer,
                              onTap: () => setState(
                                () => _paymentMethod =
                                    _PaymentMethod.bankTransfer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'ยอดรวม',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  _formatPrice(total),
                                  style: const TextStyle(
                                    fontSize: 22,
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
                                onPressed:
                                    _paymentMethod ==
                                        _PaymentMethod.bankTransfer
                                    ? () => Navigator.push<void>(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (_) => SlipUploadScreen(
                                            amount: total,
                                            shippingAddress: _addressController
                                                .text
                                                .trim(),
                                            shippingFee: _shippingFee,
                                          ),
                                        ),
                                      )
                                    : null,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF333333),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text(
                                  'ยืนยันการสั่งสินค้า',
                                  style: TextStyle(fontSize: 17),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  String _formatPrice(double price) {
    final amount = price % 1 == 0
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
    return '฿$amount';
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(color: Color(0xFF777777), fontSize: 14),
  );
}

class _OutlinedPanel extends StatelessWidget {
  const _OutlinedPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _PaymentMethodOption extends StatelessWidget {
  const _PaymentMethodOption({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? Colors.black : const Color(0xFFBDBDBD),
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF444444)),
              const SizedBox(width: 10),
              Expanded(child: Text(title)),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF333333)
                        : const Color(0xFF999999),
                    width: selected ? 6 : 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
