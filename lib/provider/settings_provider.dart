import 'package:flutter/material.dart';
import 'package:netdrop/model/settings_state.dart';
import 'package:netdrop/network/multicast_service.dart';
import 'package:netdrop/provider/history_provider.dart';
import 'package:netdrop/provider/network/nearby_devices_provider.dart';
import 'package:netdrop/provider/network/send_provider.dart';
import 'package:netdrop/provider/network/server_provider.dart';
import 'package:netdrop/provider/persistence_provider.dart';
import 'package:netdrop/provider/progress_provider.dart';
import 'package:netdrop/provider/security_provider.dart';
import 'package:refena/refena.dart';

class SettingsService extends Notifier<SettingsState> {
  @override
  SettingsState init() {
    final security = ref.read(securityProvider);
    return ref.read(persistenceProvider).loadSettings(fingerprint: security.fingerprint);
  }

  Future<void> setAlias(String alias) async {
    final trimmed = alias.trim();
    if (trimmed.isEmpty) {
      return;
    }
    state = state.copyWith(alias: trimmed);
    await ref.read(persistenceProvider).saveSettings(state);
  }

  Future<void> setPort(int port) async {
    if (port < 1024 || port > 65535) {
      return;
    }
    state = state.copyWith(port: port);
    await ref.read(persistenceProvider).saveSettings(state);
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    state = state.copyWith(themeMode: themeMode);
    await ref.read(persistenceProvider).saveSettings(state);
  }

  Future<void> setHttps(bool https) async {
    state = state.copyWith(https: https);
    await ref.read(persistenceProvider).saveSettings(state);
  }

  Future<void> resetApp() async {
    final reset = await ref.read(persistenceProvider).resetToDefaults();
    ref.notifier(securityProvider).replaceContext(reset.security);
    state = reset.settings;

    ref.notifier(historyProvider).clearHistory();
    ref.redux(nearbyDevicesProvider).dispatch(ClearDevicesAction());
    ref.notifier(progressProvider).clear();
    ref.notifier(sendProvider).clearSession();
    ref.notifier(serverProvider).clearActiveSession();

    await ref.notifier(serverProvider).stopServer();
    await ref.notifier(serverProvider).startServer();
    await ref.global.dispatchAsync(StartDiscoveryAction());
  }
}

final settingsProvider = NotifierProvider<SettingsService, SettingsState>(
  (ref) => SettingsService(),
);
