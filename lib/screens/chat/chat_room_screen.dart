// หน้าห้องแชทระหว่างลูกค้ากับเจ้าของร้าน
import 'package:flutter/material.dart';

import '../../models/chat_message_model.dart';
import '../../services/chat_service.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.customerId,
    required this.ownerId,
    required this.currentUserId,
    required this.title,
    this.subtitle,
    this.showBack = false,
    this.bottomNavigationBar,
  });

  final String customerId;
  final String ownerId;
  final String currentUserId;
  final String title;
  final String? subtitle;
  final bool showBack;
  final Widget? bottomNavigationBar;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _service = ChatService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final Stream<List<ChatMessageModel>> _messages;
  bool _sending = false;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _messages = _service.watchMessages(
      '${widget.customerId}_${widget.ownerId}',
    );
    _markRead();
  }

  void _markRead() {
    _service
        .markRead(
          customerId: widget.customerId,
          ownerId: widget.ownerId,
          userId: widget.currentUserId,
        )
        .catchError((_) {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _service.sendMessage(
        customerId: widget.customerId,
        ownerId: widget.ownerId,
        senderId: widget.currentUserId,
        text: text,
      );
      _controller.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ส่งข้อความไม่สำเร็จ')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.title.isEmpty ? '?' : widget.title.characters.first;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: widget.showBack,
        titleSpacing: widget.showBack ? 0 : 16,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFEEEEEE),
              child: Text(initial),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.subtitle != null)
                    Text(
                      widget.subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: _messages,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('โหลดข้อความไม่สำเร็จ'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                if (messages.length != _lastCount) {
                  final hasIncoming =
                      messages.length > _lastCount &&
                      messages.last.senderId != widget.currentUserId;
                  _lastCount = messages.length;
                  _scrollToEnd();
                  if (hasIncoming) _markRead();
                }
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'ยังไม่มีข้อความ เริ่มการสนทนาได้เลย',
                      style: TextStyle(color: Color(0xFF999999)),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _MessageBubble(
                      text: message.text ?? '',
                      isMine: message.senderId == widget.currentUserId,
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'พิมพ์ข้อความ...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF333333),
                    ),
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.bottomNavigationBar,
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.text, required this.isMine});

  final String text;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMine ? const Color(0xFF333333) : const Color(0xFFEFEFEF),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: isMine ? Colors.white : const Color(0xFF292929),
          ),
        ),
      ),
    );
  }
}
