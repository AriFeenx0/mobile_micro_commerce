import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_routes.dart';
import '../../../models/order_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/order_service.dart';
import '../../../widgets/navigation/owner_bottom_nav.dart';
import '../../../widgets/order_list_content.dart';

class OrderManageScreen extends StatelessWidget {
  const OrderManageScreen({super.key});

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
          appBar: AppBar(title: const Text('คำสั่งซื้อทั้งหมด')),
          body: StreamBuilder<List<OrderModel>>(
            stream: OrderService().watchOrdersForOwner(ownerId),
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
              );
            },
          ),
          bottomNavigationBar: OwnerBottomNav(
            selectedIndex: 2,
            onDestinationSelected: (index) {
              final route = switch (index) {
                0 => AppRoutes.ownerDashboard,
                1 => AppRoutes.ownerBooks,
                3 => AppRoutes.chats,
                4 => AppRoutes.profile,
                _ => null,
              };
              if (route != null) {
                Navigator.pushReplacementNamed(context, route);
              }
            },
          ),
        );
      },
    );
  }
}
