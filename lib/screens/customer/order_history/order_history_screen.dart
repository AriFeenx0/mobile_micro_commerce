// แสดงประวัติคำสั่งซื้อของลูกค้า
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_routes.dart';
import '../../../models/order_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/order_service.dart';
import '../../../widgets/order_list_content.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final profile = auth.profile;
        if (profile == null || profile.role != UserRole.customer) {
          return const Scaffold(
            body: Center(child: Text('ประวัตินี้สำหรับบัญชีลูกค้าเท่านั้น')),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('ประวัติคำสั่งซื้อ'),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.customerBooks,
                  (_) => false,
                ),
                icon: const Icon(Icons.exit_to_app),
                label: const Text('ออก'),
              ),
            ],
          ),
          body: StreamBuilder<List<OrderModel>>(
            stream: OrderService().watchOrdersForCustomer(profile.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(
                  child: Text('โหลดประวัติคำสั่งซื้อไม่สำเร็จ'),
                );
              }
              return OrderListContent(orders: snapshot.data ?? const []);
            },
          ),
        );
      },
    );
  }
}
