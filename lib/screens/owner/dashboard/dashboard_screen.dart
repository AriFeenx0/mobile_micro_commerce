import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../widgets/navigation/owner_bottom_nav.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
                const SizedBox(height: 18),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final horizontalPadding = constraints.maxWidth < 420
                          ? 22.0
                          : 40.0;
                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          14,
                          horizontalPadding,
                          20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Row(
                              children: [
                                Expanded(
                                  child: _MetricPanel(
                                    label: 'ยอดขายวันนี้',
                                    value: '฿ 2,150',
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _MetricPanel(
                                    label: 'ออเดอร์ใหม่',
                                    value: '6',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 15,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7E4),
                                border: Border.all(
                                  color: const Color(0xFFE9BE58),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'หนังสือเหลือ 1 เล่ม 8 รายการ',
                                style: TextStyle(
                                  color: Color(0xFF8E681B),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _ActionButton(
                                    label: 'เพิ่มหนังสือ',
                                    icon: Icons.add,
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      AppRoutes.ownerBookForm,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ActionButton(
                                    label: 'สร้างคูปอง',
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      AppRoutes.ownerCoupons,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            const _SectionHeading('ออเดอร์ล่าสุด'),
                            _DashboardRow(
                              title: 'เมย์ - นิทานเมืองริมทาง เล่ม 2',
                              trailing: 'รอชำระ',
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.ownerOrders,
                              ),
                            ),
                            _DashboardRow(
                              title: 'บี - สายลมแห่งฤดูฝน เล่ม 1-3',
                              trailing: 'จัดส่งแล้ว',
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.ownerOrders,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const _SectionHeading('ข้อความใหม่จากลูกค้า (2)'),
                            _DashboardRow(
                              title: 'ปลาม: เล่ม 2 สภาพเป็นยังไงคะ?',
                              unread: true,
                              onTap: () =>
                                  Navigator.pushNamed(context, AppRoutes.chats),
                            ),
                            _DashboardRow(
                              title: 'ต้น: มีเล่ม 3 เข้าเมื่อไหร่คะ?',
                              unread: true,
                              onTap: () =>
                                  Navigator.pushNamed(context, AppRoutes.chats),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                OwnerBottomNav(
                  selectedIndex: 0,
                  onDestinationSelected: (index) {
                    final route = switch (index) {
                      1 => AppRoutes.ownerBooks,
                      2 => AppRoutes.ownerOrders,
                      3 => AppRoutes.chats,
                      4 => AppRoutes.profile,
                      _ => null,
                    };
                    if (route != null) {
                      Navigator.pushReplacementNamed(context, route);
                    }
                  },
                ),
          ],
        ),
      ),
    );
  }
}

class _MetricPanel extends StatelessWidget {
  const _MetricPanel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF999999), fontSize: 15),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF292929),
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 20),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF292929),
          side: const BorderSide(color: Color(0xFF999999), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        title,
        style: const TextStyle(color: Color(0xFF999999), fontSize: 16),
      ),
    );
  }
}

class _DashboardRow extends StatelessWidget {
  const _DashboardRow({
    required this.title,
    required this.onTap,
    this.trailing,
    this.unread = false,
  });

  final String title;
  final String? trailing;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFDDDDDD))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, color: Color(0xFF292929)),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Text(
                trailing!,
                style: const TextStyle(color: Color(0xFF777777), fontSize: 14),
              ),
            ],
            if (unread) ...[
              const SizedBox(width: 12),
              const CircleAvatar(radius: 6, backgroundColor: Color(0xFF333333)),
            ],
          ],
        ),
      ),
    );
  }
}
