import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:netdrop/model/device.dart';
import 'package:netdrop/provider/local_device_info_provider.dart';
import 'package:refena/refena.dart';

class LocalIpService {
  Future<List<String>> getLocalIps() async {
    if (kIsWeb) {
      return const [];
    }

    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    );

    final ips = <String>[];
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        if (!address.isLoopback) {
          ips.add(address.address);
        }
      }
    }
    return ips;
  }
}

final localIpProvider = Provider<LocalIpService>((ref) => LocalIpService());

final deviceTypeProvider = Provider<DeviceType>((ref) {
  if (kIsWeb) {
    return DeviceType.desktop;
  }
  if (Platform.isAndroid || Platform.isIOS) {
    return DeviceType.mobile;
  }
  return DeviceType.desktop;
});

final deviceModelProvider = Provider<String>((ref) {
  return ref.read(localDeviceInfoProvider).modelName;
});
