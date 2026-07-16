import 'package:flutter/material.dart';

class SettingsState {
  const SettingsState({
    required this.alias,
    required this.port,
    required this.fingerprint,
    this.themeMode = ThemeMode.system,
    this.https = false,
  });

  final String alias;
  final int port;
  final String fingerprint;
  final ThemeMode themeMode;
  final bool https;

  SettingsState copyWith({
    String? alias,
    int? port,
    String? fingerprint,
    ThemeMode? themeMode,
    bool? https,
  }) {
    return SettingsState(
      alias: alias ?? this.alias,
      port: port ?? this.port,
      fingerprint: fingerprint ?? this.fingerprint,
      themeMode: themeMode ?? this.themeMode,
      https: https ?? this.https,
    );
  }
}
