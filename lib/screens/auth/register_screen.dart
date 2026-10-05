import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_form_components.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                    _buildField(
                      label: 'Username',
                      hint: 'your username here',
                      controller: _usernameController,
                      autofillHints: const [AutofillHints.username],
                      validator: _requiredValidator('กรุณากรอก Username'),
                    ),
                    _buildField(
                      label: 'Your name',
                      hint: 'your name here',
                      controller: _firstNameController,
                      textCapitalization: TextCapitalization.words,
                      validator: _requiredValidator('กรุณากรอกชื่อ'),
                    ),
                    _buildField(
                      label: 'Email',
                      hint: 'your@email.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty || !email.contains('@')) {
                          return 'กรุณากรอกอีเมลให้ถูกต้อง';
                        }
                        return null;
                      },
                    ),
                    _buildField(
                      label: 'Password',
                      hint: '••••••••',
                      controller: _passwordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.done,
                      validator: _requiredValidator('กรุณากรอกรหัสผ่าน'),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    _buildField(
                      label: 'Confirm Password',
                      hint: '••••••••',
                      controller: _confirmPasswordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'กรุณายืนยันรหัสผ่าน';
                        }
                        if (value != _passwordController.text) {
                          return 'รหัสผ่านไม่ตรงกัน';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 4),
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
                                'สมัครสมาชิก',
                                style: TextStyle(
                                  fontSize: AuthFormStyle.buttonFontSize,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'มีบัญชีอยู่แล้ว?',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF777777), fontSize: 15),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.login,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF292929),
                        padding: const EdgeInsets.only(top: 1),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'เข้าสู่ระบบ',
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

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction textInputAction = TextInputAction.next,
    Iterable<String>? autofillHints,
    bool obscureText = false,
    void Function(String)? onFieldSubmitted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthFormStyle.label(label),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            obscureText: obscureText,
            style: const TextStyle(
              fontSize: AuthFormStyle.inputFontSize,
              color: Color(0xFF333333),
            ),
            decoration: AuthFormStyle.inputDecoration(hint),
            validator: validator,
            onFieldSubmitted: onFieldSubmitted,
          ),
        ],
      ),
    );
  }

  String? Function(String?) _requiredValidator(String message) => (value) {
    if (value?.trim().isEmpty ?? true) return message;
    return null;
  };

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      await _authService.registerWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
        name: _firstNameController.text,
      );
      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.customerBooks,
        (_) => false,
      );
    } catch (error) {
      if (mounted) _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'email-already-in-use' => 'อีเมลนี้มีบัญชีอยู่แล้ว',
        'invalid-email' => 'รูปแบบอีเมลไม่ถูกต้อง',
        'weak-password' => 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร',
        'operation-not-allowed' =>
          'ยังไม่ได้เปิด Email/Password ใน Firebase Console',
        'too-many-requests' => 'ลองหลายครั้งเกินไป กรุณารอสักครู่',
        'network-request-failed' => 'เชื่อมต่ออินเทอร์เน็ตไม่สำเร็จ',
        _ => 'สมัครสมาชิกไม่สำเร็จ กรุณาลองใหม่',
      };
    }
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'สร้างบัญชีแล้ว แต่ไม่มีสิทธิ์บันทึกโปรไฟล์ใน Firestore';
    }
    return 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
