// แสดงข้อมูลโปรไฟล์และเมนูตามบทบาทผู้ใช้
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/feature_placeholder_screen.dart';
import '../../widgets/navigation/customer_bottom_nav.dart';
import '../../widgets/navigation/owner_bottom_nav.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (auth.error != null) {
          return _ProfileState(
            message: 'โหลดข้อมูลโปรไฟล์ไม่สำเร็จ',
            actionLabel: 'ลองใหม่',
            onAction: auth.reload,
          );
        }
        if (!auth.isSignedIn || auth.profile == null) {
          return _ProfileState(
            message: 'กรุณาเข้าสู่ระบบเพื่อดูโปรไฟล์',
            actionLabel: 'เข้าสู่ระบบ',
            onAction: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.login,
              (_) => false,
            ),
          );
        }

        final profile = auth.profile!;
        final isCustomer = profile.role == UserRole.customer;
        final isOwner = profile.role == UserRole.owner;
        if (!isCustomer && !isOwner) {
          return const _ProfileState(message: 'ไม่พบ role ของบัญชีนี้');
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
                    children: [
                      const SizedBox(height: 12),
                      const Text(
                        'โปรไฟล์',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Center(
                        child: CircleAvatar(
                          radius: 54,
                          backgroundColor: const Color(0xFFF0F0F0),
                          foregroundImage: profile.photoUrl?.isNotEmpty == true
                              ? NetworkImage(profile.photoUrl!)
                              : null,
                          child: profile.photoUrl?.isNotEmpty == true
                              ? null
                              : const Icon(
                                  Icons.person_outline,
                                  size: 72,
                                  color: Color(0xFF999999),
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        profile.name.isEmpty ? 'ไม่ระบุชื่อ' : profile.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isOwner
                                ? const Color(0xFFFFEEEE)
                                : const Color(0xFFEEF4FA),
                            border: Border.all(
                              color: isOwner
                                  ? const Color(0xFFE6A0A0)
                                  : const Color(0xFFB7D1E9),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            isOwner ? 'เจ้าของร้าน' : 'ลูกค้า',
                            style: TextStyle(
                              color: isOwner
                                  ? const Color(0xFFAC3932)
                                  : const Color(0xFF315D87),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Divider(height: 1),
                      _ProfileMenuRow(
                        icon: Icons.edit_outlined,
                        title: 'แก้ไขโปรไฟล์',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.editProfile),
                      ),
                      if (isCustomer) ...[
                        _ProfileMenuRow(
                          icon: Icons.location_on_outlined,
                          title: 'ที่อยู่จัดส่ง',
                          onTap: () =>
                              _showPlaceholder(context, 'ที่อยู่จัดส่ง'),
                        ),
                        _ProfileMenuRow(
                          icon: Icons.receipt_long_outlined,
                          title: 'ประวัติคำสั่งซื้อ',
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.customerOrderHistory,
                          ),
                        ),
                        _ProfileMenuRow(
                          icon: Icons.notifications_none,
                          title: 'การแจ้งเตือน',
                          onTap: () =>
                              _showPlaceholder(context, 'การแจ้งเตือน'),
                        ),
                        _ProfileMenuRow(
                          icon: Icons.help_outline,
                          title: 'ช่วยเหลือ / ติดต่อร้าน',
                          onTap: () => _showPlaceholder(
                            context,
                            'ช่วยเหลือ / ติดต่อร้าน',
                          ),
                        ),
                      ] else ...[
                        _ProfileMenuRow(
                          icon: Icons.storefront_outlined,
                          title: 'ข้อมูลร้านค้า',
                          onTap: () =>
                              _showPlaceholder(context, 'ข้อมูลร้านค้า'),
                        ),
                        _ProfileMenuRow(
                          icon: Icons.account_balance_outlined,
                          title: 'บัญชีรับเงิน (พร้อมเพย์/ธนาคาร)',
                          onTap: () => _showPlaceholder(
                            context,
                            'บัญชีรับเงิน (พร้อมเพย์/ธนาคาร)',
                          ),
                        ),
                        _ProfileMenuRow(
                          icon: Icons.notifications_none,
                          title: 'การแจ้งเตือน',
                          onTap: () =>
                              _showPlaceholder(context, 'การแจ้งเตือน'),
                        ),
                        _ProfileMenuRow(
                          icon: Icons.help_outline,
                          title: 'ช่วยเหลือ',
                          onTap: () => _showPlaceholder(context, 'ช่วยเหลือ'),
                        ),
                      ],
                      _ProfileMenuRow(
                        icon: Icons.logout,
                        title: 'ออกจากระบบ',
                        color: const Color(0xFFD33B32),
                        showChevron: false,
                        onTap: () => _signOut(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: isOwner
              ? OwnerBottomNav(
                  selectedIndex: 4,
                  onDestinationSelected: (index) =>
                      _navigateOwner(context, index),
                )
              : CustomerBottomNav(
                  selectedIndex: 3,
                  onDestinationSelected: (index) =>
                      _navigateCustomer(context, index),
                ),
        );
      },
    );
  }

  void _showPlaceholder(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => FeaturePlaceholderScreen(
          title: title,
          message: '$title ยังไม่พร้อมใช้งาน',
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await context.read<AuthProvider>().signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  void _navigateCustomer(BuildContext context, int index) {
    final route = switch (index) {
      0 => AppRoutes.customerBooks,
      1 => AppRoutes.customerCart,
      2 => AppRoutes.chats,
      _ => null,
    };
    if (route != null) Navigator.pushReplacementNamed(context, route);
  }

  void _navigateOwner(BuildContext context, int index) {
    final route = switch (index) {
      0 => AppRoutes.ownerDashboard,
      1 => AppRoutes.ownerBooks,
      2 => AppRoutes.ownerOrders,
      3 => AppRoutes.chats,
      _ => null,
    };
    if (route != null) Navigator.pushReplacementNamed(context, route);
  }
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = const Color(0xFF303030),
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 72,
          child: InkWell(
            onTap: onTap,
            child: Row(
              children: [
                SizedBox(width: 56, child: Icon(icon, color: color, size: 28)),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: color, fontSize: 17),
                  ),
                ),
                if (showChevron)
                  const Icon(
                    Icons.chevron_right,
                    size: 30,
                    color: Color(0xFFB8B8B8),
                  ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _ProfileState extends StatelessWidget {
  const _ProfileState({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 14),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
