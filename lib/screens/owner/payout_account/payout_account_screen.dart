// หน้าจอให้เจ้าของร้านแก้ไขบัญชีธนาคารสำหรับรับเงินโอน
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';

class PayoutAccountScreen extends StatefulWidget {
  const PayoutAccountScreen({super.key});

  @override
  State<PayoutAccountScreen> createState() => _PayoutAccountScreenState();
}

class _PayoutAccountScreenState extends State<PayoutAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final profile = context.read<AuthProvider>().profile;
    if (profile != null) {
      _bankNameController.text = profile.bankName;
      _accountNumberController.text = profile.bankAccountNumber;
      _accountNameController.text = profile.bankAccountName.isEmpty
          ? profile.name
          : profile.bankAccountName;
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    if (profile?.role != UserRole.owner) {
      return Scaffold(
        appBar: AppBar(title: const Text('บัญชีรับเงิน')),
        body: const Center(child: Text('เฉพาะเจ้าของร้านเท่านั้น')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('บัญชีรับเงิน')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'ข้อมูลนี้จะแสดงให้ลูกค้าเมื่อเลือกชำระเงินด้วยการโอนผ่านธนาคาร '
              'ส่วน QR พร้อมเพย์ใช้เบอร์โทรศัพท์จากโปรไฟล์',
              style: TextStyle(color: Color(0xFF777777)),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _bankNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'ธนาคาร',
                border: OutlineInputBorder(),
              ),
              validator: _required('กรุณากรอกชื่อธนาคาร'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _accountNumberController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
              ],
              decoration: const InputDecoration(
                labelText: 'เลขที่บัญชี',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final digits = (value ?? '').replaceAll('-', '');
                return digits.length < 10
                    ? 'เลขที่บัญชีต้องมีอย่างน้อย 10 หลัก'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _accountNameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อบัญชี',
                border: OutlineInputBorder(),
              ),
              validator: _required('กรุณากรอกชื่อบัญชี'),
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
                    : const Text('บันทึกบัญชีรับเงิน'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? Function(String?) _required(String message) =>
      (value) => value == null || value.trim().isEmpty ? message : null;

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().updateBankAccount(
        bankName: _bankNameController.text,
        accountNumber: _accountNumberController.text,
        accountName: _accountNameController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกบัญชีรับเงินแล้ว')));
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกไม่สำเร็จ กรุณาลองใหม่')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
