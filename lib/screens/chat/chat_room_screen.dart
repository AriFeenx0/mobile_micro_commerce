/// จัดการและแสดงการสนทนาระหว่างลูกค้ากับเจ้าของร้าน รวมถึงรูปภาพแนบ
// ใช้เก็บข้อมูลรูปภาพที่เลือกไว้ในหน่วยความจำ เพื่อแสดงตัวอย่างก่อนส่ง
import 'dart:typed_data';

// วิดเจ็ตและองค์ประกอบส่วนติดต่อผู้ใช้ของ Flutter
import 'package:flutter/material.dart';
// ใช้เปิดแกลเลอรีและให้ผู้ใช้เลือกรูปภาพ
import 'package:image_picker/image_picker.dart';

// โมเดลข้อมูลของข้อความแต่ละรายการในห้องแชท
import '../../models/chat_message_model.dart';
// บริการอ่าน/ส่งข้อความและทำเครื่องหมายว่าอ่านข้อความแล้ว
import '../../services/chat_service.dart';
// บริการอัปโหลดรูปภาพแชทไปยังพื้นที่จัดเก็บ
import '../../services/storage_service.dart';

// หน้าห้องสนทนาที่เก็บสถานะภายใน เช่น ข้อความและรูปภาพที่กำลังเลือก
class ChatRoomScreen extends StatefulWidget {
  // รับข้อมูลคู่สนทนา ผู้ใช้ปัจจุบัน และตัวเลือกการแสดงผลของหน้าจอ
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

  // รหัสลูกค้าและเจ้าของร้านใช้ระบุห้องสนทนา
  final String customerId;
  final String ownerId;
  // รหัสผู้ใช้ปัจจุบันใช้ระบุข้อความของตนเองและอัปเดตสถานะการอ่าน
  final String currentUserId;
  // ชื่อและข้อความรองที่แสดงในแถบด้านบนของห้องแชท
  final String title;
  final String? subtitle;
  // กำหนดการแสดงปุ่มย้อนกลับและแถบนำทางด้านล่างเพิ่มเติม
  final bool showBack;
  final Widget? bottomNavigationBar;

  /// สร้างสถานะและจัดการวงจรชีวิตของห้องแชท
  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

// เก็บสถานะและการทำงานทั้งหมดของหน้าห้องแชท
class _ChatRoomScreenState extends State<ChatRoomScreen> {
  // บริการสำหรับติดตามสถานะข้อความและส่งข้อความ
  final _service = ChatService();
  // บริการอัปโหลดรูปภาพที่แนบมากับข้อความ
  final _storageService = StorageService();
  // ตัวเลือกภาพจากแกลเลอรีของอุปกรณ์
  final _imagePicker = ImagePicker();
  // ควบคุมข้อความที่ผู้ใช้กำลังพิมพ์
  final _controller = TextEditingController();
  // ควบคุมตำแหน่งเลื่อนของรายการข้อความ
  final _scrollController = ScrollController();
  // สตรีมข้อความสดของห้องสนทนานี้
  late final Stream<List<ChatMessageModel>> _messages;
  // เก็บไฟล์รูปภาพและข้อมูลไบต์สำหรับแสดงตัวอย่างก่อนส่ง
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  // ป้องกันการเลือกรูปภาพหรือส่งข้อความซ้ำระหว่างที่กำลังทำงาน
  bool _pickingImage = false;
  bool _sending = false;
  // จำนวนข้อความจากรอบก่อน ใช้ตรวจจับข้อความใหม่เพื่อเลื่อนและอัปเดตสถานะอ่าน
  int _lastCount = 0;

  /// เริ่มติดตามข้อความของห้องนี้และทำเครื่องหมายข้อความที่มีว่าอ่านแล้ว
  @override
  void initState() {
    super.initState();
    _messages = _service.watchMessages(
      '${widget.customerId}_${widget.ownerId}',
    );
    _markRead();
  }

  /// แจ้งบริการแชทว่าผู้ใช้ปัจจุบันอ่านข้อความในห้องนี้แล้ว
  void _markRead() {
    _service
        .markRead(
          customerId: widget.customerId,
          ownerId: widget.ownerId,
          userId: widget.currentUserId,
        )
        .catchError((_) {});
  }

