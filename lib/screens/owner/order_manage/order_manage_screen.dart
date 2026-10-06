// แสดงออเดอร์ร้านและจัดการการตรวจสอบการชำระเงิน
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_routes.dart';
import '../../../models/order_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/order_service.dart';
import '../../../widgets/order_list_content.dart';

class OrderManageScreen extends StatefulWidget {
  const OrderManageScreen({super.key});

  @override
  State<OrderManageScreen> createState() => _OrderManageScreenState();
}

class _OrderManageScreenState extends State<OrderManageScreen> {
  final _orderService = OrderService();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (auth.profile?.role != UserRole.owner) {
          return const Scaffold(
            body: Center(child: Text('หน้านี้สำหรับเจ้าของร้านเท่านั้น')),
          );
        }
        final ownerId = auth.profile!.id;
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
            leading: IconButton(
              tooltip: 'กลับ Dashboard',
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                AppRoutes.ownerDashboard,
              ),
              icon: const Icon(Icons.arrow_back),
            ),
            title: const Text(
              'จัดการออเดอร์',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          body: StreamBuilder<List<OrderModel>>(
            stream: _orderService.watchOrdersForOwner(ownerId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('โหลดคำสั่งซื้อไม่สำเร็จ'));
              }
              return OrderListContent(
                orders: snapshot.data ?? const [],
                ownerView: true,
                onConfirmPayment: (order) =>
                    _orderService.confirmPaymentAndDeductStock(order.id),
                onRejectPayment: (order) =>
                    _orderService.rejectPayment(order.id),
              );
            },
          ),
        );
      },
    );
  }
}
