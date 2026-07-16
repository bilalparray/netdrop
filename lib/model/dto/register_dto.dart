import 'package:netdrop/model/device.dart';

class InfoDto {
  const InfoDto({
    required this.alias,
    required this.version,
    required this.fingerprint,
    this.deviceModel,
    this.deviceType,
    this.download = false,
  });

  final String alias;
  final String version;
  final String fingerprint;
  final String? deviceModel;
  final DeviceType? deviceType;
  final bool download;

  Map<String, dynamic> toJson() => {
        'alias': alias,
        'version': version,
        'fingerprint': fingerprint,
        if (deviceModel != null) 'deviceModel': deviceModel,
        if (deviceType != null) 'deviceType': deviceType!.name,
        'download': download,
      };

  factory InfoDto.fromJson(Map<String, dynamic> json) {
    return InfoDto(
      alias: json['alias'] as String,
      version: json['version'] as String,
      fingerprint: json['fingerprint'] as String,
      deviceModel: json['deviceModel'] as String?,
      deviceType: _parseDeviceType(json['deviceType']),
      download: json['download'] as bool? ?? false,
    );
  }
}

class RegisterDto {
  const RegisterDto({
    required this.alias,
    required this.version,
    required this.fingerprint,
    required this.port,
    this.deviceModel,
    this.deviceType,
    this.protocol = 'http',
    this.download = false,
  });

  final String alias;
  final String version;
  final String fingerprint;
  final int port;
  final String? deviceModel;
  final DeviceType? deviceType;
  final String protocol;
  final bool download;

  Map<String, dynamic> toJson() => {
        'alias': alias,
        'version': version,
        'fingerprint': fingerprint,
        'port': port,
        if (deviceModel != null) 'deviceModel': deviceModel,
        if (deviceType != null) 'deviceType': deviceType!.name,
        'protocol': protocol,
        'download': download,
      };

  factory RegisterDto.fromJson(Map<String, dynamic> json) {
    return RegisterDto(
      alias: json['alias'] as String,
      version: json['version'] as String,
      fingerprint: json['fingerprint'] as String,
      port: json['port'] as int,
      deviceModel: json['deviceModel'] as String?,
      deviceType: _parseDeviceType(json['deviceType']),
      protocol: json['protocol'] as String? ?? 'http',
      download: json['download'] as bool? ?? false,
    );
  }

  Device toDevice(String ip) {
    return Device(
      ip: ip,
      port: port,
      fingerprint: fingerprint,
      alias: alias,
      version: version,
      https: protocol == 'https',
      deviceModel: deviceModel,
      deviceType: deviceType ?? DeviceType.desktop,
      download: download,
      lastSeen: DateTime.now().millisecondsSinceEpoch,
    );
  }
}

DeviceType? _parseDeviceType(Object? value) {
  if (value is! String) {
    return null;
  }
  return DeviceType.values.cast<DeviceType?>().firstWhere(
        (type) => type?.name == value,
        orElse: () => null,
      );
}
