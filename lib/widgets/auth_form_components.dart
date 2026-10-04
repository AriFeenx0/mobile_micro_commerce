import 'package:flutter/material.dart';

abstract final class AuthFormStyle {
  static const compactBreakpoint = 420.0;
  static const compactHorizontalPadding = 28.0;
  static const wideHorizontalPadding = 48.0;
  static const topPadding = 30.0;
  static const bottomPadding = 28.0;
  static const logoSize = 92.0;
  static const logoRadius = 18.0;
  static const labelFontSize = 15.0;
  static const inputFontSize = 16.0;
  static const inputHorizontalPadding = 18.0;
  static const inputVerticalPadding = 15.0;
  static const inputRadius = 12.0;
  static const buttonHeight = 56.0;
  static const buttonRadius = 14.0;
  static const buttonFontSize = 18.0;

  static Widget logo() => Center(
    child: Container(
      width: logoSize,
      height: logoSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        border: Border.all(color: const Color(0xFFA0A0A0), width: 2),
        borderRadius: BorderRadius.circular(logoRadius),
      ),
      child: const Text(
        'Logo',
        style: TextStyle(color: Color(0xFF999999), fontSize: 16),
      ),
    ),
  );

  static Widget label(String text) => Padding(
    padding: const EdgeInsets.only(left: 14),
    child: Text(
      text,
      style: const TextStyle(color: Color(0xFF999999), fontSize: labelFontSize),
    ),
  );

  static InputDecoration inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: Color(0xFFB8B8B8),
      fontSize: inputFontSize,
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: inputHorizontalPadding,
      vertical: inputVerticalPadding,
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFFA0A0A0), width: 2),
      borderRadius: BorderRadius.circular(inputRadius),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFF555555), width: 2),
      borderRadius: BorderRadius.circular(inputRadius),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFFB44343), width: 2),
      borderRadius: BorderRadius.circular(inputRadius),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFFB44343), width: 2),
      borderRadius: BorderRadius.circular(inputRadius),
    ),
  );
}
