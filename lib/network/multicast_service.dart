import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:netdrop/config/constants.dart';
import 'package:netdrop/model/device.dart';
import 'package:netdrop/model/dto/register_dto.dart';
import 'package:netdrop/provider/device_preferences_provider.dart';
import 'package:netdrop/provider/local_ip_provider.dart';
import 'package:netdrop/provider/network/nearby_devices_provider.dart';
import 'package:netdrop/provider/security_provider.dart';
import 'package:netdrop/provider/settings_provider.dart';
import 'package:netdrop/util/http_client_factory.dart';
import 'package:refena/refena.dart';

final _logger = Logger('MulticastService');

class MulticastService {
  MulticastService(this._ref);

  final Ref _ref;
  RawDatagramSocket? _socket;
  bool _listening = false;

  Future<void> startListener() async {
    if (_listening) {
      return;
    }

    final settings = _ref.read(settingsProvider);

    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        discoveryPort,
        reuseAddress: true,
        reusePort: !Platform.isAndroid,
      );
      _socket!.broadcastEnabled = true;
      _socket!.joinMulticast(InternetAddress(defaultMulticastGroup));
      _socket!.listen(_onDatagram);
      _listening = true;
      await sendAnnouncement();
      _logger.info(
        'Multicast listener started on $defaultMulticastGroup:$discoveryPort (HTTP port ${settings.port})',
      );
    } catch (error, stackTrace) {
      _logger.severe('Failed to start multicast listener', error, stackTrace);
    }
  }

  Future<void> sendAnnouncement() async {
    final settings = _ref.read(settingsProvider);
    final dto = RegisterDto(
      alias: settings.alias,
      version: protocolVersion,
      fingerprint: settings.fingerprint,
      port: settings.port,
      protocol: settings.https ? 'https' : 'http',
      deviceType: _ref.read(deviceTypeProvider),
      deviceModel: _ref.read(deviceModelProvider),
    );

    final payload = utf8.encode(jsonEncode({...dto.toJson(), 'announce': true}));
    final group = InternetAddress(defaultMulticastGroup);

    for (final delay in [0, 100, 500, 2000]) {
      if (delay == 0) {
        _socket?.send(payload, group, discoveryPort);
      } else {
        Timer(Duration(milliseconds: delay), () {
          _socket?.send(payload, group, discoveryPort);
        });
      }
    }
  }

  void _onDatagram(RawSocketEvent event) {
    if (event != RawSocketEvent.read) {
      return;
    }

    final socket = _socket;
    if (socket == null) {
      return;
    }

    final datagram = socket.receive();
    if (datagram == null) {
      return;
    }

    try {
      final json = jsonDecode(utf8.decode(datagram.data)) as Map<String, dynamic>;
      final dto = RegisterDto.fromJson(json);
      final settings = _ref.read(settingsProvider);

      if (dto.fingerprint == settings.fingerprint) {
        return;
      }

      final ip = datagram.address.address;
      final device = dto.toDevice(ip);
      _ref.redux(nearbyDevicesProvider).dispatch(
            RegisterDeviceAction(device, localFingerprint: settings.fingerprint),
          );
      unawaited(_respondToAnnouncement(device));
    } catch (error, stackTrace) {
      _logger.fine('Ignored invalid multicast packet', error, stackTrace);
    }
  }

  Future<void> _respondToAnnouncement(Device device) async {
    try {
      final settings = _ref.read(settingsProvider);
      final client = createHttpClient(
        https: device.https,
        security: device.https ? _ref.read(securityProvider) : null,
        connectionTimeout: const Duration(milliseconds: defaultDiscoveryTimeoutMs),
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
        deviceType: _ref.read(deviceTypeProvider),
        deviceModel: _ref.read(deviceModelProvider),
      );
      request.write(jsonEncode(body.toJson()));
      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final dto = RegisterDto.fromJson(jsonDecode(responseBody) as Map<String, dynamic>);
        if (dto.fingerprint == settings.fingerprint) {
          return;
        }
        _ref.redux(nearbyDevicesProvider).dispatch(
              RegisterDeviceAction(
                dto.toDevice(device.ip),
                localFingerprint: settings.fingerprint,
              ),
            );
      }
      client.close(force: true);
    } catch (_) {
      // UDP fallback is acceptable; peer is already registered from multicast.
    }
  }

  Future<void> dispose() async {
    _socket?.close();
    _socket = null;
    _listening = false;
  }
}

final multicastServiceProvider = Provider<MulticastService>((ref) {
  return MulticastService(ref);
});

class StartDiscoveryAction extends AsyncGlobalAction {
  @override
  Future<void> reduce() async {
    final localFingerprint = ref.read(settingsProvider).fingerprint;
    ref.redux(nearbyDevicesProvider).dispatch(RemoveLocalDeviceAction(localFingerprint));
    ref.redux(nearbyDevicesProvider).dispatch(SetScanningAction(true));
    try {
      await ref.read(multicastServiceProvider).startListener();
      await ref.read(multicastServiceProvider).sendAnnouncement();
      await _httpSubnetScan(ref);
    } finally {
      final prefs = ref.read(devicePreferencesProvider);
      ref.redux(nearbyDevicesProvider).dispatch(
            RemoveStaleDevicesAction(
              preserveFingerprints: {
                ...prefs.manualDevices.keys,
                ...prefs.pinnedFingerprints,
              },
            ),
          );
      ref.redux(nearbyDevicesProvider).dispatch(SetScanningAction(false));
    }
  }
}

Future<void> _httpSubnetScan(Ref ref) async {
  final ips = await ref.read(localIpProvider).getLocalIps();
  if (ips.isEmpty) {
    return;
  }

  final settings = ref.read(settingsProvider);
  final body = RegisterDto(
    alias: settings.alias,
    version: protocolVersion,
    fingerprint: settings.fingerprint,
    port: settings.port,
    protocol: settings.https ? 'https' : 'http',
    deviceType: ref.read(deviceTypeProvider),
    deviceModel: ref.read(deviceModelProvider),
  );

  final subnets = ips.map((ip) => ip.split('.').take(3).join('.')).toSet();
  final futures = <Future<void>>[];

  for (final subnet in subnets) {
    for (var i = 0; i <= 255; i++) {
      final targetIp = '$subnet.$i';
      if (ips.contains(targetIp)) {
        continue;
      }
      futures.add(_probeIp(ref, targetIp, body));
      if (futures.length >= 50) {
        await Future.wait(futures);
        futures.clear();
      }
    }
  }

  if (futures.isNotEmpty) {
    await Future.wait(futures);
  }
}

Future<void> _probeIp(Ref ref, String ip, RegisterDto body) async {
  final useHttps = body.protocol == 'https';
  try {
    final client = createHttpClient(
      https: useHttps,
      security: useHttps ? ref.read(securityProvider) : null,
      connectionTimeout: const Duration(milliseconds: defaultDiscoveryTimeoutMs),
    );
    final scheme = useHttps ? 'https' : 'http';
    final uri = Uri.parse('$scheme://$ip:${body.port}$apiBasePath/register');
    final request = await client.postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(body.toJson()));
    final response = await request.close();
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final dto = RegisterDto.fromJson(jsonDecode(responseBody) as Map<String, dynamic>);
      if (dto.fingerprint != body.fingerprint) {
        ref.redux(nearbyDevicesProvider).dispatch(
              RegisterDeviceAction(
                dto.toDevice(ip),
                localFingerprint: body.fingerprint,
              ),
            );
      }
    }
    client.close(force: true);
  } catch (_) {
    // Expected for most IPs on the subnet.
  }
}
