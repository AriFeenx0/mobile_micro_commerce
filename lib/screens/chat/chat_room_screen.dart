// หน้าห้องสนทนาที่ตอนนี้เป็นหน้าตัวอย่าง
import 'package:flutter/material.dart';
import 'package:mobile_micro_commerce/widgets/feature_placeholder_screen.dart';

class ChatRoomScreen extends StatelessWidget {
  const ChatRoomScreen({super.key});

  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
        title: 'Chat',
        message: 'Chat room placeholder',
      );
}