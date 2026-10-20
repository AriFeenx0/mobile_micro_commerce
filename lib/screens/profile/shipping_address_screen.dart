// หน้าจอแก้ไขที่อยู่จัดส่งของลูกค้า
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class ShippingAddressScreen extends StatefulWidget {
  const ShippingAddressScreen({super.key});

  @override
  State<ShippingAddressScreen> createState() => _ShippingAddressScreenState();
}

class _ShippingAddressScreenState extends State<ShippingAddressScreen> {
  final _addressController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _addressController.text =
        context.read<AuthProvider>().profile?.address ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ที่อยู่จัดส่ง')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _addressController,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'ที่อยู่จัดส่ง',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('บันทึกที่อยู่'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final profile = auth.profile;
    if (profile == null) return;
    setState(() => _saving = true);
    try {
      await auth.updateProfile(
        name: profile.name,
        phone: profile.phone,
        address: _addressController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกที่อยู่แล้ว')));
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกที่อยู่ไม่สำเร็จ กรุณาลองใหม่')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
