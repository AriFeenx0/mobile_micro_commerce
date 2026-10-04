import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
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
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
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
                    _buildField(
                      label: 'Username',
                      hint: 'your username here',
                      controller: _usernameController,
                      autofillHints: const [AutofillHints.username],
                      validator: _requiredValidator('กรุณากรอก Username'),
                    ),
                    _buildField(
                      label: 'First Name',
                      hint: 'your First Name here',
                      controller: _firstNameController,
                      textCapitalization: TextCapitalization.words,
                      validator: _requiredValidator('กรุณากรอกชื่อ'),
                    ),
                    _buildField(
                      label: 'Last Name',
                      hint: 'your Last Name here',
                      controller: _lastNameController,
                      textCapitalization: TextCapitalization.words,
                      validator: _requiredValidator('กรุณากรอกนามสกุล'),
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
                    const SizedBox(height: 4),
                    SizedBox(
                      height: AuthFormStyle.buttonHeight,
                      child: FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF333333),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AuthFormStyle.buttonRadius,
                            ),
                          ),
                        ),
                        child: const Text(
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

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('ระบบสมัครสมาชิกยังไม่พร้อมใช้งาน')),
        );
    }
  }
}
