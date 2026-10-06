// แถบนำทางเจ้าของร้านพร้อมตัวบอกออเดอร์รอตรวจ
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';

class OwnerBottomNav extends StatelessWidget {
  const OwnerBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final profile = auth.profile;
        if (profile == null || profile.role != UserRole.owner) {
          return _buildNavigation(context, false);
        }
        return StreamBuilder<List<OrderModel>>(
          stream: OrderService().watchOrdersForOwner(profile.id),
          builder: (context, snapshot) {
            final hasUnconfirmedOrder = (snapshot.data ?? const <OrderModel>[])
                .any((order) => order.status == OrderStatus.pendingSlipReview);
            return _buildNavigation(context, hasUnconfirmedOrder);
          },
        );
      },
    );
  }

  Widget _buildNavigation(BuildContext context, bool hasUnconfirmedOrder) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? const Color(0xFF292929)
                : const Color(0xFF999999),
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? const Color(0xFF292929)
                : const Color(0xFF999999),
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.bold
                : FontWeight.normal,
          );
        }),
      ),
      child: NavigationBar(
        height: 86,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'สินค้า',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: hasUnconfirmedOrder,
              smallSize: 9,
              backgroundColor: Colors.red,
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: hasUnconfirmedOrder,
              smallSize: 9,
              backgroundColor: Colors.red,
              child: const Icon(Icons.receipt_long),
            ),
            label: 'ออเดอร์',
          ),
          const NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'แชท',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}
