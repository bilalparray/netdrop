import 'package:netdrop/model/cross_file.dart';
import 'package:netdrop/model/device.dart';
import 'package:netdrop/model/state/nearby_devices_state.dart';
import 'package:refena/refena.dart';

class NearbyDevicesService extends ReduxNotifier<NearbyDevicesState> {
  @override
  NearbyDevicesState init() => const NearbyDevicesState();
}

final nearbyDevicesProvider = ReduxProvider<NearbyDevicesService, NearbyDevicesState>(
  (ref) => NearbyDevicesService(),
);

class RemoveLocalDeviceAction extends ReduxAction<NearbyDevicesService, NearbyDevicesState> {
  RemoveLocalDeviceAction(this.fingerprint);

  final String fingerprint;

  @override
  NearbyDevicesState reduce() {
    if (!state.devices.containsKey(fingerprint)) {
      return state;
    }
    final updated = Map<String, Device>.from(state.devices)..remove(fingerprint);
    return state.copyWith(devices: updated);
  }
}

class RegisterDeviceAction extends ReduxAction<NearbyDevicesService, NearbyDevicesState> {
  RegisterDeviceAction(this.device, {this.localFingerprint});

  final Device device;
  final String? localFingerprint;

  @override
  NearbyDevicesState reduce() {
    if (localFingerprint != null && device.fingerprint == localFingerprint) {
      return state;
    }
    final updated = Map<String, Device>.from(state.devices);
    updated[device.fingerprint] = device.copyWith(
      lastSeen: DateTime.now().millisecondsSinceEpoch,
    );
    return state.copyWith(devices: updated);
  }
}

class SetScanningAction extends ReduxAction<NearbyDevicesService, NearbyDevicesState> {
  SetScanningAction(this.scanning);

  final bool scanning;

  @override
  NearbyDevicesState reduce() {
    return state.copyWith(scanning: scanning);
  }
}

class RemoveStaleDevicesAction extends ReduxAction<NearbyDevicesService, NearbyDevicesState> {
  RemoveStaleDevicesAction({this.maxAgeMs = 30000, this.preserveFingerprints = const {}});

  final int maxAgeMs;
  final Set<String> preserveFingerprints;

  @override
  NearbyDevicesState reduce() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final updated = Map<String, Device>.from(state.devices)
      ..removeWhere((fingerprint, device) {
        if (preserveFingerprints.contains(fingerprint)) {
          return false;
        }
        return now - device.lastSeen > maxAgeMs;
      });
    return state.copyWith(devices: updated);
  }
}

class ClearDevicesAction extends ReduxAction<NearbyDevicesService, NearbyDevicesState> {
  @override
  NearbyDevicesState reduce() => const NearbyDevicesState();
}

final selectedFilesProvider = NotifierProvider<SelectedFilesService, List<CrossFile>>(
  (ref) => SelectedFilesService(),
);

final filePrepInProgressProvider = NotifierProvider<FilePrepService, bool>(
  (ref) => FilePrepService(),
);

class FilePrepService extends Notifier<bool> {
  @override
  bool init() => false;

  void setPreparing(bool preparing) {
    state = preparing;
  }
}

class SelectedFilesService extends Notifier<List<CrossFile>> {
  @override
  List<CrossFile> init() => const [];

  void setFiles(List<CrossFile> files) {
    state = List.unmodifiable(files);
  }

  void clear() {
    state = const [];
  }

  void removeFile(String id) {
    state = List.unmodifiable(state.where((file) => file.id != id));
  }
}
