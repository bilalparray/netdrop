import 'package:netdrop/model/device.dart';

class NearbyDevicesState {
  const NearbyDevicesState({
    this.devices = const {},
    this.scanning = false,
  });

  final Map<String, Device> devices;
  final bool scanning;

  List<Device> get deviceList {
    final list = devices.values.toList()
      ..sort((a, b) => a.alias.toLowerCase().compareTo(b.alias.toLowerCase()));
    return list;
  }

  List<Device> deviceListExcluding(String fingerprint) {
    return deviceList.where((device) => device.fingerprint != fingerprint).toList();
  }

  NearbyDevicesState copyWith({
    Map<String, Device>? devices,
    bool? scanning,
  }) {
    return NearbyDevicesState(
      devices: devices ?? this.devices,
      scanning: scanning ?? this.scanning,
    );
  }
}
