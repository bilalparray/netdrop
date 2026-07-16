import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DeviceNameHelper {
  DeviceNameHelper._();

  static final _plugin = DeviceInfoPlugin();
  static const _androidChannel = MethodChannel('com.qayham.netdrop/receive');

  /// Human-readable name for this device (Settings name, model, or hostname).
  static Future<String> resolveModelName() async {
    try {
      if (Platform.isAndroid) {
        final systemName = await _readAndroidSystemName();
        if (systemName != null && systemName.isNotEmpty) {
          return systemName;
        }

        final info = await _plugin.androidInfo;
        final model = _cleanAndroidModel(info.model);
        if (model.isNotEmpty) {
          return model;
        }
        return '${info.manufacturer} ${info.device}'.trim();
      }
      if (Platform.isIOS) {
        final info = await _plugin.iosInfo;
        final name = info.name.trim();
        if (name.isNotEmpty) {
          return name;
        }
        return info.utsname.machine;
      }
      if (Platform.isWindows) {
        final info = await _plugin.windowsInfo;
        return info.computerName.trim();
      }
      if (Platform.isMacOS) {
        final info = await _plugin.macOsInfo;
        final name = info.computerName.trim();
        if (name.isNotEmpty) {
          return name;
        }
        return info.model;
      }
      if (Platform.isLinux) {
        final info = await _plugin.linuxInfo;
        final name = info.prettyName.trim();
        if (name.isNotEmpty) {
          return name;
        }
      }
    } catch (error, stackTrace) {
      debugPrint(
        'DeviceNameHelper.resolveModelName failed: $error\n$stackTrace',
      );
    }

    return _hostnameFallback();
  }

  static Future<String?> _readAndroidSystemName() async {
    try {
      final name = await _androidChannel.invokeMethod<String>('getDeviceName');
      final trimmed = name?.trim();
      if (trimmed == null || trimmed.isEmpty || isPlaceholderAlias(trimmed)) {
        return null;
      }
      return trimmed;
    } catch (error) {
      debugPrint('Android getDeviceName failed: $error');
      return null;
    }
  }

  static String _cleanAndroidModel(String raw) {
    final model = raw.trim();
    if (model.isEmpty) {
      return model;
    }
    // Some OEMs return internal codenames in lowercase — keep as-is if mixed case.
    return model;
  }

  /// Default alias shown to other devices on the network.
  static Future<String> resolveDefaultAlias() async {
    return resolveModelName();
  }

  static String resolveOsLabel() {
    return switch (Platform.operatingSystem) {
      'android' => 'Android',
      'ios' => 'iOS',
      'windows' => 'Windows',
      'macos' => 'macOS',
      'linux' => 'Linux',
      _ => Platform.operatingSystem,
    };
  }

  static bool isPlaceholderAlias(String alias) {
    final trimmed = alias.trim();
    return trimmed.isEmpty || trimmed == 'My Device' || trimmed == 'Unknown';
  }

  /// Old installs used adjective + noun aliases like "Swift Fox".
  static bool isLegacyRandomAlias(String alias) {
    const adjectives = ['Swift', 'Bright', 'Calm', 'Bold', 'Quick', 'Clear'];
    const nouns = ['Fox', 'Hawk', 'Wave', 'Node', 'Link', 'Pulse'];
    final parts = alias.trim().split(' ');
    if (parts.length != 2) {
      return false;
    }
    return adjectives.contains(parts[0]) && nouns.contains(parts[1]);
  }

  static bool shouldAutoSetAlias(String alias, bool hasSavedAlias) {
    if (!hasSavedAlias) {
      return true;
    }
    return isPlaceholderAlias(alias) || isLegacyRandomAlias(alias);
  }

  static String _hostnameFallback() {
    try {
      final host = Platform.localHostname.trim();
      if (host.isNotEmpty && host != 'localhost') {
        return host;
      }
    } catch (_) {
      // ignored
    }
    return 'My Device';
  }
}
