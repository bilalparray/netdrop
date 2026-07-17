import 'dart:convert';
import 'dart:io';

import 'package:netdrop/config/constants.dart';
import 'package:netdrop/model/device.dart';
import 'package:netdrop/model/dto/register_dto.dart';
import 'package:netdrop/provider/local_ip_provider.dart';
import 'package:netdrop/provider/network/nearby_devices_provider.dart';
import 'package:netdrop/provider/security_provider.dart';
import 'package:netdrop/provider/settings_provider.dart';
import 'package:netdrop/provider/device_preferences_provider.dart';
import 'package:netdrop/util/http_client_factory.dart';
import 'package:refena/refena.dart';

/// Fetches device info from a known IP/port (tries HTTP then HTTPS).
Future<Device?> fetchDeviceAt({
  required Ref ref,
  required String ip,
  required int port,
  bool? preferHttps,
}) async {
  final schemes = preferHttps == null
      ? const ['http', 'https']
      : preferHttps
      ? const ['https', 'http']
      : const ['http', 'https'];

  for (final scheme in schemes) {
    final useTls = scheme == 'https';
    try {
      final client = createHttpClient(
        https: useTls,
        security: useTls ? ref.read(securityProvider) : null,
        connectionTimeout: const Duration(seconds: 5),
      );
      final uri = Uri.parse('$scheme://$ip:$port$apiBasePath/info');
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(const Utf8Decoder()).join();
      client.close(force: true);

      if (response.statusCode != 200) {
        continue;
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final info = RegisterDto.fromJson({
        'alias': json['alias'],
        'version': json['version'],
        'fingerprint': json['fingerprint'],
        'port': port,
        'protocol': scheme,
        if (json['deviceModel'] != null) 'deviceModel': json['deviceModel'],
        if (json['deviceType'] != null) 'deviceType': json['deviceType'],
      });

      return info.toDevice(ip);
    } catch (_) {
      // Try the next scheme.
    }
  }
  return null;
}

/// Registers this device with a remote peer and adds it to the nearby list.
Future<Device?> connectToDevice({
  required Ref ref,
  required String ip,
  required int port,
  bool? preferHttps,
  Device? knownDevice,
}) async {
  final settings = ref.read(settingsProvider);
  final localFingerprint = settings.fingerprint;

  final device =
      knownDevice ??
      await fetchDeviceAt(
        ref: ref,
        ip: ip,
        port: port,
        preferHttps: preferHttps,
      );
  if (device == null) {
    return null;
  }

  if (device.fingerprint == localFingerprint) {
    return null;
  }

  try {
    final client = createHttpClient(
      https: device.https,
      security: device.https ? ref.read(securityProvider) : null,
      connectionTimeout: const Duration(seconds: 5),
    );
    final uri = Uri.parse('${device.baseUrl}$apiBasePath/register');
    final request = await client.postUrl(uri);
    request.headers.contentType = ContentType.json;

    final body = RegisterDto(
      alias: settings.alias,
      version: protocolVersion,
      fingerprint: settings.fingerprint,
      port: settings.port,
      protocol: settings.https ? 'https' : 'http',
      deviceType: ref.read(deviceTypeProvider),
      deviceModel: ref.read(deviceModelProvider),
    );
    request.write(jsonEncode(body.toJson()));
    final response = await request.close();
    await response.drain<void>();
    client.close(force: true);

    if (response.statusCode != 200) {
      return null;
    }
  } catch (_) {
    return null;
  }

  ref.redux(nearbyDevicesProvider).dispatch(
    RegisterDeviceAction(device, localFingerprint: localFingerprint),
  );
  return device;
}

/// Reconnects manually saved devices on app start.
Future<void> reconnectManualDevices(Ref ref) async {
  final manual = ref.read(devicePreferencesProvider).manualDevices.values;
  for (final record in manual) {
    await connectToDevice(
      ref: ref,
      ip: record.ip,
      port: record.port,
      preferHttps: record.https,
      knownDevice: Device(
        ip: record.ip,
        port: record.port,
        fingerprint: record.fingerprint,
        alias: record.alias,
        version: protocolVersion,
        https: record.https,
        lastSeen: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
