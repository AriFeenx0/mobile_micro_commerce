/// แสดงภาพรวม รายได้ คำสั่งซื้อล่าสุด และข้อความใหม่ของเจ้าของร้าน
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_routes.dart';
import '../../../models/book_model.dart';
import '../../../models/book_volume_model.dart';
import '../../../models/chat_message_model.dart';
import '../../../models/order_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/book_service.dart';
import '../../../services/chat_service.dart';
import '../../../services/order_service.dart';
import '../../../widgets/navigation/owner_bottom_nav.dart';

class DashboardScreen extends StatelessWidget {
  /// สร้างหน้าแดชบอร์ดของเจ้าของร้าน
  const DashboardScreen({super.key});

  /// แสดงข้อมูลสรุปและรายการล่าสุดของร้าน
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final owner = auth.profile;
        if (owner == null || owner.role != UserRole.owner) {
          return const Scaffold(
            body: Center(child: Text('หน้านี้สำหรับเจ้าของร้านเท่านั้น')),
          );
        }
        return StreamBuilder<List<OrderModel>>(
          stream: OrderService().watchOrdersForOwner(owner.id),
          builder: (context, orderSnapshot) {
            final orders = orderSnapshot.data ?? const <OrderModel>[];
            final unconfirmedCount = orders
                .where((order) => order.status == OrderStatus.pendingSlipReview)
                .length;
            final totalRevenue = orders
                .where((order) => order.status == OrderStatus.paid)
                .fold<double>(0, (sum, order) => sum + order.subtotal);
            final now = DateTime.now();
            // ไม่มี field วันที่ชำระ จึงใช้ updatedAt (เวลาเปลี่ยนเป็นสถานะชำระแล้ว)
            final todayRevenue = orders
                .where((order) {
                  final date = order.updatedAt ?? order.createdAt;
                  return order.status == OrderStatus.paid &&
                      date != null &&
                      date.year == now.year &&
                      date.month == now.month &&
                      date.day == now.day;
                })
                .fold<double>(0, (sum, order) => sum + order.subtotal);
            final recentOrders = orders.take(2).toList();
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: _MetricPanel(
                                        label: 'รายได้รวม',
                                        value:
                                            '฿${totalRevenue.toStringAsFixed(2)}',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _MetricPanel(
                                        label: 'รายได้วันนี้',
                                        value:
                                            '฿${todayRevenue.toStringAsFixed(2)}',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _MetricPanel(
                                  label: 'ออเดอร์รอยืนยัน',
                                  value: '$unconfirmedCount',
                                ),
                                const SizedBox(height: 16),
                                _LowStockBooksSection(ownerId: owner.id),
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
                                if (orderSnapshot.hasError)
                                  const _DashboardRow(
                                    title: 'โหลดคำสั่งซื้อไม่สำเร็จ',
                                  )
                                else if (orderSnapshot.connectionState ==
                                        ConnectionState.waiting &&
                                    recentOrders.isEmpty)
                                  const _DashboardRow(
                                    title: 'กำลังโหลดคำสั่งซื้อ...',
                                  )
                                else if (recentOrders.isEmpty)
                                  const _DashboardRow(
                                    title: 'ยังไม่มีคำสั่งซื้อ',
                                  )
                                else
                                  for (final order in recentOrders)
                                    _RecentOrderRow(
                                      key: ValueKey(order.id),
                                      order: order,
                                      onTap: () => Navigator.pushNamed(
                                        context,
                                        AppRoutes.ownerOrders,
                                      ),
                                    ),
                                const SizedBox(height: 16),
                                _UnreadMessagesSection(ownerId: owner.id),
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
          },
        );
      },
    );
  }
}

class _LowStockBooksSection extends StatefulWidget {
  const _LowStockBooksSection({required this.ownerId});

  final String ownerId;

  @override
  State<_LowStockBooksSection> createState() => _LowStockBooksSectionState();
}

class _LowStockBooksSectionState extends State<_LowStockBooksSection> {
  static const _stockWarningThreshold = 5;

