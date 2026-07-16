import 'package:flutter/material.dart';
import 'package:netdrop/config/app_colors.dart';
import 'package:netdrop/model/device.dart';

String formatOsLabel(String? raw) {
  if (raw == null || raw.isEmpty) {
    return 'Unknown';
  }
  return switch (raw.toLowerCase()) {
    'android' => 'Android',
    'ios' => 'iOS',
    'windows' => 'Windows',
    'macos' => 'macOS',
    'linux' => 'Linux',
    _ => raw[0].toUpperCase() + raw.substring(1),
  };
}

IconData deviceIcon(Device device) {
  return switch (device.deviceType) {
    DeviceType.mobile => Icons.smartphone,
    DeviceType.desktop => Icons.laptop_mac,
    DeviceType.headless => Icons.dns_outlined,
    DeviceType.server => Icons.storage_outlined,
  };
}

Color deviceIconColor(Device device) {
  return switch (device.deviceType) {
    DeviceType.mobile => NetDropColors.primary,
    DeviceType.desktop => NetDropColors.primaryDark,
    _ => NetDropColors.textSecondary,
  };
}
