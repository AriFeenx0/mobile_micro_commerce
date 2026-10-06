// หน้าจอเข้าสู่ระบบด้วยอีเมลและรหัสผ่าน
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_form_components.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                constraints.maxWidth < AuthFormStyle.compactBreakpoint
                ? AuthFormStyle.compactHorizontalPadding
                : AuthFormStyle.wideHorizontalPadding;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AuthFormStyle.topPadding,
                horizontalPadding,
                AuthFormStyle.bottomPadding,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    AuthFormStyle.logo(),
                    const SizedBox(height: 22),
                    AuthFormStyle.label('Email'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      style: const TextStyle(
                        fontSize: AuthFormStyle.inputFontSize,
                        color: Color(0xFF333333),
                      ),
                      decoration: AuthFormStyle.inputDecoration(
                        'you@email.com',
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty || !email.contains('@')) {
                          return 'กรุณากรอกอีเมลให้ถูกต้อง';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AuthFormStyle.label('Password'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      style: const TextStyle(
                        fontSize: AuthFormStyle.inputFontSize,
                        color: Color(0xFF333333),
                      ),
                      decoration: AuthFormStyle.inputDecoration('••••••••'),
                      validator: (value) =>
                          (value?.isEmpty ?? true) ? 'กรุณากรอกรหัสผ่าน' : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isSubmitting ? null : _resetPassword,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF666666),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'ลืมรหัสผ่าน?',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: AuthFormStyle.buttonHeight,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF333333),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AuthFormStyle.buttonRadius,
                            ),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'เข้าสู่ระบบ',
                                style: TextStyle(
                                  fontSize: AuthFormStyle.buttonFontSize,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ยังไม่มีบัญชี?',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF777777), fontSize: 15),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.register),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF292929),
                        padding: const EdgeInsets.only(top: 1),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'สมัครสมาชิก',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      final user = await _authService.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;

      final destination = user.role == UserRole.customer
          ? AppRoutes.customerBooks
          : AppRoutes.ownerDashboard;
      Navigator.pushNamedAndRemoveUntil(
        context,
        destination,
        (_) => false,
      );
    } catch (error) {
      if (mounted) _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMessage('กรอกอีเมลให้ถูกต้องก่อนขอรีเซ็ตรหัสผ่าน');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _authService.sendPasswordResetEmail(email);
      if (mounted) _showMessage('ส่งลิงก์รีเซ็ตรหัสผ่านไปยังอีเมลแล้ว');
    } catch (error) {
      if (mounted) _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'invalid-email' => 'รูปแบบอีเมลไม่ถูกต้อง',
        'user-disabled' => 'บัญชีนี้ถูกระงับการใช้งาน',
        'user-not-found' || 'wrong-password' || 'invalid-credential' =>
          'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
        'operation-not-allowed' =>
          'ยังไม่ได้เปิด Email/Password ใน Firebase Console',
        'too-many-requests' => 'ลองหลายครั้งเกินไป กรุณารอสักครู่',
        'network-request-failed' => 'เชื่อมต่ออินเทอร์เน็ตไม่สำเร็จ',
        _ => 'เข้าสู่ระบบไม่สำเร็จ กรุณาลองใหม่',
      };
    }
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'ไม่มีสิทธิ์อ่านโปรไฟล์จาก Firestore';
    }
    return 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
