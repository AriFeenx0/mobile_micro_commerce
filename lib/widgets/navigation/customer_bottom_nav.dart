import 'package:flutter/material.dart';

class CustomerBottomNav extends StatelessWidget {
  const CustomerBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.menu_book), label: 'รายการสินค้า'),
        NavigationDestination(icon: Icon(Icons.shopping_bag), label: 'ตะกร้าสินค้า'),
        NavigationDestination(icon: Icon(Icons.chat), label: 'แชท'),
        NavigationDestination(icon: Icon(Icons.person), label: 'โปรไฟล์'),
      ],
    );
  }
}