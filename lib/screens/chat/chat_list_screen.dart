// หน้ารายการห้องแชทที่ยังเป็นหน้าตัวอย่าง
import 'package:flutter/material.dart';
import 'package:mobile_micro_commerce/widgets/feature_placeholder_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
        title: 'Chats',
        message: 'Chat list placeholder',
      );
}