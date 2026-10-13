// หน้าแชทตามบทบาท: ลูกค้าเข้าห้องแชทเลย ส่วนเจ้าของเห็นรายชื่อลูกค้า
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../models/chat_message_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../widgets/navigation/customer_bottom_nav.dart';
import '../../widgets/navigation/owner_bottom_nav.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;
    if (auth.isLoading || profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return profile.role == UserRole.owner
        ? _OwnerChatList(owner: profile)
        : _CustomerChat(customer: profile);
  }
}

class _CustomerChat extends StatefulWidget {
  const _CustomerChat({required this.customer});

  final UserModel customer;

  @override
  State<_CustomerChat> createState() => _CustomerChatState();
}

class _CustomerChatState extends State<_CustomerChat> {
  late final Future<UserModel?> _owner = ChatService().getOwner();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _owner,
      builder: (context, snapshot) {
        final owner = snapshot.data;
        if (owner == null) {
          return Scaffold(
            body: Center(
              child: snapshot.connectionState != ConnectionState.done
                  ? const CircularProgressIndicator()
                  : const Text('ไม่พบข้อมูลร้านค้า'),
            ),
            bottomNavigationBar: _nav(context),
          );
        }
        return ChatRoomScreen(
          customerId: widget.customer.id,
          ownerId: owner.id,
          currentUserId: widget.customer.id,
          title: owner.name.isEmpty ? 'ร้านค้า' : owner.name,
          bottomNavigationBar: _nav(context),
        );
      },
    );
  }

  Widget _nav(BuildContext context) => CustomerBottomNav(
    selectedIndex: 2,
    onDestinationSelected: (index) {
      final route = switch (index) {
        0 => AppRoutes.customerBooks,
        1 => AppRoutes.customerCart,
        3 => AppRoutes.profile,
        _ => null,
      };
      if (route != null) Navigator.pushReplacementNamed(context, route);
    },
  );
}

class _OwnerChatList extends StatefulWidget {
  const _OwnerChatList({required this.owner});

  final UserModel owner;

  @override
  State<_OwnerChatList> createState() => _OwnerChatListState();
}

class _OwnerChatListState extends State<_OwnerChatList> {
  final _service = ChatService();
  late final Stream<List<UserModel>> _customers = _service.watchCustomers();
  late final Stream<List<ChatRoomModel>> _rooms = _service.watchRoomsForUser(
    widget.owner.id,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text('แชท', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _customers,
        builder: (context, customerSnapshot) {
          if (customerSnapshot.hasError) {
            return const Center(child: Text('โหลดรายชื่อลูกค้าไม่สำเร็จ'));
          }
          if (!customerSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<List<ChatRoomModel>>(
            stream: _rooms,
            builder: (context, roomSnapshot) {
              final rooms = {
                for (final room in roomSnapshot.data ?? const <ChatRoomModel>[])
                  room.id: room,
              };
              final customers = [...customerSnapshot.data!];
              DateTime time(UserModel c) =>
                  rooms[ChatRoomModel.buildRoomId(c.id, widget.owner.id)]
                      ?.lastMessageAt ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              customers.sort((a, b) => time(b).compareTo(time(a)));
              if (customers.isEmpty) {
                return const Center(child: Text('ยังไม่มีลูกค้าในระบบ'));
              }
              return ListView.separated(
                itemCount: customers.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  final room =
                      rooms[ChatRoomModel.buildRoomId(
                        customer.id,
                        widget.owner.id,
                      )];
                  return _CustomerTile(
                    customer: customer,
                    room: room,
                    ownerId: widget.owner.id,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ChatRoomScreen(
                          customerId: customer.id,
                          ownerId: widget.owner.id,
                          currentUserId: widget.owner.id,
                          title: customer.name,
                          subtitle: 'ลูกค้า',
                          showBack: true,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: OwnerBottomNav(
        selectedIndex: 3,
        onDestinationSelected: (index) {
          final route = switch (index) {
            0 => AppRoutes.ownerDashboard,
            1 => AppRoutes.ownerBooks,
            2 => AppRoutes.ownerOrders,
            4 => AppRoutes.profile,
            _ => null,
          };
          if (route != null) Navigator.pushReplacementNamed(context, route);
        },
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({
    required this.customer,
    required this.room,
    required this.ownerId,
    required this.onTap,
  });

  final UserModel customer;
  final ChatRoomModel? room;
  final String ownerId;
  final VoidCallback onTap;

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final sameDay =
        now.year == time.year && now.month == time.month && now.day == time.day;
    return sameDay
        ? DateFormat('HH:mm').format(time)
        : DateFormat('d/M/yy').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final unread = room?.unreadCount[ownerId] ?? 0;
    final lastAt = room?.lastMessageAt;
    final name = customer.name.isEmpty ? customer.email : customer.name;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: const Color(0xFFEEEEEE),
        child: Text(name.isEmpty ? '?' : name.characters.first),
      ),
      title: Text(
        name,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        (room?.lastMessage.isNotEmpty ?? false)
            ? room!.lastMessage
            : 'เริ่มการสนทนา',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
          color: unread > 0 ? const Color(0xFF292929) : const Color(0xFF999999),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (lastAt != null)
            Text(
              _formatTime(lastAt),
              style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
            ),
          if (unread > 0) ...[
            const SizedBox(height: 4),
            Badge(label: Text('$unread'), backgroundColor: const Color(0xFF333333)),
          ],
        ],
      ),
    );
  }
}
