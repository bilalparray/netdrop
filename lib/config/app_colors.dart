import 'package:flutter/material.dart';

abstract final class NetDropColors {
  static const primary = Color(0xFF0056D2);
  static const primaryDark = Color(0xFF0041A8);
  static const primaryLight = Color(0xFF3D7FE8);

  static const background = Color(0xFFF8FAFF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFEEF2FF);

  static const textPrimary = Color(0xFF1A1D26);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);

  static const online = Color(0xFF22C55E);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);

  static const iconDocuments = Color(0xFF0056D2);
  static const iconImages = Color(0xFF22C55E);
  static const iconVideos = Color(0xFF8B5CF6);
  static const iconAudio = Color(0xFFEF4444);
  static const iconArchives = Color(0xFFF59E0B);
  static const iconOther = Color(0xFF64748B);

  static const cardShadow = Color(0x140056D2);

  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary, primaryDark],
  );
}
