enum DeviceType { mobile, desktop, headless, server }

class Device {
  const Device({
    required this.ip,
    required this.port,
    required this.fingerprint,
    required this.alias,
    required this.version,
    this.https = false,
    this.deviceModel,
    this.deviceType = DeviceType.desktop,
    this.download = false,
    this.lastSeen = 0,
  });

  final String ip;
  final int port;
  final String fingerprint;
  final String alias;
  final String version;
  final bool https;
  final String? deviceModel;
  final DeviceType deviceType;
  final bool download;
  final int lastSeen;

  String get baseUrl {
    final scheme = https ? 'https' : 'http';
    return '$scheme://$ip:$port';
  }

  Device copyWith({int? lastSeen}) {
    return Device(
      ip: ip,
      port: port,
      fingerprint: fingerprint,
      alias: alias,
      version: version,
      https: https,
      deviceModel: deviceModel,
      deviceType: deviceType,
      download: download,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Device && fingerprint == other.fingerprint;

  @override
  int get hashCode => fingerprint.hashCode;
}