  final _bookService = BookService();
  final Map<String, BookModel> _books = {};
  final Map<String, List<BookVolumeModel>> _volumes = {};
  final Map<String, StreamSubscription<List<BookVolumeModel>>>
  _volumeSubscriptions = {};
  final Map<String, Object> _volumeErrors = {};
  final Set<String> _loadingVolumeIds = {};
  StreamSubscription<List<BookModel>>? _booksSubscription;
  Object? _booksError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _subscribeToBooks();
  }

  @override
  void didUpdateWidget(covariant _LowStockBooksSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ownerId != widget.ownerId) {
      _subscribeToBooks();
    }
  }

  void _subscribeToBooks() {
    unawaited(_booksSubscription?.cancel());
    for (final subscription in _volumeSubscriptions.values) {
      unawaited(subscription.cancel());
    }
    _volumeSubscriptions.clear();
    _books.clear();
    _volumes.clear();
    _volumeErrors.clear();
    _loadingVolumeIds.clear();
    _isLoading = true;
    _booksError = null;

    _booksSubscription = _bookService
        .watchBooksByOwner(widget.ownerId)
        .listen(
          (books) {
            if (!mounted) return;
            final nextBooks = {for (final book in books) book.id: book};
            final removedBookIds = _volumeSubscriptions.keys
                .where((bookId) => !nextBooks.containsKey(bookId))
                .toList();
            for (final bookId in removedBookIds) {
              unawaited(_volumeSubscriptions.remove(bookId)!.cancel());
              _volumes.remove(bookId);
              _volumeErrors.remove(bookId);
              _loadingVolumeIds.remove(bookId);
            }

            final newBooks = books
                .where((book) => !_volumeSubscriptions.containsKey(book.id))
                .toList();
            setState(() {
              _books
                ..clear()
                ..addAll(nextBooks);
              _isLoading = false;
              _booksError = null;
              _loadingVolumeIds.addAll(newBooks.map((book) => book.id));
            });

            for (final book in newBooks) {
              _volumeSubscriptions[book.id] = _bookService
                  .watchBookVolumes(book.id)
                  .listen(
                    (volumes) {
                      if (!mounted) return;
                      setState(() {
                        _volumes[book.id] = volumes;
                        _volumeErrors.remove(book.id);
                        _loadingVolumeIds.remove(book.id);
                      });
                    },
                    onError: (Object error) {
                      if (!mounted) return;
                      setState(() {
                        _volumeErrors[book.id] = error;
                        _loadingVolumeIds.remove(book.id);
                      });
                    },
                  );
            }
          },
          onError: (Object error) {
            if (!mounted) return;
            setState(() {
              _booksError = error;
              _isLoading = false;
            });
          },
        );
  }

  @override
  void dispose() {
    unawaited(_booksSubscription?.cancel());
    for (final subscription in _volumeSubscriptions.values) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lowStockVolumes =
        <({BookModel book, BookVolumeModel volume})>[
          for (final book in _books.values)
            for (final volume in _volumes[book.id] ?? const <BookVolumeModel>[])
              if (volume.availableStock <= _stockWarningThreshold)
                (book: book, volume: volume),
        ]..sort(
          (first, second) => first.volume.availableStock.compareTo(
            second.volume.availableStock,
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E4),
        border: Border.all(color: const Color(0xFFE9BE58), width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFF9A6B00)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'แจ้งเตือนหนังสือใกล้หมด',
                  style: TextStyle(
                    color: Color(0xFF292929),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (lowStockVolumes.isNotEmpty)
                Text(
                  '${lowStockVolumes.length} รายการ',
                  style: const TextStyle(
                    color: Color(0xFF9A6B00),
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_booksError != null || _volumeErrors.isNotEmpty)
            const Text(
              'โหลดข้อมูลสต็อกหนังสือไม่สำเร็จ',
              style: TextStyle(color: Color(0xFF9B1C1C)),
            )
          else if (_isLoading || _loadingVolumeIds.isNotEmpty)
            const LinearProgressIndicator()
          else if (lowStockVolumes.isEmpty)
            const Text(
              'ไม่มีหนังสือที่เหลือน้อย',
              style: TextStyle(color: Color(0xFF666666)),
            )
          else
            for (final entry in lowStockVolumes)
              _DashboardRow(
                title: '${entry.book.title} เล่ม ${entry.volume.volumeNumber}',
                trailing: 'เหลือ ${entry.volume.availableStock} เล่ม',
                unread: true,
                onTap: () => Navigator.pushNamed(context, AppRoutes.ownerBooks),
              ),
        ],
      ),
    );
  }
}

class _RecentOrderRow extends StatefulWidget {
  /// สร้างแถวสรุปคำสั่งซื้อพร้อมการดำเนินการเมื่อแตะ
  const _RecentOrderRow({super.key, required this.order, required this.onTap});

  final OrderModel order;
  final VoidCallback onTap;

  /// สร้างสถานะสำหรับโหลดข้อมูลลูกค้าของคำสั่งซื้อ
  @override
  State<_RecentOrderRow> createState() => _RecentOrderRowState();
}

class _RecentOrderRowState extends State<_RecentOrderRow> {
  final _authService = AuthService();
  late Future<UserModel?> _customerProfile;

  /// โหลดโปรไฟล์ลูกค้าเมื่อแถวถูกสร้าง
  @override
  void initState() {
    super.initState();
    _loadCustomerProfile();
  }

