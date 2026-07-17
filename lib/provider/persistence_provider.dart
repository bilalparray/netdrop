import 'dart:convert';
import 'package:netdrop/config/constants.dart';
import 'package:netdrop/util/device_name.dart';
import 'package:netdrop/model/settings_state.dart';
import 'package:netdrop/model/stored_security_context.dart';
import 'package:netdrop/model/device_preferences.dart';
import 'package:netdrop/model/transfer_history_entry.dart';
import 'package:netdrop/util/security_helper.dart';
import 'package:refena/refena.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersistenceService {
  PersistenceService(this._prefs);

  final SharedPreferences _prefs;
  static const _aliasKey = 'nd_alias';
  static const _portKey = 'nd_port';
  static const _fingerprintKey = 'nd_fingerprint';
  static const _httpsKey = 'nd_https';
  static const _securityKey = 'nd_security_context';
  static const _historyKey = 'nd_transfer_history';
  static const _trustedKey = 'nd_trusted_devices';
  static const _pinnedKey = 'nd_pinned_devices';
  static const _manualKey = 'nd_manual_devices';

  static Future<PersistenceService> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    return PersistenceService(prefs);
  }

  StoredSecurityContext? loadSecurityContext() {
    final raw = _prefs.getString(_securityKey);
    if (raw == null) {
      return null;
    }
    return StoredSecurityContext.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSecurityContext(StoredSecurityContext context) async {
    await _prefs.setString(_securityKey, jsonEncode(context.toJson()));
  }

  bool get hasSavedAlias => _prefs.containsKey(_aliasKey);

  SettingsState loadSettings({required String fingerprint}) {
    final alias = _prefs.getString(_aliasKey) ?? 'My Device';
    final port = _prefs.getInt(_portKey) ?? defaultPort;
    final https = _prefs.getBool(_httpsKey) ?? false;

    if (!_prefs.containsKey(_portKey)) {
      _prefs.setInt(_portKey, port);
    }

    return SettingsState(
      alias: alias,
      port: port,
      fingerprint: fingerprint,
      https: https,
    );
  }

  Future<void> saveSettings(SettingsState settings) async {
    await _prefs.setString(_aliasKey, settings.alias);
    await _prefs.setInt(_portKey, settings.port);
    await _prefs.setString(_fingerprintKey, settings.fingerprint);
    await _prefs.setBool(_httpsKey, settings.https);
  }

  List<TransferHistoryEntry> loadHistory() {
    final raw = _prefs.getString(_historyKey);
    if (raw == null) {
      return const [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((entry) => TransferHistoryEntry.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveHistory(List<TransferHistoryEntry> history) async {
    final encoded = jsonEncode(history.map((entry) => entry.toJson()).toList());
    await _prefs.setString(_historyKey, encoded);
  }

  DevicePreferencesState loadDevicePreferences() {
    final trusted = _readStringSet(_trustedKey);
    final pinned = _readStringSet(_pinnedKey);
    final manualRaw = _prefs.getString(_manualKey);
    final manual = <String, ManualDeviceRecord>{};
    if (manualRaw != null) {
      final decoded = jsonDecode(manualRaw) as List<dynamic>;
      for (final entry in decoded) {
        final record = ManualDeviceRecord.fromJson(
          Map<String, dynamic>.from(entry as Map),
        );
        manual[record.fingerprint] = record;
      }
    }
    return DevicePreferencesState(
      trustedFingerprints: trusted,
      pinnedFingerprints: pinned,
      manualDevices: manual,
    );
  }

  Future<void> saveDevicePreferences(DevicePreferencesState prefs) async {
    await _prefs.setStringList(_trustedKey, prefs.trustedFingerprints.toList());
    await _prefs.setStringList(_pinnedKey, prefs.pinnedFingerprints.toList());
    final manual = prefs.manualDevices.values.map((e) => e.toJson()).toList();
    await _prefs.setString(_manualKey, jsonEncode(manual));
  }

  Set<String> _readStringSet(String key) {
    return _prefs.getStringList(key)?.toSet() ?? {};
  }

  Future<void> clearDevicePreferences() async {
    await _prefs.remove(_trustedKey);
    await _prefs.remove(_pinnedKey);
    await _prefs.remove(_manualKey);
  }

  Future<({StoredSecurityContext security, SettingsState settings})> resetToDefaults() async {
    await _prefs.clear();
    final security = SecurityHelper.generate();
    await saveSecurityContext(security);
    final alias = await DeviceNameHelper.resolveDefaultAlias();
    final settings = SettingsState(
      alias: alias.isNotEmpty ? alias : 'My Device',
      port: defaultPort,
      fingerprint: security.fingerprint,
      https: false,
    );
    await saveSettings(settings);
    await saveHistory(const []);
    await clearDevicePreferences();
    return (security: security, settings: settings);
  }
}

final persistenceProvider = Provider<PersistenceService>((ref) {
  throw UnimplementedError('PersistenceService must be overridden at startup');
});
