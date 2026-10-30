/// แสดงคูปองที่ใช้งานได้และให้ลูกค้าคัดลอกรหัสไปใช้ตอนชำระเงิน
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../models/coupon_model.dart';
import '../../../services/coupon_service.dart';

class CustomerCouponsScreen extends StatefulWidget {
  const CustomerCouponsScreen({super.key});

  /// สร้างสถานะสำหรับติดตามรายการคูปอง
  @override
  State<CustomerCouponsScreen> createState() => _CustomerCouponsScreenState();
}

class _CustomerCouponsScreenState extends State<CustomerCouponsScreen> {
  late final Stream<List<CouponModel>> _stream = CouponService()
      .watchActiveCoupons();

  /// แสดงคูปองที่ใช้ได้ พร้อมสถานะโหลด ผิดพลาด หรือไม่มีรายการ
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('คูปองของฉัน'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: StreamBuilder<List<CouponModel>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('โหลดคูปองไม่สำเร็จ'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final coupons = snapshot.data!;
          if (coupons.isEmpty) {
            return const Center(child: Text('ยังไม่มีคูปองที่ใช้ได้ในขณะนี้'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: coupons.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _CouponCard(coupons[index]),
          );
        },
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard(this.coupon);

  final CouponModel coupon;

  /// แสดงรายละเอียดคูปองและปุ่มคัดลอกรหัส
  @override
  Widget build(BuildContext context) {
    final discount = coupon.discountType == DiscountType.percent
        ? 'ลด ${coupon.discountValue.toStringAsFixed(0)}%'
        : 'ลด ${coupon.discountValue.toStringAsFixed(0)} บาท';
    final conditions = [
      if (coupon.minOrderAmount > 0)
        'ขั้นต่ำ ${coupon.minOrderAmount.toStringAsFixed(0)} บาท',
      coupon.expiresAt == null
          ? 'ไม่มีวันหมดอายุ'
          : 'หมดอายุ ${DateFormat('d MMM yyyy').format(coupon.expiresAt!)}',
    ].join(' · ');

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
                Text(discount),
                Text(
                  conditions,
                  style: const TextStyle(color: Color(0xFF777777)),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'คัดลอกโค้ด',
            icon: const Icon(Icons.copy_outlined),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: coupon.code));
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text('คัดลอกโค้ด ${coupon.code} แล้ว')),
                );
            },
          ),
        ],
      ),
    );
  }
}
