import 'package:netdrop/config/constants.dart';
import 'package:netdrop/model/device.dart';

/// Encodes this device as a QR / deep-link payload for manual pairing.
String encodePairingPayload({
  required String ip,
  required int port,
  required String fingerprint,
  required String alias,
  required bool https,
}) {
  final uri = Uri(
    scheme: 'netdrop',
    host: 'pair',
    queryParameters: {
      'v': protocolVersion,
      'ip': ip,
      'port': '$port',
      'fp': fingerprint,
      'alias': alias,
      'https': https ? '1' : '0',
    },
  );
  return uri.toString();
}

/// Parses a QR code or pasted pairing link.
Device? decodePairingPayload(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  Uri? uri;
  try {
    uri = Uri.parse(trimmed);
  } catch (_) {
    return null;
  }

  if (uri.scheme != 'netdrop' || uri.host != 'pair') {
    return null;
  }

  final ip = uri.queryParameters['ip'];
  final portRaw = uri.queryParameters['port'];
  final fingerprint = uri.queryParameters['fp'];
  final alias = uri.queryParameters['alias'];
  if (ip == null || portRaw == null || fingerprint == null || alias == null) {
    return null;
  }

  final port = int.tryParse(portRaw);
  if (port == null || port < 1 || port > 65535) {
    return null;
  }

  return Device(
    ip: ip,
    port: port,
    fingerprint: fingerprint,
    alias: alias,
    version: uri.queryParameters['v'] ?? protocolVersion,
    https: uri.queryParameters['https'] == '1',
    lastSeen: DateTime.now().millisecondsSinceEpoch,
  );
}

/// Parses `192.168.1.5:53317` or `192.168.1.5`.
({String ip, int port})? parseHostPort(String input, {int defaultPort = defaultPort}) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final parts = trimmed.split(':');
  if (parts.length == 1) {
    return (ip: parts[0], port: defaultPort);
  }
  if (parts.length == 2) {
    final port = int.tryParse(parts[1]);
    if (port == null) {
      return null;
    }
    return (ip: parts[0], port: port);
  }
  return null;
}