  /// คืนทรัพยากรของตัวควบคุมเมื่อหน้าจอถูกนำออก
  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// ส่งข้อความที่พิมพ์และ/หรือรูปภาพที่เลือกไปยังห้องสนทนา
  Future<void> _send() async {
    // ตัดช่องว่างรอบข้อความและหยุดหากไม่มีเนื้อหาหรือกำลังส่งอยู่
    final text = _controller.text.trim();
    final image = _selectedImage;
    if ((text.isEmpty && image == null) || _sending) return;
    setState(() => _sending = true);
    try {
      // อัปโหลดรูปภาพก่อนเมื่อมีรูปแนบ แล้วนำ URL ไปบันทึกกับข้อความ
      final imageUrl = image == null
          ? null
          : await _storageService.uploadChatImage(
              customerId: widget.customerId,
              ownerId: widget.ownerId,
              senderId: widget.currentUserId,
              image: image,
            );
      // บันทึกข้อความพร้อมรหัสผู้ส่งและ URL รูปภาพ (ถ้ามี)
      await _service.sendMessage(
        customerId: widget.customerId,
        ownerId: widget.ownerId,
        senderId: widget.currentUserId,
        text: text,
        imageUrl: imageUrl,
      );
      // ล้างช่องพิมพ์และยกเลิกรูปภาพที่แนบหลังส่งสำเร็จ
      _controller.clear();
      if (mounted) {
        setState(() {
          _selectedImage = null;
          _selectedImageBytes = null;
        });
      }
    } catch (error) {
      // แจ้งผู้ใช้เมื่อการส่งข้อความหรือการส่งรูปภาพล้มเหลว
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              image == null
                  ? 'ส่งข้อความไม่สำเร็จ: $error'
                  : 'ส่งรูปภาพไม่สำเร็จ: $error',
            ),
          ),
        );
      }
    } finally {
      // คืนสถานะปุ่มส่งให้พร้อมใช้งาน หากหน้าจอยังอยู่
      if (mounted) setState(() => _sending = false);
    }
  }

  /// เปิดแกลเลอรี ให้ผู้ใช้เลือกรูป และเตรียมข้อมูลสำหรับตัวอย่าง
  Future<void> _pickImage() async {
    // ไม่เริ่มเลือกภาพซ้ำขณะกำลังเลือกหรือส่งข้อความ
    if (_pickingImage || _sending) return;
    setState(() => _pickingImage = true);
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      // ผู้ใช้อาจปิดหน้าต่างเลือกภาพโดยไม่เลือกรูป
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      // เก็บไฟล์และไบต์รูปภาพเพื่อใช้ตอนส่งและแสดงตัวอย่าง
      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
    } catch (error) {
      // แสดงข้อผิดพลาดหากไม่สามารถเปิดหรืออ่านรูปภาพได้
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เลือกรูปภาพไม่สำเร็จ: $error')));
      }
    } finally {
      // สิ้นสุดสถานะกำลังเลือกรูปเมื่อการทำงานเสร็จ
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  /// เลื่อนรายการไปยังข้อความล่าสุดหลังเฟรมปัจจุบันวาดเสร็จ
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

  /// สร้างโครงหน้าจอ แถบหัวข้อ รายการข้อความ และแถบเขียนข้อความ
  @override
  Widget build(BuildContext context) {
    // ใช้อักษรตัวแรกของชื่อเป็นรูปโปรไฟล์สำรองเมื่อแสดงหัวข้อห้องแชท
    final initial = widget.title.isEmpty ? '?' : widget.title.characters.first;
    return Scaffold(
      // กำหนดพื้นหลังและส่วนหัวของหน้าห้องสนทนา
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: widget.showBack,
        titleSpacing: widget.showBack ? 0 : 16,
        // แสดงรูปอักษร ชื่อคู่สนทนา และข้อความรอง (ถ้ามี)
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
      // จัดวางสตรีมข้อความและส่วนเขียนข้อความในแนวตั้ง
      body: Column(
        children: [
          const Divider(height: 1),
          // รับข้อความแบบเรียลไทม์ พร้อมแสดงสถานะโหลด ผิดพลาด หรือรายการสนทนา
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: _messages,
              builder: (context, snapshot) {
                // แจ้งเมื่อไม่สามารถโหลดข้อมูลข้อความจากสตรีมได้
                if (snapshot.hasError) {
                  return const Center(child: Text('โหลดข้อความไม่สำเร็จ'));
                }
                // แสดงตัวหมุนระหว่างรอข้อมูลครั้งแรก
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                // อ่านรายการข้อความและตรวจว่ามีข้อความใหม่เข้ามาหรือไม่
                final messages = snapshot.data!;
                if (messages.length != _lastCount) {
                  // เลื่อนลงท้ายรายการเมื่อจำนวนข้อความเปลี่ยน และทำเครื่องหมาย
                  // ว่าอ่านแล้วเฉพาะเมื่อข้อความใหม่มาจากผู้ใช้อื่น
                  final hasIncoming =
                      messages.length > _lastCount &&
                      messages.last.senderId != widget.currentUserId;
                  _lastCount = messages.length;
                  _scrollToEnd();
                  if (hasIncoming) _markRead();
                }
                // แสดงคำแนะนำเมื่อห้องสนทนายังไม่มีข้อความ
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'ยังไม่มีข้อความ เริ่มการสนทนาได้เลย',
                      style: TextStyle(color: Color(0xFF999999)),
                    ),
                  );
                }
                // สร้างรายการข้อความ โดยระบุว่าข้อความใดเป็นของผู้ใช้ปัจจุบัน
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    // แสดงข้อความแต่ละรายการเป็นกล่องข้อความ
                    return _MessageBubble(
                      text: message.text ?? '',
                      imageUrl: message.imageUrl,
                      isMine: message.senderId == widget.currentUserId,
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          // เว้นพื้นที่ปลอดภัยด้านล่างและจัดส่วนแนบรูปกับช่องพิมพ์
          SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // แสดงภาพตัวอย่างและปุ่มลบเมื่อมีรูปที่เลือกไว้
                if (_selectedImageBytes != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _selectedImageBytes!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('พร้อมส่งรูปภาพ')),
                        // ยกเลิกรูปที่เลือก โดยปิดปุ่มระหว่างกำลังส่ง
                        IconButton(
                          tooltip: 'นำรูปภาพออก',
                          onPressed: _sending
                              ? null
                              : () => setState(() {
                                  _selectedImage = null;
                                  _selectedImageBytes = null;
                                }),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                // แถวควบคุมสำหรับเลือกรูป พิมพ์ข้อความ และส่งข้อความ
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                  child: Row(
                    children: [
                      // เปิดแกลเลอรี และแสดงตัวหมุนระหว่างกำลังเลือกรูป
                      IconButton(
                        tooltip: 'เลือกรูปภาพ',
                        onPressed: _pickingImage || _sending
                            ? null
                            : _pickImage,
                        icon: _pickingImage
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.image_outlined),
                      ),
                      // ช่องพิมพ์ข้อความ รองรับหลายบรรทัดและส่งด้วยปุ่มบนคีย์บอร์ด
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
                      // ปุ่มส่งข้อความ แสดงสถานะกำลังส่งขณะรอผลลัพธ์
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF333333),
                        ),
                        onPressed: _sending ? null : _send,
                        icon: _sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // แสดงแถบนำทางด้านล่างที่หน้าจอแม่ส่งเข้ามา (ถ้ามี)
      bottomNavigationBar: widget.bottomNavigationBar,
    );
  }
}

// กล่องแสดงข้อความหนึ่งรายการ โดยจัดตำแหน่งและสีตามผู้ส่ง
class _MessageBubble extends StatelessWidget {
  // รับเนื้อหาข้อความ URL รูปภาพ และสถานะว่าเป็นข้อความของผู้ใช้เองหรือไม่
  const _MessageBubble({
    required this.text,
    required this.imageUrl,
    required this.isMine,
  });

  final String text;
  final String? imageUrl;
  final bool isMine;

  /// สร้างกล่องข้อความซึ่งอาจมีรูปภาพ ข้อความ หรือทั้งสองอย่าง
  @override
  Widget build(BuildContext context) {
    // คำนวณขนาดรูปภาพจากความกว้างหน้าจอเพื่อให้เหมาะกับพื้นที่แชท
    final imageSize = MediaQuery.sizeOf(context).width * 0.6;
    return Align(
      // วางข้อความของผู้ใช้ปัจจุบันชิดขวา และข้อความคู่สนทนาชิดซ้าย
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        // กำหนดระยะห่าง ขนาดสูงสุด สีพื้นหลัง และมุมโค้งของกล่องข้อความ
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMine ? const Color(0xFF333333) : const Color(0xFFEFEFEF),
          borderRadius: BorderRadius.circular(18),
        ),
        // จัดรูปภาพและข้อความภายในกล่องจากบนลงล่าง
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // โหลดและแสดงรูปภาพที่แนบ พร้อมแสดงไอคอนเมื่อโหลดไม่สำเร็จ
            if (imageUrl != null && imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl!,
                  width: imageSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => SizedBox(
                    width: imageSize,
                    height: 100,
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
            // แสดงเนื้อหาข้อความถ้ามี และเว้นระยะจากรูปภาพเมื่อแสดงร่วมกัน
            if (text.isNotEmpty) ...[
              if (imageUrl != null && imageUrl!.isNotEmpty)
                const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    color: isMine ? Colors.white : const Color(0xFF292929),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
