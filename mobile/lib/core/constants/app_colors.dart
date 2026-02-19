import 'package:flutter/material.dart';

/// BLIP 색상 시스템 (SSOT)
/// web/src/app/globals.css 와 동일한 색상 유지
class AppColors {
  AppColors._();

  // ─── Dark Theme (기본) ───
  static const signalGreenDark = Color(0xFF00FF94);
  static const voidBlackDark = Color(0xFF050505);
  static const ghostGreyDark = Color(0xFF888888);
  static const borderDark = Color(0x0DFFFFFF); // rgba(255,255,255,0.05)
  static const surfaceDark = Color(0xFF0A0A0A);
  static const cardDark = Color(0xFF111111);

  // ─── Light Theme ───
  static const signalGreenLight = Color(0xFF00CC7D);
  static const voidBlackLight = Color(0xFFFFFFFF);
  static const ghostGreyLight = Color(0xFF666666);
  static const borderLight = Color(0x26000000); // rgba(0,0,0,0.15)
  static const surfaceLight = Color(0xFFF5F5F5);
  static const cardLight = Color(0xFFFFFFFF);

  // ─── 공통 ───
  static const glitchRed = Color(0xFFFF2A6D);
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
}
