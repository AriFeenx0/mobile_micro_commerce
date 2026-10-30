/// ฟอร์มสร้างคูปองใหม่โดยใช้โค้ดคูปองเป็นรหัสเอกสาร
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../models/coupon_model.dart';
import '../../../services/coupon_service.dart';

class CouponFormScreen extends StatefulWidget {
  /// สร้างหน้าฟอร์มสำหรับสร้างคูปอง
  const CouponFormScreen({super.key});

  /// สร้างสถานะของฟอร์มคูปอง
  @override
  State<CouponFormScreen> createState() => _CouponFormScreenState();
}

class _CouponFormScreenState extends State<CouponFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _couponService = CouponService();
  final _codeController = TextEditingController();
  final _valueController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _usageLimitController = TextEditingController();
  DiscountType _discountType = DiscountType.percent;
  DateTime? _expiresAt;
  bool _saving = false;

  /// คืนทรัพยากรของช่องกรอกข้อมูลคูปอง
  @override
  void dispose() {
    _codeController.dispose();
    _valueController.dispose();
    _minOrderController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }

  /// แสดงฟอร์มกำหนดโค้ด ส่วนลด เงื่อนไข และวันหมดอายุของคูปอง
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สร้างคูปอง')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_-]')),
                LengthLimitingTextInputFormatter(20),
              ],
              decoration: const InputDecoration(
                labelText: 'โค้ดคูปอง',
                helperText: 'A-Z 0-9 _ - ความยาว 3-20 ตัว เช่น BOOK50',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  CouponModel.isValidCode(CouponModel.normalizeCode(value ?? ''))
                  ? null
                  : 'โค้ดต้องมี 3-20 ตัว (A-Z 0-9 _ -)',
            ),
            const SizedBox(height: 16),
            SegmentedButton<DiscountType>(
              segments: const [
                ButtonSegment(
                  value: DiscountType.percent,
                  label: Text('ลดเป็น %'),
                ),
                ButtonSegment(
                  value: DiscountType.fixed,
                  label: Text('ลดเป็นบาท'),
                ),
              ],
              selected: {_discountType},
              onSelectionChanged: (value) =>
                  setState(() => _discountType = value.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valueController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: _discountType == DiscountType.percent
                    ? 'เปอร์เซ็นต์ส่วนลด (1-100)'
                    : 'ส่วนลด (บาท)',
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                final number = double.tryParse((value ?? '').trim());
                if (number == null || number <= 0) return 'กรุณากรอกส่วนลด';
                if (_discountType == DiscountType.percent && number > 100) {
                  return 'เปอร์เซ็นต์ต้องไม่เกิน 100';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minOrderController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'ยอดซื้อขั้นต่ำ (บาท) เว้นว่าง = ไม่มี',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) return null;
                final number = double.tryParse(text);
                return number == null || number < 0
                    ? 'ยอดขั้นต่ำไม่ถูกต้อง'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usageLimitController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'จำนวนครั้งที่ใช้ได้ เว้นว่าง = ไม่จำกัด',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickExpiry,
              icon: const Icon(Icons.event_outlined),
              label: Text(
                _expiresAt == null
                    ? 'ไม่กำหนดวันหมดอายุ (แตะเพื่อเลือก)'
                    : 'หมดอายุ ${DateFormat('d MMM yyyy').format(_expiresAt!)}',
              ),
            ),
            if (_expiresAt != null)
              TextButton(
                onPressed: () => setState(() => _expiresAt = null),
                child: const Text('ล้างวันหมดอายุ'),
              ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('สร้างคูปอง'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// เลือกวันหมดอายุและกำหนดเวลาให้สิ้นสุดในวันนั้น
  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked == null) return;
    // หมดอายุสิ้นวันของวันที่เลือก
    setState(
      () => _expiresAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        23,
        59,
        59,
      ),
    );
  }

  /// ตรวจสอบข้อมูลและสร้างคูปองใหม่
  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await _couponService.createCoupon(
        rawCode: _codeController.text,
        discountType: _discountType,
        discountValue: double.parse(_valueController.text.trim()),
        minOrderAmount: double.tryParse(_minOrderController.text.trim()) ?? 0,
        usageLimit: int.tryParse(_usageLimitController.text.trim()) ?? 0,
        expiresAt: _expiresAt,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('สร้างคูปองแล้ว')));
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message.toString()
                : error is ArgumentError
                ? error.message.toString()
                : 'สร้างคูปองไม่สำเร็จ กรุณาลองใหม่',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
