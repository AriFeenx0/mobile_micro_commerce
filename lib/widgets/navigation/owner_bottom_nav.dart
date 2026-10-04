import 'package:flutter/material.dart';

class OwnerBottomNav extends StatelessWidget {
  const OwnerBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.newOrderCount = 6,
    this.unreadChatCount = 2,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final int newOrderCount;
  final int unreadChatCount;

  @override
  Widget build(BuildContext context) {
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
              label: Text('$newOrderCount'),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: Badge(
              label: Text('$newOrderCount'),
              child: const Icon(Icons.receipt_long),
            ),
            label: 'ออเดอร์',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('$unreadChatCount'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon: Badge(
              label: Text('$unreadChatCount'),
              child: const Icon(Icons.chat_bubble),
            ),
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
