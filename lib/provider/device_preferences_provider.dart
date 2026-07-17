import 'package:netdrop/model/device.dart';
import 'package:netdrop/model/device_preferences.dart';
import 'package:netdrop/provider/persistence_provider.dart';
import 'package:refena/refena.dart';

class DevicePreferencesService extends Notifier<DevicePreferencesState> {
  @override
  DevicePreferencesState init() {
    return ref.read(persistenceProvider).loadDevicePreferences();
  }

  Future<void> _persist() async {
    await ref.read(persistenceProvider).saveDevicePreferences(state);
  }

  Future<void> setTrusted(String fingerprint, bool trusted) async {
    final updated = Set<String>.from(state.trustedFingerprints);
    if (trusted) {
      updated.add(fingerprint);
    } else {
      updated.remove(fingerprint);
    }
    state = state.copyWith(trustedFingerprints: updated);
    await _persist();
  }

  Future<void> toggleTrusted(String fingerprint) {
    return setTrusted(fingerprint, !state.isTrusted(fingerprint));
  }

  Future<void> setPinned(String fingerprint, bool pinned) async {
    final updated = Set<String>.from(state.pinnedFingerprints);
    if (pinned) {
      updated.add(fingerprint);
    } else {
      updated.remove(fingerprint);
    }
    state = state.copyWith(pinnedFingerprints: updated);
    await _persist();
  }

  Future<void> togglePinned(String fingerprint) {
    return setPinned(fingerprint, !state.isPinned(fingerprint));
  }

  Future<void> saveManualDevice(Device device) async {
    final updated = Map<String, ManualDeviceRecord>.from(state.manualDevices);
    updated[device.fingerprint] = ManualDeviceRecord(
      fingerprint: device.fingerprint,
      ip: device.ip,
      port: device.port,
      alias: device.alias,
      https: device.https,
    );
    state = state.copyWith(manualDevices: updated);
    await _persist();
  }

  Future<void> removeManualDevice(String fingerprint) async {
    if (!state.manualDevices.containsKey(fingerprint)) {
      return;
    }
    final updated = Map<String, ManualDeviceRecord>.from(state.manualDevices)
      ..remove(fingerprint);
    state = state.copyWith(manualDevices: updated);
    await _persist();
  }

  bool isTrusted(String fingerprint) => state.isTrusted(fingerprint);

  bool isPinned(String fingerprint) => state.isPinned(fingerprint);

  Future<void> reset() async {
    state = const DevicePreferencesState();
    await _persist();
  }
}

final devicePreferencesProvider =
    NotifierProvider<DevicePreferencesService, DevicePreferencesState>(
  (ref) => DevicePreferencesService(),
);

List<Device> sortDevices(
  List<Device> devices, {
  required Set<String> pinnedFingerprints,
}) {
  final sorted = List<Device>.from(devices);
  sorted.sort((a, b) {
    final aPinned = pinnedFingerprints.contains(a.fingerprint);
    final bPinned = pinnedFingerprints.contains(b.fingerprint);
    if (aPinned != bPinned) {
      return aPinned ? -1 : 1;
    }
    return a.alias.toLowerCase().compareTo(b.alias.toLowerCase());
  });
  return sorted;
}
