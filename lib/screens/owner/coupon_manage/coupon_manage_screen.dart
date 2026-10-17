// หน้าจัดการคูปองของเจ้าของร้าน แสดงรายการ เปิด/ปิดใช้งาน และสร้างคูปองใหม่
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/coupon_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/coupon_service.dart';
import 'coupon_form_screen.dart';

class CouponManageScreen extends StatefulWidget {
  const CouponManageScreen({super.key});

  @override
  State<CouponManageScreen> createState() => _CouponManageScreenState();
}

class _CouponManageScreenState extends State<CouponManageScreen> {
  final _couponService = CouponService();
  String? _streamOwnerId;
  Stream<List<CouponModel>>? _couponStream;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    if (profile == null || profile.role != UserRole.owner) {
      return Scaffold(
        appBar: AppBar(title: const Text('จัดการคูปอง')),
        body: const Center(child: Text('หน้านี้สำหรับบัญชีเจ้าของร้านเท่านั้น')),
      );
    }
    if (_streamOwnerId != profile.id) {
      _streamOwnerId = profile.id;
      _couponStream = _couponService.watchCouponsForOwner(profile.id);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('จัดการคูปอง'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push<void>(
          context,
          MaterialPageRoute<void>(builder: (_) => const CouponFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('สร้างคูปอง'),
      ),
      body: StreamBuilder<List<CouponModel>>(
        stream: _couponStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('โหลดคูปองไม่สำเร็จ'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final coupons = snapshot.data!;
          if (coupons.isEmpty) {
            return const Center(child: Text('ยังไม่มีคูปอง'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
            itemCount: coupons.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _CouponTile(
              coupon: coupons[index],
              onToggle: (value) => _toggle(coupons[index], value),
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggle(CouponModel coupon, bool value) async {
    try {
      await _couponService.setActive(coupon.id, value);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message.toString()
                : 'อัปเดตคูปองไม่สำเร็จ',
          ),
        ),
      );
    }
  }
}

class _CouponTile extends StatelessWidget {
  const _CouponTile({required this.coupon, required this.onToggle});

  final CouponModel coupon;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final discount = coupon.discountType == DiscountType.percent
        ? 'ลด ${coupon.discountValue.toStringAsFixed(0)}%'
        : 'ลด ${coupon.discountValue.toStringAsFixed(0)} บาท';
    final usage = coupon.usageLimit > 0
        ? 'ใช้แล้ว ${coupon.usedCount}/${coupon.usageLimit}'
              '${coupon.reservedCount > 0 ? ' (รอยืนยัน ${coupon.reservedCount})' : ''}'
        : 'ใช้แล้ว ${coupon.usedCount} (ไม่จำกัด)';
    final expiry = coupon.expiresAt == null
        ? 'ไม่มีวันหมดอายุ'
        : 'หมดอายุ ${DateFormat('d MMM yyyy HH:mm').format(coupon.expiresAt!)}';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon.code,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$discount${coupon.minOrderAmount > 0 ? ' · ขั้นต่ำ ${coupon.minOrderAmount.toStringAsFixed(0)} บาท' : ''}',
                ),
                Text(
                  usage,
                  style: const TextStyle(color: Color(0xFF777777)),
                ),
                Text(
                  expiry,
                  style: const TextStyle(color: Color(0xFF777777)),
                ),
              ],
            ),
          ),
          Switch(value: coupon.isActive, onChanged: onToggle),
        ],
      ),
    );
  }
}