  /// โหลดโปรไฟล์อีกครั้งเมื่อคำสั่งซื้อเปลี่ยนเป็นของลูกค้ารายอื่น
  @override
  void didUpdateWidget(covariant _RecentOrderRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.customerId != widget.order.customerId) {
      _loadCustomerProfile();
    }
  }

  /// ดึงโปรไฟล์ลูกค้าของคำสั่งซื้อปัจจุบัน
  void _loadCustomerProfile() {
    _customerProfile = _authService.getUserProfile(widget.order.customerId);
  }

  /// แสดงชื่อลูกค้า รายการสินค้า และสถานะคำสั่งซื้อ
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _customerProfile,
      builder: (context, snapshot) {
        final customerName = snapshot.data?.name.trim();
        final displayName = customerName == null || customerName.isEmpty
            ? 'ลูกค้า'
            : customerName;
        final items = widget.order.items
            .map(
              (item) => '${item.title} เล่ม ${item.volumeNumber} x${item.qty}',
            )
            .join(', ');
        return _DashboardRow(
          title: '$displayName · $items',
          trailing: orderStatusToString(widget.order.status),
          onTap: widget.onTap,
        );
      },
    );
  }
}

class _UnreadMessagesSection extends StatefulWidget {
  /// สร้างส่วนแสดงข้อความที่ยังไม่ได้อ่านของเจ้าของร้าน
  const _UnreadMessagesSection({required this.ownerId});

  final String ownerId;

  /// สร้างสถานะสำหรับติดตามห้องสนทนาของเจ้าของร้าน
  @override
  State<_UnreadMessagesSection> createState() => _UnreadMessagesSectionState();
}

class _UnreadMessagesSectionState extends State<_UnreadMessagesSection> {
  late final Stream<List<ChatRoomModel>> _rooms = ChatService()
      .watchRoomsForUser(widget.ownerId);

  /// แสดงห้องที่มีข้อความใหม่เรียงตามเวลาข้อความล่าสุด
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatRoomModel>>(
      stream: _rooms,
      builder: (context, snapshot) {
        final unreadRooms =
            (snapshot.data ?? const <ChatRoomModel>[])
                .where((room) => (room.unreadCount[widget.ownerId] ?? 0) > 0)
                .toList()
              ..sort(
                (a, b) => (b.lastMessageAt ?? DateTime(0)).compareTo(
                  a.lastMessageAt ?? DateTime(0),
                ),
              );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeading('ข้อความใหม่จากลูกค้า (${unreadRooms.length})'),
            if (snapshot.hasError)
              const _DashboardRow(title: 'โหลดข้อความไม่สำเร็จ')
            else if (unreadRooms.isEmpty)
              const _DashboardRow(title: 'ไม่มีข้อความใหม่')
            else
              for (final room in unreadRooms.take(2))
                _UnreadMessageRow(
                  key: ValueKey(room.id),
                  room: room,
                  ownerId: widget.ownerId,
                ),
          ],
        );
      },
    );
  }
}

class _UnreadMessageRow extends StatefulWidget {
  /// สร้างแถวสรุปข้อความใหม่จากลูกค้า
  const _UnreadMessageRow({
    super.key,
    required this.room,
    required this.ownerId,
  });

  final ChatRoomModel room;
  final String ownerId;

  /// สร้างสถานะสำหรับโหลดโปรไฟล์ผู้ส่งข้อความ
  @override
  State<_UnreadMessageRow> createState() => _UnreadMessageRowState();
}

class _UnreadMessageRowState extends State<_UnreadMessageRow> {
  late final Future<UserModel?> _customer = AuthService().getUserProfile(
    widget.room.participants.firstWhere(
      (id) => id != widget.ownerId,
      orElse: () => '',
    ),
  );

  /// แสดงชื่อผู้ส่งและข้อความล่าสุดที่ยังไม่ได้อ่าน
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _customer,
      builder: (context, snapshot) {
        final name = snapshot.data?.name.trim();
        final displayName = name == null || name.isEmpty ? 'ลูกค้า' : name;
        return _DashboardRow(
          title: '$displayName: ${widget.room.lastMessage}',
          unread: true,
          onTap: () => Navigator.pushNamed(context, AppRoutes.chats),
        );
      },
    );
  }
}

class _MetricPanel extends StatelessWidget {
  /// สร้างแผงแสดงชื่อและค่าของตัวชี้วัด
  const _MetricPanel({required this.label, required this.value});

  final String label;
  final String value;

  /// แสดงค่าตัวชี้วัดในรูปแบบแผงสรุป
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
  /// สร้างปุ่มดำเนินการพร้อมข้อความและไอคอนเสริม
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  /// แสดงปุ่มที่เรียกการดำเนินการที่ได้รับ
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
  /// สร้างหัวข้อสำหรับส่วนข้อมูลในแดชบอร์ด
  const _SectionHeading(this.title);

  final String title;

  /// แสดงหัวข้อส่วนด้วยรูปแบบตัวอักษรของแดชบอร์ด
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
  /// สร้างแถวข้อมูลพร้อมสถานะและการดำเนินการเสริม
  const _DashboardRow({
    required this.title,
    this.onTap,
    this.trailing,
    this.unread = false,
  });

  final String title;
  final String? trailing;
  final bool unread;
  final VoidCallback? onTap;

  /// แสดงข้อความ แถบข้อมูลเสริม และตัวบอกข้อความที่ยังไม่อ่าน
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
